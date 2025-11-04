#!/bin/bash
# ================================================================
# Description: Website bookmark launcher using rofi or dmenu
# Author: Chris Lee, ChatGPT
# Dependencies: rofi or dmenu, xdg-open
# Usage:
#   ./web_bookmarks.sh -r   (for rofi)
#   ./web_bookmarks.sh -d   (for dmenu)
# Notes:
#   - Add websites to ~/.config/web_bookmarks/sites.txt
#   - Format: Website Name | https://example.com
# ================================================================

SITE_LIST="$HOME/.config/web_bookmarks/sites.txt"

# -----------------------------
# Detect current window manager
# -----------------------------
if pgrep -x qtile >/dev/null; then
    WM="qtile"
elif pgrep -x openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi

web_menu() {
    SELECTED_NAME=$(grep -v '^#' "$SITE_LIST" | awk -F'|' '{print $1}' | $launcher -p "Select a Website")
    SELECTED_NAME=$(echo "$SELECTED_NAME" | xargs)

    if [[ -n "$SELECTED_NAME" ]]; then
        URL=$(grep -i "^$SELECTED_NAME[[:space:]]*|" "$SITE_LIST" | awk -F'|' '{print $2}' | xargs)

        if [[ -n "$URL" ]]; then
            xdg-open "$URL" >/dev/null 2>&1 &
        else
            echo "No URL found for $SELECTED_NAME"
        fi
    fi
}

# -----------------------------
# Parse arguments
# -----------------------------
if [[ $# -eq 0 ]]; then
    echo "󰖟 Please See $(basename "$0") -h for help"
    exit 0
fi

while getopts "drh" main 2>/dev/null; do
    case "${main}" in
        d)
            package_list=(
                dmenu
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


            launcher="dmenu -nb '#1e1e2e' -nf '#cdd6f4' -sb '#89b4fa' -sf '#1e1e2e' -l 15 -i -p "Launch Application""
            web_menu
            ;;
        r)
            package_list=(
                rofi
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

            # 👇 use WM-aware rofi config
            launcher="rofi -config /home/$USER/.config/${WM:-openbox}/rofi/config.rasi -dmenu -i -p 'Bookmarks'"
            web_menu
            ;;
        h)
            echo "Website Bookmark Launcher"
            echo "Usage: $(basename "$0") [ARGUMENT]"
            echo ""
            printf "%-30s %s\n" " -r" "Use rofi menu (themed per WM)"
            printf "%-30s %s\n" " -d" "Use dmenu menu"
            ;;
        *)
            echo "Please see $0 -h for help"
            ;;
    esac
    exit 0
done
