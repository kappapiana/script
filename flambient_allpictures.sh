#!/bin/bash
set -euo pipefail

# This has been vibecoded with Gemini use at your peril
# I don't believe any copyright goes here

# 1. Set the target directory
# Uses the first argument provided, or defaults to current folder (.)
DIR="${1:-.}"

# Remove trailing slash from directory path if present
DIR="${DIR%/}"

# Change to target directory so output lands next to the images
cd "$DIR" || { echo "Error: Cannot access directory '$DIR'"; exit 1; }

echo "--- Processing folder: $DIR ---"

# 2. Check dependencies
if ! command -v align_image_stack &> /dev/null; then
    echo "Error: align_image_stack not found. Install hugin-tools or similar."
    exit 1
fi

# 3. Collect all image files into an array
# nullglob: no error if no files match
# nocaseglob: match .JPG, .PNG etc. as well
shopt -s nullglob nocaseglob
FILES=(*.jpg *.jpeg *.JPG *.JPEG *.tif *.tiff *.TIF *.TIFF *.png *.PNG)
shopt -u nullglob nocaseglob

# Deduplicate (nocaseglob can produce duplicates on case-insensitive filesystems)
# Sort by name for consistent ordering
mapfile -t FILES < <(printf '%s\n' "${FILES[@]}" | sort -u)

# Check if we have enough images
COUNT=${#FILES[@]}
if [ "$COUNT" -lt 2 ]; then
    echo "Error: Found $COUNT images. Need at least 2 to align."
    exit 1
fi

echo "Found $COUNT images to stack."

# 4. Align Images
TEMP_PREFIX="aligned_temp"

echo "--- Step 1: Aligning $COUNT images (this may take a moment) ---"
# -a: Output prefix  -m: Optimize field of view  -v: Verbose
# -C: Auto crop to remove black edges  -c 25: Control points
align_image_stack -a "$TEMP_PREFIX" -m -v -C -c 25 "${FILES[@]}"

# Check for success
if [ ! -f "${TEMP_PREFIX}0000.tif" ]; then
    echo "Error: Alignment failed."
    exit 1
fi

# 5. Stack Images for GIMP
OUTPUT_FILE="Room_Stack.tif"
echo "--- Step 2: Stacking aligned layers into $OUTPUT_FILE ---"

if command -v convert &> /dev/null; then
    # Clean up temp files on exit (including interrupt)
    trap 'rm -f "${TEMP_PREFIX}"*.tif 2>/dev/null' EXIT INT TERM

    convert "${TEMP_PREFIX}"*.tif "$OUTPUT_FILE"

    echo "Success! Cleaning up temp files..."
    rm -f "${TEMP_PREFIX}"*.tif
    trap - EXIT INT TERM

    echo "--- Step 3: Opening GIMP ---"
    echo "IMPORTANT: In the GIMP dialog, ensure you select 'Open pages as: Layers'"

    if command -v gimp &> /dev/null; then
        gimp "$OUTPUT_FILE" &
    elif command -v flatpak &> /dev/null; then
        flatpak run org.gimp.GIMP "$OUTPUT_FILE" &
    else
        echo "GIMP not found. Output saved as: $DIR/$OUTPUT_FILE"
    fi
else
    echo "ImageMagick not found. Leaving aligned files separate."
    echo "--- Step 3: Opening GIMP ---"
    echo "IMPORTANT: In the GIMP dialog, ensure you select 'Open pages as: Layers'"

    # Expand glob to list of files for GIMP
    temp_files=("${TEMP_PREFIX}"*.tif)
    if command -v gimp &> /dev/null; then
        gimp "${temp_files[@]}" &
    elif command -v flatpak &> /dev/null; then
        flatpak run org.gimp.GIMP "${temp_files[@]}" &
    else
        echo "GIMP not found. Aligned files: ${temp_files[*]}"
    fi
fi

echo "Done."
