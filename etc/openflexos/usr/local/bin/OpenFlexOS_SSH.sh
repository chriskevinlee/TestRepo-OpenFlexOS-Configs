#!/bin/bash
# ================================================================
# Description: SSH menu using rofi or dmenu for quick connections
# Author: Chris Lee, ChatGPT
# Dependencies: rofi, dmenu, openssh, alacritty
# Usage: ./ssh.sh [-r | -d | -h]
# Notes: Add SSH servers to ~/.ssh/servers.txt in the format:
#        Server Name | ssh user@ip_address
# ================================================================
source "$HOME/.config/dmenu_theme.conf"

ssh_icon="󰣀"
echo "$ssh_icon"

# Detect window manager (Qtile/Openbox/Other)
if pgrep -x qtile >/dev/null; then
    WM="qtile"
elif pgrep -x openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi

# -----------------------------------------------------------------
# Function: rofi_cmd
# Description: Launch rofi with appropriate config based on WM
# -----------------------------------------------------------------
rofi_cmd() {
    local prompt="${1:-Select SSH Server}"

    case "$WM" in
        qtile)
            rofi -config "$HOME/.config/qtile/rofi/config.rasi" -dmenu -p "$prompt"
            ;;
        openbox)
            rofi -config "$HOME/.config/openbox/rofi/config.rasi" -dmenu -p "$prompt"
            ;;
        *)
            rofi -dmenu -p "$prompt"
            ;;
    esac
}

# -----------------------------------------------------------------
# Function: ssh_menu
# Description: Reads servers.txt and launches SSH via selected app
# -----------------------------------------------------------------
ssh_menu() {
    local launcher=("$@")
    local SSH_DIR="$HOME/.ssh"
    local SERVER_LIST="$SSH_DIR/servers.txt"

    # Create SSH directory and server list file if missing
    [[ ! -d "$SSH_DIR" ]] && mkdir -p "$SSH_DIR"
    [[ ! -f "$SERVER_LIST" ]] && echo "# Server Name | SSH Command" > "$SERVER_LIST"

    # Read the server list and pass names to launcher
    local SELECTED_NAME
    SELECTED_NAME=$(grep -v '^#' "$SERVER_LIST" | awk -F'|' '{print $1}' | "${launcher[@]}")
    SELECTED_NAME=$(echo "$SELECTED_NAME" | xargs)  # Trim whitespace

    if [[ -n "$SELECTED_NAME" ]]; then
        local CONNECTION_STRING
        CONNECTION_STRING=$(grep -i "^$SELECTED_NAME[[:space:]]*|" "$SERVER_LIST" | awk -F'|' '{print $2}' | xargs)
        if [[ -n "$CONNECTION_STRING" ]]; then
            alacritty -e bash -c "$CONNECTION_STRING; echo 'Press any key to exit'; read -n 1"
        else
            echo "No connection string found for $SELECTED_NAME"
        fi
    fi
}

# -----------------------------------------------------------------
# Function: install_missing
# Description: Installs missing packages using pacman
# -----------------------------------------------------------------
install_missing() {
    local packages=("$@")
    local script_name
    script_name=$(basename "$0")

    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            echo "Message from $script_name: $pkg is NOT installed, installing..."
            dunstify -u normal "Installing $pkg..."
            zenity --info --text="Installing $pkg..."

            alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
        fi
    done
}

# -----------------------------------------------------------------
# Argument parsing
# -----------------------------------------------------------------
while getopts "drh" opt 2>/dev/null; do
    case "$opt" in
        d)
            # Dependencies for dmenu mode
            install_missing dmenu openssh alacritty ttf-nerd-fonts-symbols

            # Define dmenu launcher (as an array)
           




            dmenu_launcher=(
                dmenu
                -nb "$DMENU_NB"
                -nf "$DMENU_NF"
                -sb "$DMENU_SB"
                -sf "$DMENU_SF"
                -l 15
                -i
                -p "Select SSH Server:"
            )

            ssh_menu "${dmenu_launcher[@]}"









           # dmenu_launcher=(
           #     dmenu
           #     -nb "#1e1e2e"
           #     -nf "#cdd6f4"
           #     -sb "#89b4fa"
           #     -sf "#1e1e2e"
           #     -l 15
           #     -i
           #     -p "Select SSH Server:"
           # )

           # ssh_menu "${dmenu_launcher[@]}"
            ;;
        r)
            # Dependencies for rofi mode
            install_missing rofi openssh alacritty ttf-nerd-fonts-symbols

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

# If no argument was given
echo "Usage: $(basename "$0") [-r | -d | -h]"
echo "Try $(basename "$0") -h for help."
exit 1

