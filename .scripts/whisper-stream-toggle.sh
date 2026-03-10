#!/bin/bash
# Push-to-talk whisper transcription
# Usage: whisper-stream-toggle.sh start|stop
# Press $mod+t to record, release to transcribe and type

WHISPER_DIR="$HOME/whisper.cpp"
WHISPER_CLI="$WHISPER_DIR/build/bin/whisper-cli"
MODEL="$WHISPER_DIR/models/ggml-base.en.bin"
LIB_PATH="$WHISPER_DIR/build/src:$WHISPER_DIR/build/ggml/src:$WHISPER_DIR/build/ggml/src/ggml-cuda"

PIDFILE="/tmp/whisper-rec.pid"
WAVFILE="/tmp/whisper-rec.wav"

start() {
    # Skip if already recording
    if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
        return
    fi

    rm -f "$WAVFILE"

    # Record 16kHz mono WAV from default mic
    arecord -f S16_LE -r 16000 -c 1 -t wav "$WAVFILE" &
    echo $! > "$PIDFILE"

    notify-send -t 1000 "Whisper" "Recording..."
}

stop() {
    if [ -f "$PIDFILE" ]; then
        kill "$(cat "$PIDFILE")" 2>/dev/null
        rm -f "$PIDFILE"
        sleep 0.1
    fi

    if [ ! -f "$WAVFILE" ]; then
        notify-send -t 1000 "Whisper" "No recording found"
        return
    fi

    notify-send -t 1000 "Whisper" "Transcribing..."

    # Transcribe the recorded audio
    text=$(LD_LIBRARY_PATH="$LIB_PATH" "$WHISPER_CLI" \
        -m "$MODEL" \
        -f "$WAVFILE" \
        --no-timestamps \
        2>/dev/null \
        | sed 's/^[[:space:]]*//' \
        | grep -v '^\s*$' \
        | grep -v '\[BLANK_AUDIO\]' \
        | tr '\n' ' ' \
        | sed 's/[[:space:]]*$//')

    rm -f "$WAVFILE"

    if [ -n "$text" ]; then
        printf '%s' "$text" | xclip -selection clipboard
        xdotool type --delay 0 -- "$text"
        notify-send -t 2000 "Whisper" "$text"
    else
        notify-send -t 1000 "Whisper" "No speech detected"
    fi
}

case "$1" in
    start) start ;;
    stop)  stop  ;;
    *)     echo "Usage: $0 start|stop" ;;
esac
