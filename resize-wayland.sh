#!/bin/bash

# A wmctrl-like utility for precise window resizing on GNOME Wayland
# Requires the 'Window Calls' or similar extension to be installed in GNOME.

# --- Input Validation ---

# Check if the correct number of arguments (3) was passed
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <window_class> <width_pixels> <height_pixels>"
    echo "Example: $0 chromium-browser 2048 1200"
    exit 1
fi

# Assign arguments to variables
WIN_CLASS="$1"
TARGET_WIDTH="$2"
TARGET_HEIGHT="$3"

# --- D-Bus Command Execution ---

gdbus call \
    --session \
    --dest org.gnome.Shell \
    --object-path /org/gnome/Shell \
    --method org.gnome.Shell.Eval \
"
    // Find the first window matching the class
    let target_window = global.get_window_actors().map(a => a.meta_window).find(w => w.get_wm_class() === '${WIN_CLASS}');

    if (target_window) {
        // Get the window's current position to avoid moving it to (0,0)
        let frame_rect = target_window.get_frame_rect();
        let x = frame_rect.x;
        let y = frame_rect.y;

        // Get the monitor index the window is currently on
        let monitor_index = global.get_screen().get_monitor_index_for_rect(frame_rect);

        // Perform the move and resize operation
        target_window.move_resize(
            monitor_index,
            x, // Keep current X position
            y, // Keep current Y position
            ${TARGET_WIDTH},
            ${TARGET_HEIGHT}
        );
        print('Resized window: ' + target_window.get_title());
    } else {
        print('Error: No window found with class: ${WIN_CLASS}');
    }
"
