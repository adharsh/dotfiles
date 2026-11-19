#!/usr/bin/env bash
# i3status, with stt's dot at the left of it: orange while stt records (a dictation or a
# meeting), blue while it transcribes or analyzes a meeting, and nothing otherwise.
# Each is in full color for its first second, so you see it start, then dims, so it doesn't
# catch the eye on a shared screen. Being at the left, it never moves the rest of the bar.
# After the dot come the Claude Code sessions (see claude_marks).
# The i3 config's status_command runs this instead of i3status.
#
# stt writes $XDG_RUNTIME_DIR/stt/<kind>.pid while it records and <pid>.busy while it
# works, each holding the pid, and sends i3status SIGUSR1 when one comes or goes, so the
# dot follows at once. The dimming waits for i3status's next second.

run="${XDG_RUNTIME_DIR:-/run/user/$UID}/stt"
claude_run="${XDG_RUNTIME_DIR:-/run/user/$UID}/claude-sessions"
bright_us=1000000

# mark GLOB BRIGHT DIM: a dot if a file matching GLOB holds a live pid, in BRIGHT for
# bright_us after the newest of them was written, then in DIM
mark() {
    local file pid written newest=0 color=$3
    for file in "$run"/$1; do
        [ -f "$file" ] || continue
        { pid=$(<"$file"); } 2>/dev/null  # quiet if it went just now
        kill -0 "$pid" 2>/dev/null || continue  # left by a process that's gone
        written=$(stat -c %.6Y "$file" 2>/dev/null) || continue
        written=${written/[.,]/}
        ((written > newest)) && newest=$written
    done
    ((newest)) || return 0
    ((${EPOCHREALTIME/[.,]/} - newest < bright_us)) && color=$2
    printf '{"name":"stt","full_text":"●","color":"%s"},' "$color"
}

# The Claude Code sessions that .scripts/claude_sessions.sh collects: a ✻ and the folder for
# each, after its host if it's not this laptop. Dim green while Claude works, bright green
# when it's your turn, and red while claude agents calls it "waiting", which looks like a
# question or permission for you.
claude_marks() {
    local files=("$claude_run"/*.json)
    [ -f "${files[0]}" ] || return 0
    # Each file is a line of JSON; one that isn't (claude printed something else) is skipped.
    jq -nRj '
        [inputs | (fromjson? // [])[] + {host: input_filename | split("/") | last | rtrimstr(".json")}]
        | sort_by(.host != "local")[]
        | {name: "claude",
           full_text: "✻ \(if .host == "local" then "" else "\(.host):" end)\(.cwd | split("/") | last)",
           color: ({busy: "#4f7a5f", waiting: "#ff6b6b"}[.status] // "#42c77a")}
        | tojson + ","' "${files[@]}" 2>/dev/null
}

i3status "$@" | {
    # The header and the opening bracket pass as they are.
    read -r line && printf '%s\n' "$line" || exit
    read -r line && printf '%s\n' "$line" || exit
    # Then a status line per second, each "[...]" or ",[...]": the dots go first in it.
    while read -r line; do
        marks="$(mark '*.pid' '#e8913a' '#905a24')$(mark '*.busy' '#5f87d7' '#4765a1')$(claude_marks)"
        printf '%s\n' "${line%%\[*}[$marks${line#*\[}" || exit
    done
}
