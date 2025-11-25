#!/bin/bash

# Resizes images to a 4:3 dimension, by adding space to one dimension and some padding to all of them
# NOTE: works only with Imagemagick 6 or less (I think)

# Define the target aspect ratio (4:3)
TARGET_RATIO="1.3333333" # 4/3

# --- NEW: Define padding as a percentage of the largest dimension ---
PADDING_PERCENT="10"      # 5% (You can change this value)

# Input and output file names
INPUT_FILE="$1"
OUTPUT_FILE="$2"

if [ -z "$INPUT_FILE" ] || [ -z "$OUTPUT_FILE" ]; then
    echo "Usage: $0 <input_file> <output_file>"
    exit 1
fi

# 1. Get original width and height
ORIG_W=$(identify -format "%w" "$INPUT_FILE")
ORIG_H=$(identify -format "%h" "$INPUT_FILE")

# 2. Calculate the dynamic padding based on the largest dimension
# Find the largest dimension (MAX_DIM)
MAX_DIM=$ORIG_W
if [ "$ORIG_H" -gt "$MAX_DIM" ]; then
    MAX_DIM=$ORIG_H
fi

# Calculate the actual padding amount in pixels (2 * PADDING for each side)
# We calculate 2 * PADDING (the total padding) to simplify the final canvas math.
# TOTAL_PADDING = MAX_DIM * (PADDING_PERCENT / 100)
# Use 'bc' for floating-point calculation and then round down to an integer.
TOTAL_PADDING=$(echo "scale=0; ($MAX_DIM * $PADDING_PERCENT / 100) / 1" | bc)

# Ensure TOTAL_PADDING is at least 1, to prevent zero-padding edge cases
if [ "$TOTAL_PADDING" -eq 0 ]; then
    TOTAL_PADDING=1
fi


# 3. Calculate the required final width (FW) and final height (FH) for the 4:3 canvas

# Calculate original ratio (w/h) for comparison
ORIG_RATIO=$(echo "scale=8; $ORIG_W / $ORIG_H" | bc -l)

if (( $(echo "$ORIG_RATIO > $TARGET_RATIO" | bc -l) )); then
    # Case: Image is TALLER (e.g., 3:4, ratio < 1.333)
    # Width (FW) is set to original width. We calculate the new required Height (FH).
    FW="$ORIG_W"
    # New Height = Original Width / Target Ratio
    FH=$(echo "scale=0; $ORIG_W / $TARGET_RATIO / 1" | bc)
else
    # Case: Image is WIDER (e.g., 16:9, ratio > 1.333)
    # Height (FH) is set to original height. We calculate the new required Width (FW).
    FH="$ORIG_H"
    # New Width = Original Height * Target Ratio
    FW=$(echo "scale=0; $ORIG_H * $TARGET_RATIO / 1" | bc)
fi

# 4. Final Canvas Dimensions
# Final Canvas Width = FW + TOTAL_PADDING
# Final Canvas Height = FH + TOTAL_PADDING
FINAL_W=$((FW + TOTAL_PADDING))
FINAL_H=$((FH + TOTAL_PADDING))

# 5. Create the image with padding and target canvas (using IMv6 convert)
convert "$INPUT_FILE" \
    -background transparent \
    -gravity center \
    -extent "${FINAL_W}x${FINAL_H}" \
    "$OUTPUT_FILE"

echo "Processed '$INPUT_FILE' to '$OUTPUT_FILE' with canvas ${FINAL_W}x${FINAL_H} (Padding: ${TOTAL_PADDING}px total)"