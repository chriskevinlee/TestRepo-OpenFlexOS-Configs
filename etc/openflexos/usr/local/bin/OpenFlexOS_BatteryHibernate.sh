#!/bin/bash

# ================================================================
# Description: This script monitors the battery and notifies the user when it's low.
# It also warns audibly and hibernates the system when the battery is critically low.
# Author: Chris Lee, ChatGPT
# Dependencies: mpv, dunstify
# Notes: Sounds from https://pixabay.com
# - https://pixabay.com/sound-effects/machine-error-by-prettysleepy-art-12669/
# - https://pixabay.com/sound-effects/error-83494/
# ================================================================

package_list=(
    mpv
    dunst
)

for pkg in "${package_list[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
        echo "$pkg is NOT installed, installing..."
        dunstify -u normal "$pkg is NOT installed, installing..."
        zenity --info --text="$pkg is NOT installed, installing..."

        # Open a new Alacritty window to run the installation
        alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
    fi
done

### Warnning ###
# Set battery percent to give a warning of low battery, Comment (#) to disable warning
WARNING_PERCENT=31
# Keep the nofication open for a set time in milliseconds
WARNING_PERCENT_TIMEOUT=6000
# Set the number of seconds until the nofications shows again after dispearing
WARNING_PERCENT_NOTIFICATION=10


### Hibernate ###
# Set battery percent to give a warning of the system is about to hibernate, Comment (#) to disable warning
HIBERNATE_PERCENT=16
# Set Number of seconds that the "SOUND AND NOTIFICATIONS" will be displayed till the system hibernates
HIBERNATE_PERCENT_NOTIFICATION=10
# The number of seconds till the system hibernates. Default 120 seconds (2 minutes), when the nofication shows you will have 120 seconds till the syste hibernates
HIBERNATE_WAIT=120

HIBERNATE_PERCENT_NOTIFICATION_SOUND=/home/$USER/.config/$DESKTOP_SESSION/sounds/error-83494.mp3
HIBERNATE_PERCENT_TIMEOUT_SOUND=/home/$USER/.config/$DESKTOP_SESSION/sounds/machine-error-by-prettysleepy-art-12669.mp3


# Get battery directory
BATTERY_DIR=$(ls /sys/class/power_supply/ | grep BAT || echo "")
if [[ -z $BATTERY_DIR ]]; then
    echo "No battery detected. Exiting."
    exit 0
fi

while true; do
    STATUS=$(cat /sys/class/power_supply/$BATTERY_DIR/status)
    CAPACITY=$(cat /sys/class/power_supply/$BATTERY_DIR/capacity)

    # Detect wake-up from hibernation and force refresh
    inotifywait -e modify /sys/class/power_supply/$BATTERY_DIR/capacity &>/dev/null
    sleep 5  # Give system some time to update battery info

    # Refresh values after wake-up
    STATUS=$(cat /sys/class/power_supply/$BATTERY_DIR/status)
    CAPACITY=$(cat /sys/class/power_supply/$BATTERY_DIR/capacity)

    # Skip checks if charging
    if [[ $STATUS == "Charging" ]]; then
        sleep 60
        continue
    fi

    # Critical battery level - prepare to hibernate
    if [[ $CAPACITY -lt $HIBERNATE_PERCENT ]]; then
        for ((i = $HIBERNATE_WAIT; i > 0; i--)); do
            STATUS=$(cat /sys/class/power_supply/$BATTERY_DIR/status)
            if [[ $STATUS == "Charging" ]]; then
                break
            fi
            if (( i % HIBERNATE_PERCENT_NOTIFICATION == 0 )); then
                mpv $HIBERNATE_PERCENT_NOTIFICATION_SOUND &
                dunstify -u critical -r 55452 "Battery is at $CAPACITY%" \
                    "System about to Hibernate in $i seconds! Please Charge the Battery."
            fi
            sleep 1
        done

        # Hibernate if still low and not charging
        if [[ $STATUS != "Charging" ]]; then
            mpv $HIBERNATE_PERCENT_TIMEOUT_SOUND &
            dunstify -t $HIBERNATE_PERCENT_TIMEOUT -u critical -r 55452 "Battery is at $CAPACITY%" "System is Hibernating Now!"
            sleep 10
            systemctl hibernate
        fi
    elif [[ $CAPACITY -lt $WARNING_PERCENT ]]; then
         dunstify -r 55452 "Battery is at $CAPACITY%" "Please Charge the Battery"
         sleep $WARNING_PERCENT_NOTIFICATION
    fi

    sleep 1
done

