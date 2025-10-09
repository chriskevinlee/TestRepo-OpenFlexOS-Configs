#!/bin/bash

# ================================================================
# Description: Media/volume control script with notifications
# Author: Chris Lee, ChatGPT
# Dependencies: pipewire-pulse, dunstify
# Usage: ./OpenFlexOS_Volume.sh -u|-d|-m|-h
# ================================================================

volume_icon="󰕾"
volume_increase="+10%"
volume_decrease="-10%"
volume_mute="toggle"
notification_id=6534

# Get the name of the current default sink
get_default_sink() {
    pactl info | grep "Default Sink:" | awk '{print $3}'
}

# Get current volume of default sink
get_current_volume() {
    local sink
    sink=$(get_default_sink)
    pactl list sinks | awk -v sink="$sink" '
        $0 ~ "Name: " sink {found=1}
        found && /Volume:/ {
            for(i=1; i<=NF; i++) {
                if($i ~ /%/) {
                    print $i
                    exit
                }
            }
        }
    '
}

# Get mute status of default sink
get_mute_status() {
    local sink
    sink=$(get_default_sink)
    pactl list sinks | awk -v sink="$sink" '
        $0 ~ "Name: " sink {found=1}
        found && /Mute:/ {print $2; exit}
    '
}

# Print current state (helper)
print_status() {
    local current_volume mute_status
    current_volume=$(get_current_volume)
    mute_status=$(get_mute_status)

    if [ "$mute_status" = "yes" ]; then
        echo "$volume_icon Muted"
    else
        echo "$volume_icon $current_volume"
    fi
}

while getopts "udmh" opt 2>/dev/null; do
    case "${opt}" in
        u)
            pactl set-sink-volume @DEFAULT_SINK@ "$volume_increase"
            dunstify -r "$notification_id" "Volume Control" "$(get_current_volume)"
            print_status
            ;;
        d)
            pactl set-sink-volume @DEFAULT_SINK@ "$volume_decrease"
            dunstify -r "$notification_id" "Volume Control" "$(get_current_volume)"
            print_status
            ;;
        m)
            pactl set-sink-mute @DEFAULT_SINK@ "$volume_mute"
            if [ "$(get_mute_status)" = "yes" ]; then
                dunstify -r "$notification_id" "Volume Control" "Muted"
            else
                dunstify -r "$notification_id" "Volume Control" "Unmuted"
            fi
            print_status
            ;;
        h)
            echo "A script to manage volume up, down, and mute"
            echo "Usage: $(basename "$0") [OPTION]"
            echo ""
            printf "%-10s %s\n" "-u" "Volume up"
            printf "%-10s %s\n" "-d" "Volume down"
            printf "%-10s %s\n" "-m" "Toggle mute"
            printf "%-10s %s\n" "-h" "Show this help"
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            exit 1
            ;;
    esac
    exit 0
done

# No args → just print current status
print_status
