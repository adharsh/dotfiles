#!/bin/bash

set -e

# Find the name of the second monitor
second_monitor=$(xrandr --query | rg ' connected ' | tail -1 | awk '{print $1}')
if [ "$second_monitor" != "eDP-1" ]; then
  # Change monitor outputs with xrandr
  xrandr --output eDP-1 --primary --mode 3000x2000 --pos 0x1080 --rotate normal --output DP-1 --off --output DP-2 --mode 1920x1080 --pos 0x0 --rotate normal --output HDMI-1 --off
  xrandr --output eDP-1 --primary --scale 1.28x1.28 --pos 0x2160 --rotate normal --output $second_monitor --scale 2x2

#  i3-msg "workspace 1, move workspace to output $second_monitor"
  i3-msg "workspace 2, move workspace to output $second_monitor"
  i3-msg "workspace 4, move workspace to output $second_monitor"
  i3-msg "workspace 6, move workspace to output $second_monitor"
  i3-msg "workspace 8, move workspace to output $second_monitor"
  i3-msg "workspace 10, move workspace to output $second_monitor"
else
  xrandr --auto
fi
