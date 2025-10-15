#!/bin/bash

# ================================================================
# Description: Wallpaper manager with static, random, cycling, slideshow, and multi-monitor support
# Author: Chris Lee, ChatGPT
# Dependencies: sxiv, zenity, wmctrl, feh, dunst
# ================================================================

package_list=(
sxiv
zenity
wmctrl
feh
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

# ---------------- Directories ----------------
SYSTEM_WALLPAPERS="/etc/openflexos/home/user/config/wallpapers"
USER_WALLPAPERS="$HOME/.config/wallpapers"

# Users can disable system wallpapers by creating ~/.config/wallpapers.nosystem
if [[ -f "$HOME/.config/wallpapers.nosystem" ]]; then
    WALLPAPER_DIRS=("$USER_WALLPAPERS")
else
    WALLPAPER_DIRS=("$SYSTEM_WALLPAPERS" "$USER_WALLPAPERS")
fi

# Temporary PID file for cycling wallpapers
PID_FILE="/tmp/wallpaper_timer.pid"

# ---------------- Multi-Monitor ----------------
Mutli_Monitor_Wallpapers() {
    wallpaper_file="$HOME/.config/$DESKTOP_SESSION/.multi_selected_wallpaper"
    monitors=($(xrandr --listmonitors | awk 'NR>1 {print $4}'))
    declare -A wallpapers

    if [[ -f "$wallpaper_file" ]]; then
        while IFS='=' read -r monitor wallpaper; do
            wallpapers["$monitor"]="$wallpaper"
        done < <(grep -v '^#' "$wallpaper_file")
    fi

    monitor_list=$(printf "%s\n" "${monitors[@]}")
    selected_monitor=$(zenity --width=500 --height=400 --list --title="Select Monitor" --column="Monitors" $monitor_list)
    [[ -z "$selected_monitor" ]] && exit 1

    new_wallpaper=$(zenity --file-selection --title="Select a wallpaper for $selected_monitor" --filename="$USER_WALLPAPERS/")
    [[ -z "$new_wallpaper" ]] && exit 1
    wallpapers["$selected_monitor"]="$new_wallpaper"

    primary_monitor="${monitors[0]}"
    secondary_monitor="${monitors[1]}"

    {
        [[ -n "${wallpapers[$primary_monitor]}" ]] && echo "$primary_monitor=$(realpath "${wallpapers[$primary_monitor]}")"
        [[ -n "${wallpapers[$secondary_monitor]}" ]] && echo "$secondary_monitor=$(realpath "${wallpapers[$secondary_monitor]}")"
        for monitor in "${!wallpapers[@]}"; do
            [[ "$monitor" != "$primary_monitor" && "$monitor" != "$secondary_monitor" ]] && echo "$monitor=$(realpath "${wallpapers[$monitor]}")"
        done
    } > "$wallpaper_file"

    feh --no-fehbg \
        --bg-scale "$(realpath "${wallpapers[$primary_monitor]}")" \
        --bg-scale "$(realpath "${wallpapers[$secondary_monitor]}")"

    [[ -f $HOME/.config/$DESKTOP_SESSION/.selected_wallpaper ]] && rm $HOME/.config/$DESKTOP_SESSION/.selected_wallpaper
}

# ---------------- Static ----------------
Select_Wallpaper() {
    sxiv -t -r "${WALLPAPER_DIRS[@]}" &
    sleep 1
    window_id=$(wmctrl -l | grep "sxiv" | awk '{print $1}')
    if [ -z "$window_id" ]; then
        zenity --error --text="sxiv window not found!"
        exit 1
    fi
    wmctrl -i -r "$window_id" -T "Select a Wallpaper...(ctrl+x+w)"
    [[ -f $HOME/.config/$DESKTOP_SESSION/.multi_selected_wallpaper ]] && rm $HOME/.config/$DESKTOP_SESSION/.multi_selected_wallpaper
}

# ---------------- Random ----------------
Select_Random_Wallpaper() {
    WALLPAPER=$(find "${WALLPAPER_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
    WALLPAPER=$(realpath "$WALLPAPER")
    feh --bg-fill "$WALLPAPER" && echo "$WALLPAPER" > "$HOME/.config/$DESKTOP_SESSION/.selected_wallpaper"
    dunstify -u normal "Wallpaper Applied"
    [[ -f $HOME/.config/$DESKTOP_SESSION/.multi_selected_wallpaper ]] && rm $HOME/.config/$DESKTOP_SESSION/.multi_selected_wallpaper
}

# ---------------- Start Cycle ----------------
Start_Wallpaper_Cycle() {
    local INTERVAL_INPUT="$1"
    if [[ "$INTERVAL_INPUT" =~ ^([0-9]+)([smSM])$ ]]; then
        VALUE="${BASH_REMATCH[1]}"
        UNIT="${BASH_REMATCH[2]}"
        [[ "$UNIT" =~ [mM] ]] && INTERVAL=$((VALUE * 60)) || INTERVAL=$VALUE
    else
        zenity --error --text="Invalid interval format. Use a number followed by 's' or 'm'."
        exit 1
    fi

    (
        while true; do
            WALLPAPER=$(find "${WALLPAPER_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)
            WALLPAPER=$(realpath "$WALLPAPER")
            feh --bg-fill "$WALLPAPER"
            sleep "$INTERVAL"
        done
    ) > /dev/null 2>&1 &

    echo $! > "$PID_FILE"
    echo "Wallpaper timer started with a $INTERVAL_INPUT interval!"
}

# ---------------- Stop Cycle ----------------
Stop_Wallpaper_Cycle() {
    if [[ -f "$PID_FILE" ]]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm "$PID_FILE"
        echo "Wallpaper timer stopped!"
    else
        echo "No wallpaper timer is running."
    fi
}

# ---------------- Slideshow ----------------
Slide_Show() {
    local INTERVAL_INPUT="$1"
    if [[ "$INTERVAL_INPUT" =~ ^([0-9]+)([smSM])$ ]]; then
        VALUE="${BASH_REMATCH[1]}"
        UNIT="${BASH_REMATCH[2]}"
        [[ "$UNIT" =~ [mM] ]] && INTERVAL=$((VALUE * 60)) || INTERVAL=$VALUE
    else
        zenity --error --text="Invalid interval format. Use a number followed by 's' or 'm'."
        exit 1
    fi

    IMAGE_FILES=$(find "${WALLPAPER_DIRS[@]}" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" -o -iname "*.bmp" \) -exec realpath {} \;)
    [[ -z "$IMAGE_FILES" ]] && { echo "No images found."; exit 1; }

    feh -F -D "$INTERVAL" $IMAGE_FILES
}

# ---------------- Helper: Ask for Interval ----------------
Ask_For_Interval() {
    local TITLE="$1"
    local INTERVAL
    INTERVAL=$(zenity --list --title="Set $TITLE Interval" --column="Options" \
        "5s" "10s" "20s" "30s" "1m" "5m" "10m" "20m" "30m" "60m" "Custom" \
        --text="Choose a time interval:")
    [[ "$INTERVAL" == "Custom" ]] && INTERVAL=$(zenity --entry --title="Custom Interval" --text="Enter time (e.g., 30s, 10m):")
    echo "$INTERVAL"
}

# ---------------- Timer Menu ----------------
MENU_OPTION=$( [[ -f "$PID_FILE" && $(pgrep -F "$PID_FILE") ]] && echo "Stop Wallpaper Cycle" || echo "Start Wallpaper Cycle" )

# ---------------- Commandline Options ----------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s) Select_Wallpaper; exit 0 ;;
        -r) Select_Random_Wallpaper; exit 0 ;;
        -b)
            if [[ $# -gt 1 && "$2" =~ ^[0-9]+[smSM]$ ]]; then
                INTERVAL="$2"
                shift
            else
                INTERVAL=$(Ask_For_Interval "Wallpaper Cycle")
            fi
            Start_Wallpaper_Cycle "$INTERVAL"
            dunstify -u normal "Wallpaper Applied every: $INTERVAL"
            exit 0
            ;;
        -e) Stop_Wallpaper_Cycle; dunstify -u normal "Wallpaper Stopped"; exit 0 ;;
        -l)
            if [[ $# -gt 1 && "$2" =~ ^[0-9]+[smSM]$ ]]; then
                INTERVAL="$2"
                shift
            else
                INTERVAL=$(Ask_For_Interval "Slideshow")
            fi
            Slide_Show "$INTERVAL"
            exit 0
            ;;
        -h)
            echo "A Wallpaper Changer with a few features, such as static wallpaper, random wallpaper, cycling wallpapers, and a slideshow."
            echo "Usage: $(basename "$0") [OPTION] [ARGUMENT]"
            echo ""

            printf "%-30s %s\n" " $(basename "$0")" "Run Zenity GUI to select the the options below"
            printf "%-30s %s\n" " -s" "Select a static wallpaper with sxiv"
            printf "%-30s %s\n" " -r" "Apply a random wallpaper using feh"
            printf "%-30s %s\n" " -b" "Start cycling wallpapers with a given interval using feh"
            printf "%-30s %s\n" " -e" "Stop cycling wallpapers using feh"
            printf "%-30s %s\n" " -l" "Start a slideshow with a given interval using feh"
            echo ""
            echo " EXAMPLES:"
            echo ""
            printf "%-30s %s\n" " $(basename "$0") -b 10s" "Start a wallpaper cycle every 10 seconds"
            printf "%-30s %s\n" " $(basename "$0") -b 5m" "Start a wallpaper cycle every 5 Minutes"
            printf "%-30s %s\n" " $(basename "$0") -e" "Stop the wallpaper cycle"
            echo ""
            printf "%-30s %s\n" " $(basename "$0") -l 10s" "Start a full screen slideshow every 10 seconds"
            printf "%-30s %s\n" " $(basename "$0") -l 5m" "Start a full screen slideshow every 5 Minutes"
            exit 0
            ;;
        *)
            echo "Invalid Option, Please use $(basename "$0") -h for help"
            exit 1
            ;;
    esac
    shift
done

# ---------------- GUI Menu ----------------
CHOICE=$(zenity  --width=500 --height=400 --list --title="Wallpaper Manager" --column="Options" \
    "Select Wallpaper" "Select Random Wallpaper" "$MENU_OPTION" "SlideShow" "Mutli-Monitor Wallpapers")
case "$CHOICE" in
    "Select Wallpaper") Select_Wallpaper ;;
    "Select Random Wallpaper") Select_Random_Wallpaper; dunstify -u normal "Wallpaper Applied" ;;
    "Start Wallpaper Cycle")
        INTERVAL=$(Ask_For_Interval "Wallpaper Cycle")
        Start_Wallpaper_Cycle "$INTERVAL"; dunstify -u normal "Wallpaper Cycle Started"
        ;;
    "Stop Wallpaper Cycle") Stop_Wallpaper_Cycle; dunstify -u normal "Wallpaper Cycle Stopped" ;;
    "SlideShow")
        INTERVAL=$(Ask_For_Interval "Slideshow")
        Slide_Show "$INTERVAL"
        ;;
    "Mutli-Monitor Wallpapers") Mutli_Monitor_Wallpapers ;;
    *) echo "No selection made." ;;
esac
