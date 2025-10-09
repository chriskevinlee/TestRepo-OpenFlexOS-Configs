#!/bin/bash

THEME_JSON="$HOME/.config/MyThemes/MyThemes.json"
CURRENT_THEME=$(jq -r '.Current_Theme' "$THEME_JSON")

# Extract needed colors
BACKGROUND=$(jq -r ".Themes[\"$CURRENT_THEME\"].background" "$THEME_JSON")
FOREGROUND=$(jq -r ".Themes[\"$CURRENT_THEME\"].foreground" "$THEME_JSON")
HIGHLIGHT=$(jq -r ".Themes[\"$CURRENT_THEME\"].highlight" "$THEME_JSON")
RED=$(jq -r ".Themes[\"$CURRENT_THEME\"].red" "$THEME_JSON")
GREEN=$(jq -r ".Themes[\"$CURRENT_THEME\"].green" "$THEME_JSON")
YELLOW=$(jq -r ".Themes[\"$CURRENT_THEME\"].yellow" "$THEME_JSON")
BLUE=$(jq -r ".Themes[\"$CURRENT_THEME\"].blue" "$THEME_JSON")
MAGENTA=$(jq -r ".Themes[\"$CURRENT_THEME\"].magenta" "$THEME_JSON")
GRAY=$(jq -r ".Themes[\"$CURRENT_THEME\"].gray" "$THEME_JSON")
TRANSPARENT=$(jq -r ".Themes[\"$CURRENT_THEME\"].transparent" "$THEME_JSON")


sed -i -E "s/#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})/$RED/g" .config/picom/picom.conf
