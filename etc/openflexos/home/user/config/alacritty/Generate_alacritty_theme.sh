#!/bin/bash

THEME_JSON="$HOME/.config/MyThemes/MyThemes.json"
CURRENT_THEME=$(jq -r '.Current_Theme' "$THEME_JSON")

# Extract colors
BG=$(jq -r ".Themes[\"$CURRENT_THEME\"].background" "$THEME_JSON")
FG=$(jq -r ".Themes[\"$CURRENT_THEME\"].foreground" "$THEME_JSON")
RED=$(jq -r ".Themes[\"$CURRENT_THEME\"].red" "$THEME_JSON")
GREEN=$(jq -r ".Themes[\"$CURRENT_THEME\"].green" "$THEME_JSON")
YELLOW=$(jq -r ".Themes[\"$CURRENT_THEME\"].yellow" "$THEME_JSON")
BLUE=$(jq -r ".Themes[\"$CURRENT_THEME\"].blue" "$THEME_JSON")
MAGENTA=$(jq -r ".Themes[\"$CURRENT_THEME\"].magenta" "$THEME_JSON")
CYAN=$(jq -r ".Themes[\"$CURRENT_THEME\"].cyan" "$THEME_JSON")
GRAY=$(jq -r ".Themes[\"$CURRENT_THEME\"].gray" "$THEME_JSON")

ALACRITTY_THEME="$HOME/.config/alacritty/alacritty.toml"

# Output to colors.toml
cat <<EOF > "$ALACRITTY_THEME"
[colors.primary]
background = "$BG"
foreground = "$FG"

[colors.normal]
black   = "#000000"
red     = "$RED"
green   = "$GREEN"
yellow  = "$YELLOW"
blue    = "$BLUE"
magenta = "$MAGENTA"
cyan    = "$CYAN"
white   = "$GRAY"

[colors.bright]
black   = "#555555"
red     = "$RED"
green   = "$GREEN"
yellow  = "$YELLOW"
blue    = "$BLUE"
magenta = "$MAGENTA"
cyan    = "$CYAN"
white   = "$FG"
EOF
