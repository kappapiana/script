#!/bin/bash
set -euo pipefail

# HDR RAW Stack - Align and blend bracketed exposures into a single HDR image.
# Linux only. Requires: hugin-tools, enblend-enfuse, dcraw
#
# Usage: ./hdr_stack_raw.sh [directory|file1 file2 ...]
#   With directory: process all RAW files in that folder
#   With files: process the given RAW/TIFF/PNG/JPG files
# Output: HDR_YYYYMMDD_HHMMSS.tif in the same directory

# --- Linux check ---
if [ "$(uname -s)" != "Linux" ]; then
    echo "Error: This script is Linux-only."
    exit 1
fi

# --- Dependency check ---
MISSING=()
for cmd in align_image_stack enfuse dcraw; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING+=("$cmd")
    fi
done
if [ ${#MISSING[@]} -gt 0 ]; then
    echo "Error: Missing required tools: ${MISSING[*]}"
    echo "Install with: sudo apt install hugin-tools enblend-enfuse dcraw"
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
# Exclude TIFF/PNG/JPG that share base name with a RAW (dcraw will produce the TIFF)
FILTERED_OTHER=()
for f in "${OTHER_FILES[@]}"; do
    base_name=$(basename "${f%.*}")
    skip=0
    for raw in "${RAW_FILES[@]}"; do
        raw_base=$(basename "${raw%.*}")
        if [[ "$base_name" == "$raw_base" ]]; then
            skip=1
            break
        fi
    done
    [ "$skip" -eq 0 ] && FILTERED_OTHER+=("$f")
done
OTHER_FILES=("${FILTERED_OTHER[@]}")

# --- Convert RAW to 16-bit linear TIFF ---
TO_ALIGN=()
if [ ${#RAW_FILES[@]} -gt 0 ]; then
    echo "--- Step 1: Converting ${#RAW_FILES[@]} RAW file(s) to 16-bit linear TIFF ---"
    for raw in "${RAW_FILES[@]}"; do
        base="${raw%.*}"
        tif_out="${base}.tif"
        # dcraw -4: 16-bit linear, -T: TIFF output, -w: use camera white balance
        dcraw -4 -T -w "$raw"
        if [ -f "$tif_out" ]; then
            CONVERTED_TIFFS+=("$tif_out")
            TO_ALIGN+=("$tif_out")
        else
            echo "Warning: dcraw did not produce output for $raw"
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
# -l: Linear input (RAW-derived TIFFs), -a: output prefix, -m: optimize FoV (handheld)
# -C: Auto crop, -c 25: control points, -v: verbose
align_image_stack -l -a "$TEMP_PREFIX" -m -v -C -c 25 "${TO_ALIGN[@]}"

if [ ! -f "${TEMP_PREFIX}0000.tif" ]; then
    echo "Error: Alignment failed."
    exit 1
fi

# --- Step 3: Blend exposures with enfuse ---
OUTPUT_FILE="HDR_$(date +%Y%m%d_%H%M%S).tif"
echo "--- Step 3: Blending exposures into $OUTPUT_FILE ---"
enfuse -o "$OUTPUT_FILE" -v "${TEMP_PREFIX}"*.tif

# Clear trap so we don't remove output; cleanup aligned temp files only
trap - EXIT INT TERM
rm -f "${TEMP_PREFIX}"*.tif 2>/dev/null
for t in "${CONVERTED_TIFFS[@]}"; do
    rm -f "$t" 2>/dev/null
done

echo "Done. Output: $WORK_DIR/$OUTPUT_FILE"
