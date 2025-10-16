#!/bin/bash

# ================================================================
# Description: SSH menu using rofi or dmenu for quick connections
# Author: Chris Lee, ChatGPT
# Dependencies: rofi, dmenu, openssh, alacritty
# Usage: ./ssh.sh [-r | -d | -h]
# Notes: Add SSH servers to ~/.ssh/servers.txt in the format:
#        Server Name | ssh user@ip_address
# ================================================================

ssh_icon="󰣀"
echo $ssh_icon

# Detect window manager (Qtile/Openbox/Other)
if pgrep -x qtile >/dev/null; then
    WM="qtile"
elif pgrep -x openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi

# Function to call rofi directly
rofi_cmd() {
    if [[ -z "$1" ]]; then prompt="Select SSH Server"; else prompt="$1"; fi

    if [[ "$WM" == "qtile" ]]; then
        rofi -config "$HOME/.config/qtile/rofi/config.rasi" -dmenu -p "$prompt"
    elif [[ "$WM" == "openbox" ]]; then
        rofi -config "$HOME/.config/openbox/rofi/config.rasi" -dmenu -p "$prompt"
    else
        rofi -dmenu -p "$prompt"
    fi
}

# SSH menu function: accepts a launcher as an argument
ssh_menu() {
    local launcher_func="$1"
    local SSH_DIR="$HOME/.ssh"
    local SERVER_LIST="$SSH_DIR/servers.txt"

    # Create SSH directory and server list file if missing
    [[ ! -d "$SSH_DIR" ]] && mkdir -p "$SSH_DIR"
    [[ ! -f "$SERVER_LIST" ]] && echo "# Server Name | SSH Command" > "$SERVER_LIST"

    # Display server names using the selected launcher
    SELECTED_NAME=$(grep -v '^#' "$SERVER_LIST" | awk -F'|' '{print $1}' | $launcher_func "Select SSH Server")
    SELECTED_NAME=$(echo "$SELECTED_NAME" | xargs)  # Trim whitespace

    if [[ -n "$SELECTED_NAME" ]]; then
        CONNECTION_STRING=$(grep -i "^$SELECTED_NAME[[:space:]]*|" "$SERVER_LIST" | awk -F'|' '{print $2}' | xargs)
        if [[ -n "$CONNECTION_STRING" ]]; then
            alacritty -e bash -c "$CONNECTION_STRING; echo 'Press any key to exit'; read -n 1"
        else
            echo "No connection string found for $SELECTED_NAME"
        fi
    fi
}

# Parse command-line arguments
while getopts "drh" opt 2>/dev/null; do
    case "$opt" in
        d)
            package_list=(
                openflexos-dmenu
                openssh
                alacritty
            )

            for pkg in "${package_list[@]}"; do
                if ! pacman -Q "$pkg" >/dev/null 2>&1; then
                    echo "Message from $0: $pkg is NOT installed, installing..."
                    dunstify -u normal "Message from $0: $pkg is NOT installed, installing..."
                    zenity --info --text="Message from $0: $pkg is NOT installed, installing..."

                    # Open a new Alacritty window to run the installation
                    alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
                fi
            done
            # Use dmenu as the launcher
            dmenu_launcher="dmenu -l 10 -y 20 -x 20 -z 1880 -i -p"
            ssh_menu "$dmenu_launcher"
            ;;
        r)
            package_list=(
                rofi
                openssh
                alacritty
            )

            for pkg in "${package_list[@]}"; do
                if ! pacman -Q "$pkg" >/dev/null 2>&1; then
                    echo "Message from $0: $pkg is NOT installed, installing..."
                    dunstify -u normal "Message from $0: $pkg is NOT installed, installing..."
                    zenity --info --text="Message from $0: $pkg is NOT installed, installing..."

                    # Open a new Alacritty window to run the installation
                    alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
                fi
            done
            # Use rofi as the launcher
            ssh_menu rofi_cmd
            ;;
        h)
            echo "SSH Menu Script"
            echo "Usage: $(basename "$0") [-r | -d | -h]"
            echo ""
            printf "%-30s %s\n" " -r" "Use Rofi to select SSH server"
            printf "%-30s %s\n" " -d" "Use Dmenu to select SSH server"
            printf "%-30s %s\n" " -h" "Show this help message"
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            ;;
    esac
    exit 0
done