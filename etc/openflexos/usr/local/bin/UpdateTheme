#!/usr/bin/env bash
set -e

bash update-ohmyposh.sh
bash update-rofi-theme.sh
bash update_dmenu_theme.sh
bash update-alacritty-theme.sh
bash update-dunst-theme.sh
bash update-gtk2-theme.sh
bash update-gtk3-theme.sh
bash update-gtk4-theme.sh

SOCKET="$HOME/.cache/qtile/qtilesocket.:0"

echo "Restarting Qtile..."
qtile cmd-obj -o cmd -f restart || true

# Wait until the IPC socket is back and responding
for i in {1..50}; do   # 50 * 0.2s = 10s timeout
    if qtile cmd-obj -s "$SOCKET" -o cmd -f info >/dev/null 2>&1; then
        echo "Qtile restarted successfully."
        exit 0
    fi
    sleep 0.2
done

echo "⚠️  Qtile restart timed out or IPC not ready."
exit 1

