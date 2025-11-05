#!/bin/bash
# ==========================================
# Power Menu Script (Qtile / Openbox)
# Supports Rofi or Dmenu launchers
# ==========================================

power_icon="⏻"
echo "$power_icon"

power() {
    # ------------------------------
    # Detect window manager
    # ------------------------------
    if pgrep -x qtile >/dev/null; then
        WM="qtile"
    elif pgrep -x openbox >/dev/null; then
        WM="openbox"
    else
        WM="unknown"
    fi

    # ------------------------------
    # Load sound configuration (optional)
    # ------------------------------
    if [[ "$WM" == "qtile" ]]; then
        source "/home/$USER/.config/qtile/scripts/OpenFlexOS_Sounds.sh"
    elif [[ "$WM" == "openbox" ]]; then
        source "/home/$USER/.config/openbox/scripts/OpenFlexOS_Sounds.sh"
    fi

    # ------------------------------
    # Launcher setup (Rofi or Dmenu)
    # ------------------------------
    if [[ "$1" == "rofi" ]]; then
        launcher="rofi -i -config /home/$USER/.config/$WM/rofi/config.rasi -dmenu"
    elif [[ "$1" == "dmenu" ]]; then
        launcher='dmenu -nb '#1e1e2e' -nf '#cdd6f4' -sb '#89b4fa' -sf '#1e1e2e' -l 15 -i -p "Power"'
    else
        echo "Invalid launcher type"
        exit 1
    fi

    # ------------------------------
    # Countdown settings
    # ------------------------------
    enable_countdown=yes
    countdown=10

    chosen=$(printf " Lock\n󰍃 Logout\n󰜉 Reboot\n Suspend\n Hibernate\n⏻ PowerOff\n" | $launcher -p "Power")

    # ------------------------------
    # Countdown timer function
    # ------------------------------
    countdown_timer() {
        [[ "$enable_countdown" != "yes" ]] && return 0

        start=$(date +%s)
        end=$(( start + countdown ))

        (
            while [ $(date +%s) -lt $end ]; do
                remaining=$(( end - $(date +%s) ))
                percent=$(( 100 * (countdown - remaining) / countdown ))
                echo "$percent"
                echo "# $chosen in: $remaining"
                sleep 0.2
            done
            echo "100"
        ) | zenity --progress \
            --title="$chosen" \
            --text="$chosen will occur in $countdown seconds" \
            --percentage=0 \
            --auto-close --width=300

        if [ $? -eq 1 ]; then
            zenity --info --text="$chosen canceled." --title="$chosen"
            return 1
        fi
        return 0
    }

    # ------------------------------
    # Logout command based on WM
    # ------------------------------
    logout_cmd() {
        if [[ "$WM" == "qtile" ]]; then
            qtile cmd-obj -o cmd -f shutdown
        elif [[ "$WM" == "openbox" ]]; then
            openbox --exit
        fi
    }

    # ------------------------------
    # Action handling
    # ------------------------------
    confirm() {
        yes_no=$(printf " no\n yes" | $launcher -p "Would You Like to $1?")
        [[ "$yes_no" == *yes* ]] || exit
    }

    case "$chosen" in
        " Lock")
            confirm "Lock"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${lock_sound}" ]] && mpv --no-video "${sounds_dir}${lock_sound}"
                xscreensaver-command -lock
            fi
            ;;
        "󰍃 Logout")
            confirm "Logout"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${logout_sound}" ]] && mpv --no-video "${sounds_dir}${logout_sound}"
                logout_cmd
            fi
            ;;
        "󰜉 Reboot")
            confirm "Reboot"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${reboot_sound}" ]] && mpv --no-video "${sounds_dir}${reboot_sound}"
                systemctl reboot
            fi
            ;;
        " Suspend")
            confirm "Suspend"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${suspend_sound}" ]] && mpv --no-video "${sounds_dir}${suspend_sound}"
                systemctl suspend
            fi
            ;;
        " Hibernate")
            confirm "Hibernate"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${hibernate_sound}" ]] && mpv --no-video "${sounds_dir}${hibernate_sound}"
                systemctl hibernate
            fi
            ;;
        "⏻ PowerOff")
            confirm "PowerOff"
            if countdown_timer; then
                [[ "$active_sounds" == yes && -f "${sounds_dir}${poweroff_sound}" ]] && mpv --no-video "${sounds_dir}${poweroff_sound}"
                systemctl poweroff
            fi
            ;;
    esac
}

# ==========================================
# CLI Argument Handling 
# ==========================================
while getopts "drh" main 2>/dev/null; do
    case "${main}" in
        d)
            package_list=(
                dmenu
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

            power dmenu
            ;;
        r)
            package_list=(
                rofi
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

            power rofi
            ;;
        h)
            echo "Usage: $(basename "$0") [OPTION]"
            echo ""
            echo "  -r    Use Rofi launcher"
            echo "  -d    Use Dmenu launcher"
            echo "  -h    Show this help message"
            ;;
        *)
            echo "Invalid option. See $(basename "$0") -h for help."
            ;;
    esac
    exit 0
done
