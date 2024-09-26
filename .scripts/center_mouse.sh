#!/bin/bash

# Get focused window
WINDOW=$(xdotool getwindowfocus)

# Move mouse to the center of the focused window
xdotool mousemove --window $WINDOW --polar 0 0
