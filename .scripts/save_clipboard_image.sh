#!/bin/bash

# Configuration file to store the last used directory
CONFIG_FILE="$HOME/.screenshot_save_config"

# Function to get the last used directory
get_last_directory() {
    if [ -f "$CONFIG_FILE" ]; then
        cat "$CONFIG_FILE"
    else
        pwd
    fi
}

# Function to save the last used directory
save_last_directory() {
    dirname "$1" > "$CONFIG_FILE"
}

save_markdown_to_clipboard() {
    local filepath="$1"
    local filename
    local parent_dir

    filename=$(basename "$filepath")
    parent_dir=$(basename "$(dirname "$filepath")")
    
    # Create the Markdown image syntax based on the parent directory
    if [ "$parent_dir" = "imgs" ]; then
        markdown_path="imgs/$filename"
    else
        markdown_path="$filename"
    fi

    # Option 1: Set markdown str to standard markdown
    # markdown_str="![${filename}](${markdown_path})"
    # echo -n "${markdown_str}" | xclip -selection clipboard

    # Option 2: Set markdown str to centered image with percentage width
    markdown_str="<div style=\"text-align: center;\">
    <img src=\"${markdown_path}\" 
        style=\"max-width: 70%; height: auto;\" 
        alt=\"${filename}\">
</div>"
    echo -e -n "${markdown_str}" | xclip -selection clipboard
}

# Generate a consistent filename for the screenshot
screenshot_filename="screenshot-$(date '+%Y-%m-%d-%H-%M-%S-%N').png"

# Check for quick save flag
while getopts "q" opt; do
    case $opt in
        q) 
            # Get last directory and generate save path
            save_path="$(get_last_directory)/$screenshot_filename"
            
            # Capture screenshot directly to final location
            if ! maim -s --hidecursor "$save_path" || [ ! -s "$save_path" ]; then
                rm -f "$save_path"
                exit 1
            fi
            
            # Save markdown to clipboard and exit
            save_markdown_to_clipboard "$save_path"
            notify-send "Screenshot saved" "$save_path" -t 3000
            exit 0
            ;;
         *) 
             echo "Usage: $(basename "$0") [-q]" >&2
             echo "  -q    Quick save to last used directory" >&2
             exit 1
             ;;
    esac
done

# Create a temporary file for the screenshot
TEMP_IMAGE=$(mktemp --suffix=.png)

# Capture the screenshot directly to the file
#  and check the exit status of maim and the file size
if ! maim -s --hidecursor "$TEMP_IMAGE" || [ ! -s "$TEMP_IMAGE" ]; then
    echo "Failed to capture screenshot or screenshot was cancelled. Exiting."
    rm -f "$TEMP_IMAGE"
    exit 1
fi

# If we get here, we have a valid screenshot. Now copy it to clipboard
# xclip -selection clipboard -t image/png < "$TEMP_IMAGE"

# Get the last used directory
last_dir=$(get_last_directory)

# Use yad to open a file selection dialog, starting in the last used directory with default filename
save_path=$(yad --file-selection --save --filename="$last_dir/$screenshot_filename" --title="Select where to save the image")

# Check if a file was selected
if [ -n "$save_path" ]; then
    # Move the temporary image file to the selected save path
    mv "$TEMP_IMAGE" "$save_path"
    
    # Save the directory of the successful save
    save_last_directory "$save_path"
        
    # Save markdown to clipboard
    save_markdown_to_clipboard "$save_path"
else
    echo "No file selected. Exiting."
    rm -f "$TEMP_IMAGE"
fi

# Clean up temporary file if it still exists
rm -f "$TEMP_IMAGE"
