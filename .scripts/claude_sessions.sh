#!/bin/bash
# Collects the Claude Code sessions for the i3 bar: this laptop's, and those on each ssh host
# listed in ~/.config/claude-sessions/hosts (one per line, # for comments). That file stays out
# of this public repo, as do any settings in ~/.config/claude-sessions/env.
# For each, $XDG_RUNTIME_DIR/claude-sessions/<host>.json (local.json for this laptop) holds
# its sessions (see poll), a few seconds old at most; .scripts/i3status_stt.sh draws them.
# Each host needs jq. Run by the claude-sessions user service.
#
# A host gets one ssh connection that runs the poll loop there. Nothing is left behind: once
# the host sees the connection is gone, which can take it a minute or two, the loop's next
# write fails and it ends. When the connection drops, its sessions leave the bar and it's
# tried again a minute later, except while its ssh certificate has expired, since connecting
# then could start a browser login: that's left for you to do.

run="${XDG_RUNTIME_DIR:-/run/user/$UID}/claude-sessions"
hosts="$HOME/.config/claude-sessions/hosts"
# Prints the sessions as a line of JSON every 3 seconds, here or on a host. For each session
# claude agents lists: Claude Code's own file for it, which also says when its status last
# changed, and the title Claude gave it (its aiTitle, which is also its terminal's title), the
# last one in its log.
read -r -d '' poll <<'EOF'
PATH="$HOME/.local/bin:$PATH"
while :; do
    claude agents --json | jq -r '.[] | "\(.pid) \(.sessionId)"' | while read -r pid id; do
        cat ~/.claude/sessions/"$pid".json; echo
        tac ~/.claude/projects/*/"$id".jsonl 2>/dev/null | grep -m1 '"type":"ai-title"'
    done | jq -ncR '[inputs | fromjson?] | group_by(.sessionId) | map(add | select(.pid))' || exit
    sleep 3
done
EOF

refresh_bar() { pkill -USR1 -x i3status; }

# follow NAME COMMAND...: keep NAME.json up to date with the poll lines COMMAND prints
follow() {
    local name=$1 line; shift
    "$@" | while read -r line; do
        [ "$line" = "$(cat "$run/$name.json" 2>/dev/null)" ] && continue
        printf '%s\n' "$line" >"$run/.$name.json" && mv "$run/.$name.json" "$run/$name.json"
        refresh_bar
    done
    rm -f "$run/$name.json"
    refresh_bar
}

# cert_expired HOST: whether HOST's ssh certificate has under 5 minutes left, or can't be read.
# ssh -G runs the ssh config's Match exec commands; if one of them logs in, put what stops it
# in the env file.
cert_expired() {
    local cert expiry
    cert=$(ssh -G "$1" 2>/dev/null | awk '$1 == "certificatefile" { print $2; exit }')
    [ -n "$cert" ] || return 1  # it doesn't use one
    expiry=$(ssh-keygen -L -f "${cert/#\~/$HOME}" 2>/dev/null | sed -n 's/^ *Valid: from .* to //p')
    [ -z "$expiry" ] || (($(date -d "$expiry" +%s) < $(date +%s) + 300))
}

follow_host() {
    while :; do
        cert_expired "$1" ||
            follow "$1" ssh -n -o BatchMode=yes -o ConnectTimeout=10 -o ServerAliveInterval=15 "$1" "$poll"
        sleep 60
    done
}

mkdir -p "$run"
rm -f "$run"/*.json
trap 'trap - TERM INT; rm -f "$run"/*.json; refresh_bar; kill 0' TERM INT

follow local sh -c "$poll" &
while read -r host; do
    follow_host "$host" &
done < <(grep -vE '^\s*(#|$)' "$hosts" 2>/dev/null)
wait
