#!/bin/bash
# ================================================================
# Description: Combined WiFi Menu using Rofi or Dmenu and status display
# Author: Chris Lee, ChatGPT
# Dependencies: rofi, dmenu, networkmanager, dunstify, NerdFontsSymbolsOnly
# ================================================================
source "$HOME/.config/dmenu_theme.conf"
wifi_icon=""
ethernet_icon=""
disconnected_icon=""

# ---------------------------------------------------------------
# Detect window manager
# ---------------------------------------------------------------
if qtile cmd-obj -o cmd -f info >/dev/null 2>&1; then
    WM="qtile"
elif pgrep -f qtile >/dev/null; then
    WM="qtile"
elif pgrep -f openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi


# ---------------------------------------------------------------
# Rofi launcher helper
# ---------------------------------------------------------------
rofi_cmd() {
    local prompt="${1:-Select an option}"

    case "$WM" in
        qtile)
            rofi -config "$HOME/.config/qtile/rofi/config.rasi" -dmenu -i -p "$prompt"
            ;;
        openbox)
            rofi -config "$HOME/.config/openbox/rofi/config.rasi" -dmenu -i -p "$prompt"
            ;;
        *)
            rofi -dmenu -i -p "$prompt"
            ;;
    esac
}

# ---------------------------------------------------------------
# Display current network status
# ---------------------------------------------------------------
status_network() {
    local state_file="/tmp/prev_network_state"

    nmcli device wifi rescan &>/dev/null

    local check_wifi check_ethernet connected_ssid current_state previous_state
    check_wifi="$(nmcli device status | grep -w wifi | grep -w connected | awk '{ print $2 }')"
    check_ethernet="$(nmcli device status | grep -w ethernet | grep -w connected | awk '{ print $2 }')"
    connected_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)

    if [[ $check_wifi == "wifi" && $check_ethernet == "ethernet" ]]; then
        current_state="$ethernet_icon $wifi_icon $connected_ssid"
    elif [[ $check_wifi == "wifi" ]]; then
        current_state="$wifi_icon $connected_ssid"
    elif [[ $check_ethernet == "ethernet" ]]; then
        current_state="$ethernet_icon"
    else
        current_state="$disconnected_icon"
    fi

    [[ -f $state_file ]] && previous_state=$(<"$state_file")

    if [[ $current_state != "$previous_state" ]]; then
        case "$current_state" in
            "$disconnected_icon") dunstify -u critical "Network Disconnected" ;;
            "$wifi_icon"*) dunstify -u normal "Connected to Wi-Fi: $connected_ssid" ;;
            "$ethernet_icon") dunstify -u normal "Connected to Ethernet" ;;
            "$ethernet_icon $wifi_icon"*) dunstify -u normal "Connected to Ethernet and Wi-Fi: $connected_ssid" ;;
        esac
    fi

    echo "$current_state" > "$state_file"
    echo "$current_state"
}

# ---------------------------------------------------------------
# Wi-Fi Menu core logic
# ---------------------------------------------------------------
wifi_network() {
    local launcher=("$@")

    local main_menu

    if [[ "${launcher[0]}" == "rofi_cmd" ]]; then
        main_menu=$(echo -e "󱚽 Connect to a Wi-Fi Network\n󰖪 Enable or Disable Wi-Fi\n󱛅 Forget a Wi-Fi Network" | rofi_cmd "Wi-Fi Manager:")
    else
        main_menu=$(echo -e "󱚽 Connect to a Wi-Fi Network\n󰖪 Enable or Disable Wi-Fi\n󱛅 Forget a Wi-Fi Network" | "${launcher[@]}" -p "Wi-Fi Manager:")
    fi

    case "$main_menu" in
        "󱚽 Connect to a Wi-Fi Network")
            local wifi_list wifi_ssid password status
            wifi_list=$(nmcli --fields SSID,ACTIVE device wifi list | sed '/^$/d' | grep -v -e '^--' -e '^SSID' | awk -F'  +' '{if ($2 == "yes") print $1 " (active)"; else print $1}' | sort -u)

            if [[ "${launcher[0]}" == "rofi_cmd" ]]; then
                wifi_ssid=$(echo "$wifi_list" | rofi_cmd "Select Wi-Fi:")
            else
                wifi_ssid=$(echo "$wifi_list" | "${launcher[@]}" -p "Select Wi-Fi:")
            fi

            [[ -z $wifi_ssid ]] && exit 0
            wifi_ssid="${wifi_ssid// (active)/}"

            if nmcli -g NAME connection show | grep -Fxq "$wifi_ssid"; then
                nmcli connection up "$wifi_ssid"
                status=$?
            else
                password=$(zenity --password --title="Wi-Fi Password for $wifi_ssid")
                nmcli device wifi connect "$wifi_ssid" password "$password"
                status=$?
            fi

            if [[ $status -eq 0 ]]; then
                dunstify -u normal "Connected to $wifi_ssid"
            else
                nmcli connection delete "$wifi_ssid" &>/dev/null
                dunstify -u critical "Failed to connect to $wifi_ssid. Try again."
            fi
            ;;
        "󰖪 Enable or Disable Wi-Fi")
            local wifi_status
            wifi_status=$(nmcli radio wifi)
            if [[ $wifi_status == "enabled" ]]; then
                nmcli radio wifi off
                dunstify -u normal "Wi-Fi Disabled"
            else
                nmcli radio wifi on
                dunstify -u normal "Wi-Fi Enabled"
            fi
            ;;
        "󱛅 Forget a Wi-Fi Network")
            local saved_wifi forget_ssid
            saved_wifi=$(nmcli -f NAME,TYPE connection show | grep wifi | awk '{print $1}' | sort -u)

            if [[ "${launcher[0]}" == "rofi_cmd" ]]; then
                forget_ssid=$(echo "$saved_wifi" | rofi_cmd "Forget which Wi-Fi?")
            else
                forget_ssid=$(echo "$saved_wifi" | "${launcher[@]}" -p "Forget which Wi-Fi?")
            fi

            [[ -n $forget_ssid ]] && nmcli connection delete "$forget_ssid" && dunstify -u normal "$forget_ssid removed"
            ;;
    esac
}

# ---------------------------------------------------------------
# Default action (no args → show status)
# ---------------------------------------------------------------
if [[ $# -eq 0 ]]; then
    status_network
    exit 0
fi

# ---------------------------------------------------------------
# Install missing dependencies helper
# ---------------------------------------------------------------
install_missing() {
    local packages=("$@")
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            echo "Installing $pkg..."
            dunstify -u normal "Installing $pkg..."
            alacritty -e bash -c "sudo pacman -S --noconfirm $pkg; read -p 'Press Enter to close...'"
        fi
    done
}

# ---------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------
while getopts "rdh" opt 2>/dev/null; do
    case "$opt" in
        r)
            install_missing rofi networkmanager dunst ttf-nerd-fonts-symbols
            wifi_network rofi_cmd
            ;;
        d)
            install_missing dmenu networkmanager dunst ttf-nerd-fonts-symbols
            dmenu_launcher=(
    dmenu
    -nb "$DMENU_NB"
    -nf "$DMENU_NF"
    -sb "$DMENU_SB"
    -sf "$DMENU_SF"
    -l 15
    -i
)

wifi_network "${dmenu_launcher[@]}"

	    
	    ;;
        h)
            echo "Wi-Fi Manager Script"
            echo "Usage: $(basename "$0") [-r | -d | -h]"
            echo ""
            printf "%-30s %s\n" " -r" "Use Rofi to manage Wi-Fi"
            printf "%-30s %s\n" " -d" "Use Dmenu to manage Wi-Fi"
            printf "%-30s %s\n" " -h" "Show this help message"
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            exit 1
            ;;
    esac
    exit 0
done
