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
source "$HOME/.config/dmenu_theme.conf"

echo "󰍜  $USER"

# --- Parse command-line arguments ---
while getopts ":rdh" opt; do
  case $opt in
    r) MENU_TOOL="rofi" ;;
    d) MENU_TOOL="dmenu" ;;
    h )
      echo "A basic Application Launcher"
      echo "Usage: $(basename "$0") [ARGUMENT]"
      echo ""
      printf "%-30s %s\n" " -r" "Use Rofi to Launch Applications"
      printf "%-30s %s\n" " -d" "Use Dmenu to Launch Applications"
      exit 0
      ;;
    *) echo "Usage: $0 [-r | -d | -h]" >&2; exit 1 ;;
  esac
done

# --- Find executable scripts (including symlinks) ---
SCRIPTS=$(find -L "$MENU_DIR" -maxdepth 1 \( -type f -o -type l \) -executable -printf "%f\n" | sort)

# --- Define launchers ---
ROFI_CONFIG="$HOME/.config/qtile/rofi/config.rasi"

if [[ "$MENU_TOOL" == "rofi" ]]; then
  LAUNCHER=(rofi -config "$ROFI_CONFIG" -dmenu -i -p "Run script:")
elif [[ "$MENU_TOOL" == "dmenu" ]]; then
  LAUNCHER=(dmenu $DMENU_OPTS -p "Run:")
fi

# --- Display menu ---
CHOICE=$(echo "$SCRIPTS" | "${LAUNCHER[@]}")

# --- Run the chosen script ---
if [[ -n "$CHOICE" ]]; then
  TARGET="$(readlink -f "$MENU_DIR/$CHOICE")"
  echo "Using menu tool: $MENU_TOOL"
  echo "Running: $TARGET"

  # Pass the flag (-r or -d) and export MENU_TOOL to the script
  FLAG=""
  [[ "$MENU_TOOL" == "rofi" ]] && FLAG="-r"
  [[ "$MENU_TOOL" == "dmenu" ]] && FLAG="-d"

  MENU_TOOL="$MENU_TOOL" "$TARGET" "$FLAG" &
fi

