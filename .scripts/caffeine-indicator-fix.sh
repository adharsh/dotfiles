#!/bin/bash

file_path="/usr/bin/caffeine-indicator"
line_to_insert="caffeine.toggle_activated()"
target_line="caffeine = Caffeine()"

# Check if the file exists
if [ ! -f "$file_path" ]; then
    echo "caffeine-indicator-fix error: File doesn't exist."
    exit 1
fi

# Check if target line exists
if ! grep -q "$target_line" "$file_path"; then
    echo "caffeine-indicator-fix error: Target line doesn't exist in the file."
    exit 1
fi

# Check if line_to_insert is already after target_line
if grep "$target_line" -A 1 "$file_path" | grep -q "$line_to_insert"; then
    echo "caffeine-indicator-fix: Line already exists immediately after the target line in the file. No need to insert."
    exit 0
fi

# Insert the line using sed without creating a temporary file
if ! sudo sed -i "/$target_line/a $line_to_insert" "$file_path"; then
    echo "caffeine-indicator-fix error: Failed to insert line."
    exit 1
fi

echo "caffeine-indicator-fix run successfully."