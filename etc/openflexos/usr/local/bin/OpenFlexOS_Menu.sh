#!/usr/bin/env bash
#
# menu-launcher
# --------------
# A launcher that uses rofi or dmenu to run executable scripts
# (or symlinks to them) from ~/.config/Menu/
#
# Usage:
#   menu-launcher -r   # use rofi
#   menu-launcher -d   # use dmenu
#   menu-launcher      # auto-detect rofi or dmenu
#

MENU_DIR="$HOME/.config/qtile/scripts/menu"
mkdir -p "$MENU_DIR"

echo "󰍜 $USER"

# --- Parse command-line arguments ---
MENU_TOOL="auto"
while getopts ":rd" opt; do
  case $opt in
    r) MENU_TOOL="rofi" ;;
    d) MENU_TOOL="dmenu" ;;
    *) echo "Usage: $0 [-r | -d]" >&2; exit 1 ;;
  esac
done

# --- Find executable scripts (including symlinks) ---
SCRIPTS=$(find -L "$MENU_DIR" -maxdepth 1 \( -type f -o -type l \) -executable -printf "%f\n" | sort)

# --- Display menu ---
case "$MENU_TOOL" in
  rofi)
    CHOICE=$(echo "$SCRIPTS" | rofi -dmenu -p "Run script:")
    ;;
  dmenu)
    CHOICE=$(echo "$SCRIPTS" | dmenu -l 15 -p "Run script:")
    ;;
esac

# --- Run the chosen script ---
if [ -n "$CHOICE" ]; then
  TARGET="$(readlink -f "$MENU_DIR/$CHOICE")"
  echo "Using menu tool: $MENU_TOOL"
  echo "Running: $TARGET"

  # Pass the flag (-r or -d) and export MENU_TOOL to the script
  FLAG=""
  [ "$MENU_TOOL" = "rofi" ] && FLAG="-r"
  [ "$MENU_TOOL" = "dmenu" ] && FLAG="-d"

  MENU_TOOL="$MENU_TOOL" "$TARGET" "$FLAG" &
fi
