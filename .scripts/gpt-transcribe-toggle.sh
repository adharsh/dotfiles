#!/bin/bash
# Push-to-talk transcription with OpenAI's gpt-transcribe model.
# Hold $mod+t to record, release it to transcribe, or close the window to cancel.

MODEL="gpt-transcribe"
API_URL="https://api.openai.com/v1/audio/transcriptions"
TERM_TITLE="gpt-transcribe"

STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/gpt-transcribe-${UID}"
SESSION_PIDFILE="$STATE_DIR/session.pid"
STOP_FILE="$STATE_DIR/stop"
STATUS_FILE="$STATE_DIR/status"
AUDIO_FILE="$STATE_DIR/recording.wav"
RESPONSE_FILE="$STATE_DIR/response.json"

RECORDER_PID=""
REQUEST_PID=""

mkdir -p "$STATE_DIR"
chmod 700 "$STATE_DIR"

notify_error() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u critical -t 4000 "GPT Transcribe" "$1"
    fi
}

reset_state() {
    rm -f "$SESSION_PIDFILE" "$STOP_FILE" "$STATUS_FILE" "$AUDIO_FILE" "$RESPONSE_FILE"
}

read_pid() {
    local pidfile="$1"
    local pid

    [ -r "$pidfile" ] || return 1
    read -r pid < "$pidfile"
    case "$pid" in
        ''|*[!0-9]*) return 1 ;;
    esac
    printf '%s\n' "$pid"
}

require_commands() {
    local command_name

    for command_name in "$@"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            notify_error "Required command not found: $command_name"
            return 1
        fi
    done
}

load_api_key() {
    if [ -z "${OPENAI_API_KEY:-}" ] && [ -f "$HOME/.api_keys" ]; then
        # shellcheck source=/dev/null
        source "$HOME/.api_keys"
    fi

    if [ -z "${OPENAI_API_KEY:-}" ]; then
        notify_error "OPENAI_API_KEY is not set in the environment or ~/.api_keys."
        return 1
    fi
}

stop_process() {
    local pid="$1"
    local attempts=0

    case "$pid" in
        ''|*[!0-9]*) return ;;
    esac
    kill -0 "$pid" 2>/dev/null || return

    kill "$pid" 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null && [ "$attempts" -lt 20 ]; do
        sleep 0.05
        attempts=$((attempts + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill -KILL "$pid" 2>/dev/null || true
    fi
    wait "$pid" 2>/dev/null || true
}

cleanup_session() {
    trap - EXIT HUP INT TERM
    stop_process "$REQUEST_PID"
    stop_process "$RECORDER_PID"
    reset_state
}

set_status() {
    printf '%s\n' "$1" > "$STATUS_FILE"
}

start() {
    local session_pid
    local target_window

    if session_pid=$(read_pid "$SESSION_PIDFILE") && kill -0 "$session_pid" 2>/dev/null; then
        return
    fi

    reset_state
    require_commands xdotool xterm || return 1

    target_window=$(xdotool getwindowfocus 2>/dev/null)
    case "$target_window" in
        ''|*[!0-9]*)
            notify_error "Could not determine where to type the transcript."
            return 1
            ;;
    esac

    "$0" session "$target_window" &
    printf '%s\n' "$!" > "$SESSION_PIDFILE"
}

run_ui() {
    local session_pid="$1"
    local status=""
    local previous=""

    case "$session_pid" in
        ''|*[!0-9]*) return 1 ;;
    esac

    trap 'exit 0' HUP INT TERM
    trap 'kill -HUP "$session_pid" 2>/dev/null || true' EXIT

    printf '\033[?25l'
    while kill -0 "$session_pid" 2>/dev/null; do
        if [ -r "$STATUS_FILE" ]; then
            IFS= read -r status < "$STATUS_FILE" || status=""
            if [ "$status" != "$previous" ]; then
                printf '\033[2J\033[H%s\n\n%s\n' "$status" "Close this window to cancel."
                previous="$status"
            fi
        fi
        sleep 0.05
    done

    trap - EXIT HUP INT TERM
}

run_session() {
    local target_window="$1"
    local window_pid
    local request_status
    local error_message
    local text

    printf '%s\n' "$$" > "$SESSION_PIDFILE"
    trap cleanup_session EXIT
    trap 'exit 0' HUP INT TERM

    require_commands ffmpeg curl jq xdotool xterm || return 1
    load_api_key || return 1

    ffmpeg \
        -nostdin \
        -hide_banner \
        -loglevel error \
        -f pulse \
        -fragment_size 1024 \
        -sample_rate 16000 \
        -channels 1 \
        -i default \
        -c:a pcm_s16le \
        -y "$AUDIO_FILE" \
        >/dev/null 2>&1 &
    RECORDER_PID=$!

    sleep 0.05
    if ! kill -0 "$RECORDER_PID" 2>/dev/null; then
        notify_error "Could not start microphone recording."
        return 1
    fi

    set_status "Listening..."
    xterm \
        -T "$TERM_TITLE" \
        -geometry 48x5 \
        -bg black \
        -fg white \
        -fa Monospace \
        -fs 16 \
        -e "$0" ui "$$" &
    window_pid=$!

    sleep 0.05
    if ! kill -0 "$window_pid" 2>/dev/null; then
        notify_error "Could not open the transcription status window."
        return 1
    fi

    while [ ! -f "$STOP_FILE" ]; do
        if ! kill -0 "$RECORDER_PID" 2>/dev/null; then
            notify_error "Microphone recording stopped unexpectedly."
            return 1
        fi
        sleep 0.05
    done

    set_status "Transcribing..."
    kill -INT "$RECORDER_PID" 2>/dev/null || true
    wait "$RECORDER_PID" 2>/dev/null || true
    RECORDER_PID=""

    if [ ! -s "$AUDIO_FILE" ] || [ "$(wc -c < "$AUDIO_FILE")" -le 1000 ]; then
        notify_error "No audio was recorded."
        return 1
    fi

    curl --silent --show-error --fail-with-body \
        --connect-timeout 10 \
        --max-time 120 \
        --request POST \
        --url "$API_URL" \
        --header "Authorization: Bearer $OPENAI_API_KEY" \
        --form "file=@$AUDIO_FILE;type=audio/wav" \
        --form "model=$MODEL" \
        --output "$RESPONSE_FILE" &
    REQUEST_PID=$!

    if wait "$REQUEST_PID"; then
        request_status=0
    else
        request_status=$?
    fi
    REQUEST_PID=""

    if [ "$request_status" -ne 0 ]; then
        error_message=$(jq -r '.error.message // empty' "$RESPONSE_FILE" 2>/dev/null)
        notify_error "${error_message:-Transcription request failed.}"
        return 1
    fi

    text=$(jq -r '.text // empty' "$RESPONSE_FILE" 2>/dev/null \
        | tr '\r\n' '  ' \
        | sed 's/[[:space:]]\+/ /g; s/^[[:space:]]*//; s/[[:space:]]*$//')

    if [ -z "$text" ]; then
        notify_error "The transcription response did not contain text."
        return 1
    fi

    if ! xdotool windowactivate --sync "$target_window" 2>/dev/null \
        || ! xdotool type --delay 0 -- "$text"; then
        notify_error "Could not type the transcript into the original window."
        return 1
    fi
}

stop() {
    touch "$STOP_FILE"
}

case "${1:-}" in
    start) start ;;
    stop) stop ;;
    session) run_session "${2:-}" ;;
    ui) run_ui "${2:-}" ;;
    *)
        echo "Usage: $0 start|stop"
        exit 2
        ;;
esac
