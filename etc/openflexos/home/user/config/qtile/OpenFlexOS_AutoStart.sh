#!/bin/bash

# ================================================================
# Description: This is a startup script for qtile window manager
# Author: Chris Lee
# Dependencies:
# Usage:
# Notes:
# ================================================================

### For singal wallpaper
# Create a config file if it dont exists, saves the wallpaper the user selected and applies the wallpaper at login
CONFIG_FILE="/home/$USER/.config/$DESKTOP_SESSION/.selected_wallpaper"

# Check if the configuration file exists and is not empty
if [ -s "$CONFIG_FILE" ]; then
  # Read the saved wallpaper path
  SELECTED_WALLPAPER=$(cat "$CONFIG_FILE")
  # Apply the wallpaper using feh
  feh --bg-scale "$SELECTED_WALLPAPER" &
fi


## For multi wallpaper
# Define the wallpaper configuration file
CONFIG_FILE="$HOME/.config/qtile/.multi_selected_wallpaper"
# Check if the configuration file exists and is not empty
if [[ -s "$CONFIG_FILE" ]]; then
    # Create an array to store wallpaper arguments
    wallpaper_args=()

    # Read each line of the file
    while IFS='=' read -r monitor wallpaper; do
        # Ensure the line is not empty and the wallpaper file exists
        if [[ -n "$monitor" && -n "$wallpaper" && -f "$wallpaper" ]]; then
            # Store the wallpaper arguments for feh
            wallpaper_args+=("--bg-scale" "$wallpaper")
        fi
    done < "$CONFIG_FILE"

    # Apply all wallpapers at once using feh
    if [[ ${#wallpaper_args[@]} -gt 0 ]]; then
        feh --no-fehbg "${wallpaper_args[@]}" &
    fi
else
    echo "Wallpaper config file is missing or empty."
fi







# Loads the login sound and plays a login sound at login
source /home/$USER/.config/qtile/scripts/OpenFlexOS_Sounds.sh
if [[ ! -z "$login_sound" ]]; then
    mpv --no-video "${sounds_dir}${login_sound}" &
fi


# Loads a authentication agent to allow applications that need sudo/authentication
if command -v /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1; then
        /usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 &
elif command -v /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 >/dev/null 2>&1; then
        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
fi


# Start Applicatiosn at login
flameshot &
xscreensaver -no-splash &
picom &
tilda &

# Start Scripts at Login
/home/$USER/.config/qtile/scripts/OpenFlexOS_BatteryHibernate.sh &
