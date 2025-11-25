#!/bin/bash

# Check if exactly two arguments are passed
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <flash_image> <ambient_image>"
    exit 1
fi

FLASH_IMG="$1"
AMBIENT_IMG="$2"
PREFIX="aligned_temp"

echo "--- Step 1: Aligning images with Hugin ---"
# -a: Prefix for output files
# -m: Optimize field of view (crucial for focus breathing correction)
# -v: Verbose
# -C: Auto crop to the area covered by both images (removes black borders)
# -c 25: Use 25 control points (good balance of speed/accuracy)
align_image_stack -a "$PREFIX" -m -v -C -c 25 "$FLASH_IMG" "$AMBIENT_IMG"

# Check if alignment was successful (files created)
if [ ! -f "${PREFIX}0000.tif" ]; then
    echo "Error: Alignment failed. Please check input files."
    exit 1
fi

echo "--- Step 2: Stacking images for GIMP ---"
# We use ImageMagick (convert) to stack the two TIFs into one multi-page TIF.
# When GIMP opens this, it will ask to import as "Layers".
OUTPUT_FILE="flambient_stack.tif"

if command -v convert &> /dev/null; then
    convert "${PREFIX}0000.tif" "${PREFIX}0001.tif" "$OUTPUT_FILE"
    echo "Images stacked into $OUTPUT_FILE"
    
    # Cleanup intermediate files
    rm "${PREFIX}0000.tif" "${PREFIX}0001.tif"
else
    echo "ImageMagick not found. Opening separated aligned files..."
    OUTPUT_FILE="${PREFIX}0000.tif ${PREFIX}0001.tif"
fi

echo "--- Step 3: Launching GIMP ---"
# Open the file.
# NOTE: When GIMP opens, a dialog will appear. Select "Open pages as: Layers".
gimp "$OUTPUT_FILE" &

echo "Done! Happy blending."