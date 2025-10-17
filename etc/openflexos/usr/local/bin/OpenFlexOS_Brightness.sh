#!/bin/bash

# ================================================================
# Description: This Script uses brightnessctl and dunst to control screen brightness and send a notifcation on compatible devices
# Author: Chris Lee, ChatGPT
# Dependencies: brightnessctl, dunst
# Usage: add to a startup script (Recommended) or ./Battery_Hibernate.sh from terminal (Not Recommended)
# Notes:
# ================================================================

package_list=(
    brightnessctl
    dunst
    ttf-nerd-fonts-symbols
)

for pkg in "${package_list[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        script_name=$(basename "$0")
        echo "Message from $script_name: $pkg is NOT installed, installing..."
        dunstify -u normal "Message from $script_name: $pkg is NOT installed, installing..."
        zenity --info --text="Message from $script_name: $pkg is NOT installed, installing..."

        alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
    fi
done


brightness_icon="󰃝"


# Check if there is any backlight directory
if [ -d /sys/class/backlight ] && [ "$(ls -A /sys/class/backlight)" ]; then
    # Get the first available backlight directory
    BACKLIGHT_DIR=$(ls /sys/class/backlight | head -n 1)

    # Define step percentage
    STEP=10%

    # Handle options
    while getopts "udh" main 2>/dev/null; do
        case "${main}" in
            u)
                brightnessctl set $STEP+
                ;;
            d)
                brightnessctl set $STEP-
                ;;
            h)
                echo "Script to adjust screen brightness on compatible devices with a backlight"
                echo "Usage: $(basename "$0") [ARGUMENT]"
                echo ""
                printf "%-30s %s\n" " -u" "Turn screen brightness up"
                printf "%-30s %s\n" " -d" "Turn screen brightness down"
                exit 0
                ;;
            *)
                echo "Please see $(basename "$0") -h for help"
                exit 1
                ;;
        esac

        # Show updated brightness after up/down
        current_brightness=$(brightnessctl get)
        max_brightness=$(brightnessctl max)
        percentage=$(( 100 * current_brightness / max_brightness ))
        dunstify -r "48457" "Brightness Control" "$percentage"
        exit 0
    done

    # If no options were passed, show current brightness
    if [ $OPTIND -eq 1 ]; then
        current_brightness=$(brightnessctl get)
        max_brightness=$(brightnessctl max)
        percentage=$(( 100 * current_brightness / max_brightness ))
        echo "$brightness_icon" "$percentage%"
        exit 0
    fi
fi
