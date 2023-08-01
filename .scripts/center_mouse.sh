#!/bin/bash

XTE=/usr/bin/xte

WINDOW=`xdotool getwindowfocus`

# Get the window geometry using xdotool
eval $(xdotool getwindowgeometry --shell $WINDOW)

# Calculate the center of the window
TX=$((WIDTH / 2))
TY=$((HEIGHT / 2))

# Calculate the desired mouse coordinates relative to the center of the window
MOUSE_X=$((X + TX))
MOUSE_Y=$((Y + TY))

# Move the mouse to the calculated coordinates using xte
$XTE "mousemove $MOUSE_X $MOUSE_Y"