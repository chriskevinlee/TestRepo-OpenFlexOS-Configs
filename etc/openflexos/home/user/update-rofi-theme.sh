#!/usr/bin/env bash
# Generate a Rofi theme based on ~/.config/openflexos/themes.json
# Current Theme: $THEME

THEME_FILE="$HOME/.config/themes.json"
ROFI_FILE="$HOME/.config/qtile/rofi/theme.rasi"

# Detect current theme
THEME=$(jq -r '.current' "$THEME_FILE")
# Current Theme: $THEME

# Helper to get a color or fallback
get_color() {
  local value
  value=$(jq -r ".themes[\"$THEME\"].$1 // empty" "$THEME_FILE")
  if [ -z "$value" ] || [ "$value" = "null" ]; then
    value="#888888"
  fi
  echo "$value"
}

# Load colors
bg=$(get_color bg)
fg=$(get_color fg)
color1=$(get_color color1)
color2=$(get_color color2)
color3=$(get_color color3)
color4=$(get_color color4)

# Optional: Map to meaningful names
background="$bg"
text="$color1"
selected="$fg"
accent="$color3"
input_border="$color2"
prompt_color="$color3"
entry_color="$color4"
error_color="$accent"

# Write the Rofi theme file
cat > "$ROFI_FILE" <<EOF
* {
    background-color: $background;
    text-color:       $text;
    selected-color:   $selected;
    accent-color:     $accent;
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
    border-color: $input_border;
    padding: 10px;
}

prompt {
    color: $prompt_color;
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
    color: $entry_color;
}

error-message {
    expand: true;
    padding: 1em;
    text-color: $error_color;
}
EOF

echo "✅ Generated Rofi theme for '$THEME' → $ROFI_FILE"
