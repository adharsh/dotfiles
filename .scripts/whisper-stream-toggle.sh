#!/bin/bash
# Push-to-talk whisper transcription with live floating terminal
# Usage: whisper-stream-toggle.sh start|stop
# Press $mod+t to start live transcription, release to stop and type result

WHISPER_DIR="$HOME/whisper.cpp"
WHISPER_STREAM="$WHISPER_DIR/build/bin/whisper-stream"
MODEL="$WHISPER_DIR/models/ggml-base.en.bin"
LIB_PATH="$WHISPER_DIR/build/src:$WHISPER_DIR/build/ggml/src:$WHISPER_DIR/build/ggml/src/ggml-cuda"

PIDFILE="/tmp/whisper-stream.pid"
OUTFILE="/tmp/whisper-stream.txt"
TERM_TITLE="whisper-live"

start() {
    # Skip if already running
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        return
    fi

    rm -f "$OUTFILE"
    : > "$OUTFILE"

    # Launch whisper-stream in a floating terminal
    # The terminal title is used by i3 to auto-float it
    # Run whisper-stream in background, writing text to file
    LD_LIBRARY_PATH="$LIB_PATH" "$WHISPER_STREAM" \
        -m "$MODEL" \
        -t 4 \
        --step 500 \
        --length 5000 \
        -f "$OUTFILE" \
        >/dev/null 2>&1 &
    WHISPER_PID=$!

    # Display latest transcription in a floating terminal
    xterm -T "$TERM_TITLE" -geometry 80x8 -bg black -fg white -fa 'Monospace' -fs 16 -e bash -c "
        tput civis
        prev=''
        while kill -0 $WHISPER_PID 2>/dev/null; do
            curr=\$(tail -1 '$OUTFILE' 2>/dev/null | grep -v '\[BLANK_AUDIO\]')
            if [ \"\$curr\" != \"\$prev\" ]; then
                printf '\033[H\033[2J%s' \"\$curr\"
                prev=\$curr
            fi
            sleep 0.1
        done
    " &

    echo $! > "$PIDFILE"
}

stop() {
    if [ -f "$PIDFILE" ]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        pkill -f "whisper-stream.*ggml-base" 2>/dev/null
        rm -f "$PIDFILE"
        sleep 0.3
    fi

    # Kill the floating terminal
    wmctrl -c "$TERM_TITLE" 2>/dev/null

    if [ -f "$OUTFILE" ]; then
        # Extract transcribed text: strip ANSI codes, blank lines, and [BLANK_AUDIO]
        text=$(sed 's/\x1b\[[0-9;]*m//g; s/\r//g' "$OUTFILE" \
            | grep -v '^\s*$' \
            | grep -v '\[BLANK_AUDIO\]' \
            | grep -v '\[Start speaking\]' \
            | sed 's/^[[:space:]]*//' \
            | tail -1 \
            | sed 's/[[:space:]]*$//')

        rm -f "$OUTFILE"

        if [ -n "$text" ]; then
            printf '%s' "$text" | xclip -selection clipboard
            xdotool type --delay 0 -- "$text"
            notify-send -t 2000 "Whisper" "$text"
        else
            notify-send -t 1000 "Whisper" "No speech detected"
        fi
    fi
}

case "$1" in
    start) start ;;
    stop)  stop  ;;
    *)     echo "Usage: $0 start|stop" ;;
esac
