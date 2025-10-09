#!/bin/bash

# ================================================================
# Description: Combined Wifi Menu using Rofi or Dmenu and status display
# Author: Chris Lee, ChatGPT
# Dependencies: rofi, dmenu, nmcli, dunstify, NerdFontsSymbolsOnly
# ================================================================

wifi_icon=""
ethernet_icon=""
disconnected_icon=""

# Detect window manager
if pgrep -x qtile >/dev/null; then
    WM="qtile"
elif pgrep -x openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi

# Function to call Rofi directly
rofi_cmd() {
    if [[ -z "$1" ]]; then prompt="Select an option"; else prompt="$1"; fi

    if [[ "$WM" == "qtile" ]]; then
        rofi -config "$HOME/.config/qtile/rofi/config.rasi" -dmenu -p "$prompt"
    elif [[ "$WM" == "openbox" ]]; then
        rofi -config "$HOME/.config/openbox/rofi/config.rasi" -dmenu -p "$prompt"
    else
        rofi -dmenu -p "$prompt"
    fi
}

# Function to display network status
status_network(){
    state_file="/tmp/prev_network_state"

    nmcli device wifi rescan &>/dev/null

    check_wifi="$(nmcli device status | grep -w wifi | grep -w connected | awk '{ print $2 }')"
    check_ethernet="$(nmcli device status | grep -w ethernet | grep -w connected | awk '{ print $2 }')"
    check_ethernet_wifi="$(nmcli device status | grep -e ethernet -e wifi | grep -w connected | awk '{ print $2 }' | sed 'N;s/\n/ /')"

    connected_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d':' -f2)

    if [[ $check_ethernet_wifi = "ethernet wifi" ]]; then
        current_state="$ethernet_icon $wifi_icon $connected_ssid"
    elif [[ $check_wifi = "wifi" ]]; then
        current_state="$wifi_icon $connected_ssid"
    elif [[ $check_ethernet = "ethernet" ]]; then
        current_state="$ethernet_icon"
    else
        current_state="$disconnected_icon"
    fi

    [[ -f $state_file ]] && previous_state=$(<"$state_file")

    if [[ $current_state != "$previous_state" ]]; then
        case "$current_state" in
            "$disconnected_icon") dunstify -u critical "Network Disconnected" ;;
            "$wifi_icon"*) dunstify -u normal "Connected to Wi-Fi" ;;
            "$ethernet_icon") dunstify -u normal "Connected to Ethernet" ;;
            "$ethernet_icon $wifi_icon"*) dunstify -u normal "Connected to Ethernet and Wi-Fi" ;;
        esac
    fi

    echo "$current_state" > "$state_file"
    echo "$current_state"
    exit 0
}

# WiFi menu function: accepts a launcher as argument
wifi_network() {
    local launcher_func="$1"

    main_message="WiFi Manager:\nWhat would you like to do?"
    main_menu=$(echo -e "󱚽 Connect to a Wifi Network\n󰖪 Enable Or Disable Wifi\n󱛅 Forget a Wifi Network" | $launcher_func "$main_message")

    if [[ $main_menu = "󱚽 Connect to a Wifi Network" ]]; then
        wifi_list=$(nmcli --fields SSID,ACTIVE device wifi list | sed '/^$/d' | grep -v -e '^--' -e '^SSID' | awk -F'  +' '{if ($2 == "yes") print $1 " (active)"; else print $1}' | sort -u)
        connect_wifi="WiFi Manager:\nChoose a Wifi Network"
        wifi_ssid=$(echo "$wifi_list" | $launcher_func "$connect_wifi")

        [[ -z $wifi_ssid ]] && exit 0
        wifi_ssid="${wifi_ssid// (active)/}"

        saved_connection=$(nmcli -g NAME connection show --active | grep -F "$wifi_ssid")
        if [[ -n $saved_connection ]]; then
            nmcli connection up "$wifi_ssid"
            status=$?
        else
            password=$(zenity --password --title="WiFi Manager: Enter password for $wifi_ssid")
            nmcli device wifi connect "$wifi_ssid" password "$password"
            status=$?
        fi

        if [[ $status -eq 0 ]] && nmcli -t -f active,ssid dev wifi | grep '^yes' | grep -q "$wifi_ssid"; then
            dunstify -u normal "Connected to $wifi_ssid"
        else
            nmcli connection delete "$wifi_ssid" &>/dev/null
            dunstify -u critical "Failed to connect to $wifi_ssid. Please run the script again to retry."
            exit 1
        fi

    elif [[ $main_menu = "󰖪 Enable Or Disable Wifi" ]]; then
        wifi_status=$(nmcli radio wifi)
        if [[ $wifi_status == "enabled" ]]; then
            nmcli radio wifi off
            dunstify -u normal "WiFi Radio Off"
        else
            nmcli radio wifi on
            dunstify -u normal "WiFi Radio On"
        fi

    elif [[ $main_menu = "󱛅 Forget a Wifi Network" ]]; then
        saved_wifi_connections=$(nmcli -f NAME,TYPE connection show | grep wifi | awk '{$NF=""; sub(/[ \t]+$/, ""); print}' | sort -u)
        wifi_forget="WiFi Manager:\nChoose a Wifi Network to Forget"
        forget_ssid=$(echo "$saved_wifi_connections" | $launcher_func "$wifi_forget")
        [[ -n $forget_ssid ]] && nmcli connection delete "$forget_ssid" && dunstify -u normal "$forget_ssid Deleted"
    fi
}

# Default action if no args are provided
if [[ $# -eq 0 ]]; then
    status_network
fi

# Parse command-line arguments
while getopts "rdh" main 2>/dev/null; do
    case "$main" in
        r)
            wifi_network rofi_cmd
            ;;
        d)
            dmenu_launcher="dmenu -l 10 -y 20 -x 20 -z 1880 -i -p"
            wifi_network "$dmenu_launcher"
            ;;
        h)
            echo "A script to manage WiFi network and display current network status"
            echo "Usage: $(basename "$0") [ARGUMENT]"
            echo ""
            printf "%-30s %s\n" " -r" "Use Rofi to manage WiFi"
            printf "%-30s %s\n" " -d" "Use Dmenu to manage WiFi"
            printf "%-30s %s\n" " -h" "Show this help message"
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            exit 1
            ;;
    esac
done