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



# Output theme.rasi
cat <<EOF > "$HOME/.config/qtile/rofi/theme.rasi"
* {
    background-color: $BACKGROUND;
    text-color:       $BLUE;
    selected-color:   $FOREGROUND;
    accent-color:     $RED;
}

configuration {
    show-icons: true;
}

window {
    location: center;
    anchor:   center;
    width: 35%;
    height: 35%;
    border: 5px;
    border-color: @accent-color;
    border-radius: 40px;
    background-color: @background-color;
}

inputbar {
    border: 0px 0px 5px 0px;
    border-color: #98971a;
    padding: 10px;
}

prompt {
    color: #d79921;
}

listview {
    padding: 10px;
}

element {
    padding: 5px;
    border-radius: 5px;
}

element normal {
    background-color: transparent;
    text-color:       @text-color;
}

element selected {
    background-color: @accent-color;
    text-color:       @selected-color;
}

element-text {
    background-color: transparent;
}

element-text selected {
    background-color: transparent;
    text-color: @selected-color;
}

entry {
    placeholder: "Search";
    color: #b16286;
}

error-message {
    expand: true;
    padding: 1em;
    text-color: #fb4934;
}



EOF