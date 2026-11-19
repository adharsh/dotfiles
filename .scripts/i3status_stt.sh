#!/usr/bin/env bash
# i3status, with stt's dot at the left of it: orange while stt records (a dictation or a
# meeting), blue while it transcribes or analyzes a meeting, and nothing otherwise.
# Each is in full color for its first second, so you see it start, then dims, so it doesn't
# catch the eye on a shared screen. Being at the left, it never moves the rest of the bar.
# After the dot come the Claude Code sessions (see claude_marks); click one to stop its blinking,
# or right-click it to go to its window (see read_clicks).
# The i3 config's status_command runs this instead of i3status.
#
# stt writes $XDG_RUNTIME_DIR/stt/<kind>.pid while it records and <pid>.busy while it
# works, each holding the pid, and sends i3status SIGUSR1 when one comes or goes, so the
# dot follows at once. The dimming waits for i3status's next second.

run="${XDG_RUNTIME_DIR:-/run/user/$UID}/stt"
claude_run="${XDG_RUNTIME_DIR:-/run/user/$UID}/claude-sessions"
clicked="$claude_run/clicked"  # a file per session whose blinking a click stopped
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

blink=1 flipped=0  # so the first line shows it

# claude_marks: puts in $claude the Claude Code sessions that .scripts/claude_sessions.sh
# collects: a ✻ and the folder for each, after its host if it's not this laptop. Where that
# leaves two the same, each also gets its name, if you gave it one with /rename, or else the
# title Claude gave it, cut at a word to 20 characters, so the bar stays short. Green while
# Claude works, and coral when it's your turn, blinking until Claude works again or you've
# seen it: clicked it, or had its window focused. A session still waiting for its first prompt
# is your turn too, but steady, since you just started it. Grey if it can't tell: a Claude Code
# before 2.1.327 may set a session's status when it starts and never again, so a status that
# hasn't changed since then means nothing.
claude_marks() {
    local files=("$claude_run"/*.json) now=$((${EPOCHREALTIME/[.,]/} / 1000)) state id seen text
    local -A color=([working]='#3fa66b' [turn]='#ff7a59' [off]='#000000' [unknown]='#6b6b6b')
    claude=
    [ -f "${files[0]}" ] || return 0
    # The blink flips about once a second: at most once per i3status line
    ((now - flipped >= 700)) && ((blink = !blink, flipped = now))
    # Claude Code titles its terminal with a mark, a space, and the session's name if you gave
    # it one with /rename, or else the title Claude gave it
    local focused=$(xdotool getactivewindow getwindowname 2>/dev/null)
    # A line per session: its state, its id, whether its window is focused, and its text as a
    # JSON string. Each file is a line of JSON; one that isn't is skipped, as is a session whose
    # id isn't a plain one, since a host sends it and the id becomes a file name in $clicked.
    while read -r state id seen text; do
        if [ "$state" = working ]; then
            [ -e "$clicked/$id" ] && rm -f "$clicked/$id"  # so its next turn blinks again
        elif [ "$state" = turn ]; then
            [ "$seen" = yes ] && [ ! -e "$clicked/$id" ] && touch "$clicked/$id"  # like a click
            ((blink)) && [ ! -e "$clicked/$id" ] && state=off
        fi
        claude+="{\"name\":\"claude\",\"instance\":\"$id\",\"full_text\":$text,\"color\":\"${color[$state]}\"},"
    done < <(jq -nrR --arg focused "${focused#* }" '
        [inputs | (fromjson? // [])[]? | objects | select(.sessionId | strings | test("^[0-9a-f-]{1,64}$"))
            + {host: input_filename | split("/") | last | rtrimstr(".json")}
            | .label = "✻ \(if .host == "local" then "" else "\(.host):" end)\(.cwd // "?" | split("/") | last)"]
        | (group_by(.label) | map(select(length > 1)[].sessionId)) as $shared
        | sort_by(.host != "local")[]
        | .sessionId as $id
        | (if .nameSource == "user" then .name else .aiTitle end) as $window_title
        | ((.statusUpdatedAt // 0) - .startedAt < 10000) as $unchanged
        | ((.version // "0") | split(".") | map(tonumber? // 0)) as $version
        | (if any($shared[]; . == $id) then
               $window_title // ""
               | if length <= 20 then . elif .[20:21] == " " then .[:20] + "…"
                 else .[:20] | sub(" [^ ]*$"; "") + "…" end
           else "" end) as $title
        | if .status == "busy" then "working"
          elif $unchanged and $version < [2, 1, 327] then "unknown"
          else "turn" end
          + " " + .sessionId
          + " " + (if $unchanged or ($window_title and $window_title == $focused) then "yes" else "no" end)
          + " " + (.label + if $title == "" then "" else " · \($title)" end | tojson)
    ' "${files[@]}" 2>/dev/null)
}

# i3bar sends a line of JSON on stdin for each click, since the header asks for them. A click
# on a Claude session stops its blinking, at once, and leaves you where you are, except a right
# click, which also takes you to its window (see focus_session).
read_clicks() {
    local line id
    while read -r line; do
        [[ $line == *'"name":"claude"'* && $line =~ \"instance\":\"([0-9a-f-]+)\" ]] || continue
        id=${BASH_REMATCH[1]}
        touch "$clicked/$id"
        pkill -USR1 -x i3status
        [[ $line =~ \"button\":3[,}] ]] && focus_session "$id"
    done
}

# focus_session ID: focuses the window showing session ID, if there is one on this laptop: the
# one titled with a mark and the session's title, the way Claude Code titles its terminal (its
# name if you gave it one with /rename, or else the title Claude gave it). That's a terminal
# here, or one ssh'd into the session's host. Nothing reads stdin here, which is i3bar's clicks.
focus_session() {
    local title con
    title=$(jq -r --arg id "$1" '.[]? | select(.sessionId == $id)
        | if .nameSource == "user" then .name else .aiTitle end // empty
    ' "$claude_run"/*.json </dev/null 2>/dev/null | head -n1)
    [ -n "$title" ] || return 0  # no title yet: its window can't be told apart
    con=$(i3-msg -t get_tree </dev/null | jq --arg title "$title" '
        first(.. | objects | select(.window and (.name // "" | sub("^[^ ]* "; "")) == $title) | .id) // empty')
    [ -n "$con" ] && i3-msg -q "[con_id=$con] focus" </dev/null
}
mkdir -p "$clicked"
read_clicks <&0 &

i3status "$@" </dev/null | {
    # The header, asking for clicks, and the opening bracket
    read -r line && printf '%s\n' "${line%\}},\"click_events\":true}" || exit
    read -r line && printf '%s\n' "$line" || exit
    # Then a status line per second, each "[...]" or ",[...]": the dots go first in it.
    while read -r line; do
        claude_marks  # not in $( ), which would forget the blink
        marks="$(mark '*.pid' '#e8913a' '#905a24')$(mark '*.busy' '#5f87d7' '#4765a1')$claude"
        printf '%s\n' "${line%%\[*}[$marks${line#*\[}" || exit
    done
}
