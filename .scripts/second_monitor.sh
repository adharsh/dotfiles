#!/bin/bash

set -e

# Find the name of the second monitor
second_monitor=$(xrandr --query | rg ' connected ' | tail -1 | awk '{print $1}')

if [ "$second_monitor" != "eDP-1" ]; then
  # Change monitor outputs with xrandr
  xrandr --output "$second_monitor" --auto --above eDP-1

  i3-msg "workspace 1, move workspace to output $second_monitor"
  i3-msg "workspace 2, move workspace to output $second_monitor"
  i3-msg "workspace 4, move workspace to output $second_monitor"
  i3-msg "workspace 10, move workspace to output $second_monitor"
else
  xrandr --auto
fi

