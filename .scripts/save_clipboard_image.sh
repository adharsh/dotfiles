#!/bin/bash

# Capture screenshot to clipboard
maim -s | xclip -selection clipboard -t image/png

# Use zenity to open a file selection dialog
save_path=$(zenity --file-selection --save --filename="clipboard_image.png" --title="Select where to save the image")

# Check if a file was selected
if [ -n "$save_path" ]; then
    # Use xclip to get the image from clipboard and convert it to PNG
    xclip -selection clipboard -t image/png -o > "$save_path"
    
    # Check if the save failed
    if [ $? -ne 0 ]; then
        zenity --error --text="Failed to save the image"
    fi
else
    echo "No file selected. Exiting."
fi
