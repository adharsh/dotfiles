#!/bin/bash

set -e

# Function to check if a workspace is empty and create a terminal if it is
create_terminal_if_empty() {
    workspace=$1
    # Check if the workspace is empty
    if [ -z "$(i3-msg -t get_tree | jq ".nodes[].nodes[].nodes[] | select(.name == \"$workspace\") | .nodes[]")" ]; then
        # If empty, create a new terminal
        i3-msg "workspace $workspace; exec i3-sensible-terminal"
    fi
}

# Create terminals in empty workspaces
for workspace in 1 2 3 4 5 6 7 8 9 10; do
    create_terminal_if_empty $workspace
done

# Find the name of the second monitor
first_monitor="eDP-1" 
second_monitor=$(xrandr --query | rg ' connected ' | tail -1 | awk '{print $1}')

if [ "$second_monitor" != "eDP-1" ]; then
    # Get the dimensions of the second monitor from the line below its name
    second_monitor_res=$(xrandr --query | awk "/$second_monitor/{getline; print \$1}")
    second_monitor_width=$(echo $second_monitor_res | cut -d'x' -f1)
    second_monitor_height=$(echo $second_monitor_res | cut -d'x' -f2)

    # Get the dimensions of the first monitor (eDP-1)
    first_monitor_res=$(xrandr --query | grep "^$first_monitor" | grep -oP '\d+x\d+' | head -1)
 
    # Change monitor outputs with xrandr
    xrandr --output $first_monitor --primary --mode $first_monitor_res --pos 0x$second_monitor_height --rotate normal --output $second_monitor --mode $second_monitor_res --pos 0x0 --rotate normal
 
    # Move workspaces to the second monitor
    # i3-msg "workspace 1, move workspace to output $first_monitor"

    i3-msg "workspace 2, move workspace to output $second_monitor"
    # i3-msg "workspace 3, move workspace to output $first_monitor"

    i3-msg "workspace 4, move workspace to output $second_monitor"
    # i3-msg "workspace 5, move workspace to output $first_monitor"

    i3-msg "workspace 6, move workspace to output $second_monitor"
    # i3-msg "workspace 7, move workspace to output $first_monitor"

    i3-msg "workspace 8, move workspace to output $second_monitor"
    # i3-msg "workspace 9, move workspace to output $first_monitor"

    # i3-msg "workspace 10, move workspace to output $first_monitor"

    # Set focus back to workspace 2 and then 3
    i3-msg "workspace 2"
    i3-msg "workspace 3"

else
    # If single monitor, reset the monitor settings
    xrandr --auto

    # Set focus back to workspace 3
    i3-msg "workspace 3"
fi
