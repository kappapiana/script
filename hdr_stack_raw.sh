#!/bin/bash
set -euo pipefail

# HDR RAW Stack - Align and blend bracketed exposures into a single HDR image.
# Linux only. Requires: hugin-tools, enblend-enfuse, darktable-cli, exiftool
#
# Usage: ./hdr_stack_raw.sh [directory|file1 file2 ...]
#   With directory: process all RAW files in that folder
#   With files: process the given RAW/TIFF/PNG/JPG files
# Output: HDR_YYYYMMDD_HHMMSS.tif in the same directory
# Please note that this is just an example of AI generated script
# don't use unless you know absolutely what it does.

# --- Linux check ---
if [ "$(uname -s)" != "Linux" ]; then
    echo "Error: This script is Linux-only."
    exit 1
fi

# --- Dependency check ---
MISSING=()
for cmd in align_image_stack enfuse darktable-cli exiftool; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING+=("$cmd")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Error: Missing required tools: ${MISSING[*]}"
    echo "Install with: sudo apt install hugin-tools enblend-enfuse darktable libimage-exiftool-perl"
    exit 1
fi

# --- Parse arguments ---
if [ "$#" -eq 0 ]; then
    echo "Usage: $0 [directory|file1 file2 ...]"
    echo "  With directory: process all RAW files in that folder"
    echo "  With files: process the given RAW/TIFF/PNG/JPG files"
    exit 1
fi

# RAW extensions (lowercase for pattern matching)
RAW_EXTS="cr2 cr3 nef nrw arw dng orf rw2 raw raf pef x3f 3fr dcr kdc mrw"
CONVERTED_TIFFS=()
TEMP_PREFIX="aligned_"
WORK_DIR=""

# Check if path is a directory
if [ "$#" -eq 1 ] && [ -d "$1" ]; then
    WORK_DIR="$(cd "$1" && pwd)"
    cd "$WORK_DIR" || exit 1
    echo "--- Processing directory: $WORK_DIR ---"

    # Collect RAW and supported raster files
    shopt -s nullglob nocaseglob
    FILES=()
    for ext in $RAW_EXTS; do
        FILES+=(*."$ext")
    done
    FILES+=(*.tif *.tiff *.png *.jpg *.jpeg)
    shopt -u nullglob nocaseglob

    # Deduplicate and sort
    mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | sort -u)
else
    # File list provided
    FILES=("$@")
    # Resolve paths and determine working directory from first file
    WORK_DIR="$(cd "$(dirname "${FILES[0]}")" && pwd)"
    cd "$WORK_DIR" || exit 1
    # Rebuild FILES with absolute paths for files that exist
    RESOLVED=()
    for f in "${FILES[@]}"; do
        if [ -f "$f" ]; then
            RESOLVED+=("$(cd "$(dirname "$f")" && pwd)/$(basename "$f")")
        else
            echo "Warning: Skipping non-existent file: $f"
        fi
    done
    FILES=("${RESOLVED[@]}")
    echo "--- Processing ${#FILES[@]} files in $WORK_DIR ---"
fi

# --- Separate RAW from pre-converted ---
RAW_FILES=()
OTHER_FILES=()
for f in "${FILES[@]}"; do
    ext="${f##*.}"
    ext_lower="${ext,,}"
    if [[ " $RAW_EXTS " == *" $ext_lower "* ]]; then
        RAW_FILES+=("$f")
    else
        OTHER_FILES+=("$f")
    fi
done
# Exclude TIFF/PNG/JPG that share base name with a RAW (darktable will produce the TIFF)
# Also exclude artifacts like IMG_3090.tif.tif when we have IMG_3090.CR3
FILTERED_OTHER=()
for f in "${OTHER_FILES[@]}"; do
    base_name=$(basename "${f%.*}")
    skip=0
    for raw in "${RAW_FILES[@]}"; do
        raw_base=$(basename "${raw%.*}")
        if [[ "$base_name" == "$raw_base" ]] || [[ "$base_name" == "$raw_base".* ]]; then
            skip=1
            break
        fi
    done
    [ "$skip" -eq 0 ] && FILTERED_OTHER+=("$f")
done
OTHER_FILES=("${FILTERED_OTHER[@]}")

# --- Convert RAW to 16-bit TIFF with darktable ---
TO_ALIGN=()
if [ ${#RAW_FILES[@]} -gt 0 ]; then
    echo "--- Step 1: Converting ${#RAW_FILES[@]} RAW file(s) to 16-bit TIFF ---"
    for raw in "${RAW_FILES[@]}"; do
        base="${raw%.*}"
        # darktable appends format extension; use base name so we get base.tif
        tif_out="${base}.tif"
        # darktable-cli: 16-bit TIFF, supports CR2/CR3/NEF/ARW/DNG etc.
        # --apply-custom-presets false: avoid database lock when GUI is open
        darktable-cli "$raw" "$base" --out-ext tiff \
            --apply-custom-presets false \
            --core --conf plugins/imageio/format/tiff/bpp=16
        if [ -f "$tif_out" ]; then
            CONVERTED_TIFFS+=("$tif_out")
            TO_ALIGN+=("$tif_out")
        else
            echo "Warning: darktable-cli did not produce output for $raw"
        fi
    done
fi

# Add pre-converted files
for f in "${OTHER_FILES[@]}"; do
    TO_ALIGN+=("$f")
done

# --- Check we have enough images ---
COUNT=${#TO_ALIGN[@]}
if [ "$COUNT" -lt 2 ]; then
    echo "Error: Need at least 2 images to stack. Found $COUNT."
    exit 1
fi

echo "Found $COUNT images to align and blend."

# --- Sort by exposure (exiftool if available, else keep order) ---
if command -v exiftool &> /dev/null; then
    # Sort by ExposureTime for consistent dark->bright order
    SORTED=()
    while IFS= read -r line; do
        [ -n "$line" ] && [ -f "$line" ] && SORTED+=("$line")
    done < <(
        for f in "${TO_ALIGN[@]}"; do
            exp=$(exiftool -ExposureTime -s3 -n "$f" 2>/dev/null || echo "0")
            printf '%s\t%s\n' "$exp" "$f"
        done | sort -t$'\t' -k1,1 -n | cut -f2-
    )
    if [ ${#SORTED[@]} -eq "$COUNT" ]; then
        TO_ALIGN=("${SORTED[@]}")
    fi
fi

# --- Cleanup trap ---
cleanup() {
    rm -f "${TEMP_PREFIX}"*.tif 2>/dev/null
    for t in "${CONVERTED_TIFFS[@]}"; do
        rm -f "$t" 2>/dev/null
    done
}
trap cleanup EXIT INT TERM

# --- Step 2: Align images ---
echo "--- Step 2: Aligning $COUNT images (this may take a moment) ---"
# -a: output prefix, -m: optimize FoV (handheld), -C: Auto crop
# -c 25: control points, -v: verbose
# (no -l: darktable output is not linear; -l only for dcraw-style linear TIFFs)
align_image_stack -a "$TEMP_PREFIX" -m -v -C -c 25 "${TO_ALIGN[@]}"

if [ ! -f "${TEMP_PREFIX}0000.tif" ]; then
    echo "Error: Alignment failed."
    exit 1
fi

# --- Step 3: Blend exposures with enfuse ---
OUTPUT_FILE="HDR_$(date +%Y%m%d_%H%M%S).tif"
echo "--- Step 3: Blending exposures into $OUTPUT_FILE ---"
enfuse -o "$OUTPUT_FILE" -v "${TEMP_PREFIX}"*.tif

# --- Step 4: Preserve EXIF metadata (merge from all sources) ---
# If values match: use as-is. If numeric and differ: average. If string and differ: "several values"
EXIF_SOURCES=()
if [ ${#RAW_FILES[@]} -gt 0 ]; then
    EXIF_SOURCES=("${RAW_FILES[@]}")
else
    EXIF_SOURCES=("${TO_ALIGN[@]}")
fi

merge_exif_tag() {
    local tag="$1"
    local numeric="$2"  # 1=numeric (average if differ), 0=string ("several values" if differ)
    local values=()
    local exif_opts="-s3"
    [[ "$numeric" -eq 1 ]] && exif_opts="-s3 -n"
    for src in "${EXIF_SOURCES[@]}"; do
        local val
        val=$(exiftool -"$tag" $exif_opts "$src" 2>/dev/null || true)
        [[ -n "$val" ]] && values+=("$val")
    done
    [[ ${#values[@]} -eq 0 ]] && return
    local first="${values[0]}"
    local all_same=1
    for v in "${values[@]}"; do
        [[ "$v" != "$first" ]] && { all_same=0; break; }
    done
    if [[ "$all_same" -eq 1 ]]; then
        exiftool -overwrite_original "-$tag=$first" "$OUTPUT_FILE" 2>/dev/null || true
    elif [[ "$numeric" -eq 1 ]]; then
        local avg
        avg=$(printf '%s\n' "${values[@]}" | awk '{ sum+=$1; n++ } END { if(n>0) printf "%.4f", sum/n }')
        [[ -n "$avg" ]] && exiftool -overwrite_original "-$tag=$avg" "$OUTPUT_FILE" 2>/dev/null || true
    else
        exiftool -overwrite_original "-$tag=several values" "$OUTPUT_FILE" 2>/dev/null || true
    fi
}

echo "--- Step 4: Preserving EXIF metadata ---"
merge_exif_tag "Make" 0
merge_exif_tag "Model" 0
merge_exif_tag "LensModel" 0
merge_exif_tag "LensID" 0
merge_exif_tag "LensMake" 0
merge_exif_tag "LensSerialNumber" 0
merge_exif_tag "LensDescription" 0
merge_exif_tag "LensInfo" 0
merge_exif_tag "LensSpecification" 0
merge_exif_tag "FNumber" 1
merge_exif_tag "ApertureValue" 1
merge_exif_tag "ExposureTime" 1
merge_exif_tag "ShutterSpeedValue" 1
merge_exif_tag "ExposureProgram" 0
merge_exif_tag "MeteringMode" 0
merge_exif_tag "WhiteBalance" 0
merge_exif_tag "Flash" 0
merge_exif_tag "FocalLength" 1
merge_exif_tag "ISO" 1
merge_exif_tag "ISOSpeedRatings" 1
merge_exif_tag "Keywords" 0
merge_exif_tag "XMP-dc:Subject" 0
merge_exif_tag "Artist" 0
merge_exif_tag "XMP-dc:Creator" 0
merge_exif_tag "Copyright" 0
merge_exif_tag "XMP-dc:Rights" 0
merge_exif_tag "GPSLongitude" 1
merge_exif_tag "GPSLongitudeRef" 0
merge_exif_tag "GPSLatitude" 1
merge_exif_tag "GPSLatitudeRef" 0
merge_exif_tag "GPSAltitude" 1
merge_exif_tag "GPSAltitudeRef" 0
merge_exif_tag "DateTimeOriginal" 0
merge_exif_tag "CreateDate" 0
# Canon CR3 often has LensModel empty; use LensID as fallback
lensmodel=$(exiftool -LensModel -s3 "$OUTPUT_FILE" 2>/dev/null || true)
if [[ -z "$lensmodel" ]]; then
    lensid=$(exiftool -LensID -s3 "$OUTPUT_FILE" 2>/dev/null || true)
    [[ -n "$lensid" ]] && exiftool -overwrite_original -LensModel="$lensid" "$OUTPUT_FILE" 2>/dev/null || true
fi
exiftool -overwrite_original -UserComment="HDR Stacked with @hdr_stack_raw.sh" "$OUTPUT_FILE" 2>/dev/null || true

# Clear trap so we don't remove output; cleanup aligned temp files only
trap - EXIT INT TERM
rm -f "${TEMP_PREFIX}"*.tif 2>/dev/null
for t in "${CONVERTED_TIFFS[@]}"; do
    rm -f "$t" 2>/dev/null
done

echo "Done. Output: $WORK_DIR/$OUTPUT_FILE"
