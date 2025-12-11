#!/usr/bin/env bash

# Path to your themes.json file
THEMES_FILE="$HOME/.config/themes.json"

# Path to picom.conf
PICOM_CONF="$HOME/.config/picom/picom.conf"

# Ensure jq is installed
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required (install with: sudo pacman -S jq)"
  exit 1
fi

# Read current theme name
CURRENT_THEME=$(jq -r '.current' "$THEMES_FILE")

# Extract .color1 for shadow-color
SHADOW_COLOR=$(jq -r ".themes.\"$CURRENT_THEME\".color1" "$THEMES_FILE")

# Validate
if [[ -z "$SHADOW_COLOR" || "$SHADOW_COLOR" == "null" ]]; then
  echo "Error: Could not find .color1 for theme '$CURRENT_THEME'"
  exit 1
fi

# Ensure picom.conf exists
if [[ ! -f "$PICOM_CONF" ]]; then
  echo "Error: $PICOM_CONF not found."
  exit 1
fi

# Update shadow-color using sed (ONLY this line)
sed -i "s/^shadow-color = .*/shadow-color = \"$SHADOW_COLOR\";/" "$PICOM_CONF"

echo "✅ Picom shadow-color updated using theme '$CURRENT_THEME' → $SHADOW_COLOR"

