#!/bin/bash

# Configuration file to store the last used directory
CONFIG_FILE="$HOME/.screenshot_save_config"

# Function to get the last used directory
get_last_directory() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        echo "$HOME"
    fi
}

# Function to save the last used directory
save_last_directory() {
    dirname "$1" > "$CONFIG_FILE"
}

# Create a temporary file for the screenshot
TEMP_IMAGE=$(mktemp --suffix=.png)

# Capture the screenshot directly to the file
maim -s "$TEMP_IMAGE"

# Check the exit status of maim and the file size
if [ $? -ne 0 ] || [ ! -s "$TEMP_IMAGE" ]; then
    echo "Failed to capture screenshot or screenshot was cancelled. Exiting."
    rm -f "$TEMP_IMAGE"
    exit 1
fi

# If we get here, we have a valid screenshot. Now copy it to clipboard
xclip -selection clipboard -t image/png < "$TEMP_IMAGE"

# Get the last used directory
last_dir=$(get_last_directory)

# Use zenity to open a file selection dialog, starting in the last used directory
save_path=$(zenity --file-selection --save --filename="$last_dir/clipboard_image.png" --title="Select where to save the image")

# Check if a file was selected
if [ -n "$save_path" ]; then
    # Move the temporary image file to the selected save path
    mv "$TEMP_IMAGE" "$save_path"
    
    # Check if the save was successful
    if [ $? -eq 0 ]; then
        # Save the directory of the successful save
        save_last_directory "$save_path"
        
        # Get the filename and parent directory from the full path
        filename=$(basename "$save_path")
        parent_dir=$(basename "$(dirname "$save_path")")
        
        # Create the Markdown image syntax based on the parent directory
        if [ "$parent_dir" = "imgs" ]; then
            # Use relative path if parent directory is "imgs"
            markdown_path="imgs/$filename"
        else
            # # Save to absolute path
            # markdown_path="$save_path"

            # Save to current working directory
            markdown_path="$filename"
        fi
         
        # Option 1: Set markdown str to standard markdown
        # markdown_str="![${filename}](${markdown_path})"
        # echo -n "${markdown_str}" | xclip -selection clipboard

        # Option 2: Set markdown str to half width and centered image
        markdown_str="<div align=\"center\">\n  <img src=\"${markdown_path}\" style=\"max-width: 50%; height: auto;\" alt=\"${filename}\">\n</div>"
        echo -e -n "${markdown_str}" | xclip -selection clipboard

    else
        zenity --error --text="Failed to save the image"
    fi
else
    echo "No file selected. Exiting."
    rm -f "$TEMP_IMAGE"
fi

# Clean up temporary file if it still exists
rm -f "$TEMP_IMAGE"
