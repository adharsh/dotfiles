#!/bin/bash
# Open a terminal on each given i3 workspace that has no windows (default: 1-10).
# Run at login from the i3 config, and by dynamic_monitors.sh (Alt+m).

set -e

[ $# -eq 0 ] && set -- 1 2 3 4 5 6 7 8 9 10

for workspace in "$@"; do
    # A workspace that doesn't exist yet comes back empty too
    if [ -z "$(i3-msg -t get_tree | jq --arg ws "$workspace" '.nodes[].nodes[].nodes[] | select(.name == $ws) | .nodes[]')" ]; then
        # Plain exec (no --no-startup-id): i3's startup notification puts the window on this workspace
        i3-msg "workspace $workspace; exec i3-sensible-terminal"
    fi
done
