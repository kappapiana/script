#!/bin/bash

# This has been vibecoded with Gemini use at your peril
# I don't believe any copyright goes here

# 1. Set the target directory
# Uses the first argument provided, or defaults to current folder (.)
DIR="${1:-.}"

# Remove trailing slash from directory path if present
DIR="${DIR%/}"

echo "--- Processing folder: $DIR ---"

# 2. Collect all image files into an array
# We enable nullglob so the script doesn't error if no files of a type exist
shopt -s nullglob
FILES=("$DIR"/*.jpg "$DIR"/*.jpeg "$DIR"/*.tif "$DIR"/*.tiff "$DIR"/*.png)
shopt -u nullglob

# Check if we have enough images
COUNT=${#FILES[@]}
if [ "$COUNT" -lt 2 ]; then
    echo "Error: Found $COUNT images. Need at least 2 to align."
    exit 1
fi

echo "Found $COUNT images to stack."

# 3. Align Images
# Prefix for temporary aligned files
TEMP_PREFIX="aligned_temp"

echo "--- Step 1: Aligning $COUNT images (this may take a moment) ---"
# -a: Output prefix
# -m: Optimize field of view (fixes focus breathing between shots)
# -v: Verbose
# -C: Auto crop to remove black edges from alignment
# -c 25: Control points
# "${FILES[@]}" expands the array to the list of files, handling spaces safely
align_image_stack -a "$TEMP_PREFIX" -m -v -C -c 25 "${FILES[@]}"

# Check for success
if [ ! -f "${TEMP_PREFIX}0000.tif" ]; then
    echo "Error: Alignment failed."
    exit 1
fi

# 4. Stack Images for GIMP
OUTPUT_FILE="Room_Stack.tif"
echo "--- Step 2: Stacking aligned layers into $OUTPUT_FILE ---"

# Use wildcard to grab all the numbered output files from align_image_stack
if command -v convert &> /dev/null; then
    # Convert all temp tifs into one multipage tif
    convert "${TEMP_PREFIX}"*.tif "$OUTPUT_FILE"
    
    echo "Success! Cleaning up temp files..."
    rm "${TEMP_PREFIX}"*.tif
else
    echo "ImageMagick not found. Leaving aligned files separate."
    # If convert fails, we define OUTPUT_FILE as the list of temp files so GIMP opens them all
    OUTPUT_FILE="${TEMP_PREFIX}*.tif"
fi

# 5. Open in GIMP
echo "--- Step 3: Opening GIMP ---"
# Reminder for the user
echo "IMPORTANT: In the GIMP dialog, ensure you select 'Open pages as: Layers'"

if which gimp; then
    gimp $OUTPUT_FILE & # try to use gimp if installed
else
    /usr/bin/flatpak run org.gimp.GIMP $OUTPUT_FILE & #maybe it's installed via flatpack
fi 

echo "Done."