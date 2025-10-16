#!/bin/bash

STATE_FILE="$HOME/.config/nerd-dictation-state"

# Read the last state
if [[ -f "$STATE_FILE" ]]; then
    LAST_STATE=$(cat "$STATE_FILE")
else
    LAST_STATE="Left-Click: Dictate"
fi

# Parse options
while getopts "sSh" main 2>/dev/null;  do
    case "$main" in
        s)
            nd begin --vosk-model-dir /opt/nerd-dictation/model &
            echo "Right-Click: Stop" > "$STATE_FILE"
            exit 0
            ;;
        S)
            nd end &
            echo "Left-Click: Dictate" > "$STATE_FILE"
            exit 0
            ;;
        h)
            echo "Usage: $(basename "$0") [OPTION]"
            echo ""
            echo "  -s        Start dictation"
            echo "  -S        Stop dictation"
            exit 0
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            exit 1
            ;;
    esac
done

# If no options were passed, show the current state
if [ $OPTIND -eq 1 ]; then
    echo "$LAST_STATE"
fi
