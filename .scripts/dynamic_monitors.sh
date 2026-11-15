#!/bin/bash
# Lay out the screens: an external monitor, if one is connected, goes above the laptop screen;
# otherwise the laptop screen is used alone.
# Run by .xsessionrc before i3 starts, so i3 never sees the mirrored screens the NVIDIA driver sets
# up at boot, by Alt+m, and with --if-changed by srandrd when a monitor is plugged in or pulled out.
# Which workspaces go on which screen is set by the "workspace N output" lines in the i3 config:
# i3 moves them over itself when a screen turns on or off.

set -e

# The outputs that were connected when the screens were last laid out
state="${XDG_RUNTIME_DIR:-/tmp}/dynamic_monitors_connected"

query=$(xrandr --query)
# " connected" with the space, so disconnected outputs don't match
connected=$(awk '/ connected/ {print $1}' <<<"$query")

# srandrd runs this on every output change, including the ones made below, so only act on a plug or unplug
if [ "$1" = --if-changed ] && [ "$connected" = "$(cat "$state" 2>/dev/null)" ]; then
    exit 0
fi

laptop=$(awk '/ connected primary/ {print $1; exit}' <<<"$query")
external=$(awk -v laptop="$laptop" '/ connected/ && $1 != laptop {print $1; exit}' <<<"$query")

if [ -n "$external" ]; then
    # The first mode listed under an output is its preferred one
    mode=$(awk -v output="$external" '$1 == output {getline; print $1; exit}' <<<"$query")
    echo "dynamic_monitors.sh: $external at $mode above $laptop"
    xrandr --output "$laptop" --primary --pos "0x${mode#*x}" --rotate normal \
        --output "$external" --mode "$mode" --pos 0x0 --rotate normal
else
    echo "dynamic_monitors.sh: $laptop only"
    xrandr --auto
fi

# Saved only once xrandr worked, so a failed attempt is retried on srandrd's next event
echo "$connected" >"$state"
