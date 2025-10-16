#!/bin/bash

package_list=(
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

updates_icon="󰁅"
noupdates_icon=""

# Detect package manager
if command -v checkupdates >/dev/null 2>&1; then
    # Arch-based system
    pacman_updates=$(checkupdates 2>/dev/null)
    count_pacman=$(echo "$pacman_updates" | grep -c '^[^[:space:]]')

    # Check for yay separately
    if command -v yay >/dev/null 2>&1; then
        aur_updates=$(yay -Qua 2>/dev/null)
        count_aur=$(echo "$aur_updates" | grep -c '^[^[:space:]]')
    else
        count_aur=0
    fi

    total=$((count_pacman + count_aur))
elif command -v apt >/dev/null 2>&1; then
    # Debian-based system
    apt update -qq >/dev/null 2>&1
    total=$(apt list --upgradable 2>/dev/null | grep -v "Listing..." | grep -c '^\S' || echo 0)
else
    total=0
fi


while getopts "uvh" main 2>/dev/null; do
    case "${main}" in
        u)
            alacritty -e bash -c '
                echo "Right Click to See updates";
                if command -v pacman >/dev/null; then
                    sudo pacman -Syu && yay -Syu;
                elif command -v apt >/dev/null; then
                    sudo apt update && sudo apt upgrade;
                else
                    echo "Unsupported system";
                fi;
                exec bash'
            ;;
        v)
            alacritty -e bash -c '
                if command -v pacman >/dev/null; then
                    echo "================";
                    echo "Pacman Updates";
                    echo "================";
                    checkupdates;
                    echo "================";
                    echo "AUR Updates";
                    echo "================";
                    yay -Qua;
                elif command -v apt >/dev/null; then
                    echo "================";
                    echo "APT Updates";
                    echo "================";
                    apt list --upgradable;
                else
                    echo "Unsupported system";
                fi;
                exec bash'
            ;;
        h)
            echo "A script to view pacman,apt updates and to be able to run the updates"
            echo "Usage: $(basename "$0") [ARGUMENT]"
            echo ""
            echo "Opens a new termial window, designed with the idea to work with left/right click on panels"
            printf "%-30s %s\n" " -u" "Run update with apt or pacman"
            printf "%-30s %s\n" " -v" "View updates with apt or pacman"
            ;;
        *)
            echo "Please see $(basename "$0") -h for help"
            exit 1
            ;;
    esac
    exit 0
done

# Output update count if no flags
if [[ "$#" -eq 0 ]]; then
    if [[ "$total" -eq 0 ]]; then
        echo "$noupdates_icon No Updates"
    else
        printf "%s %d Updates\n" "$updates_icon" "$total"
    fi
    exit 0
fi
