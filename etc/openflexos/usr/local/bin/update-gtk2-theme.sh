#!/usr/bin/env bash

if [ -L "/home/$USER/.gtkrc-2.0" ]; then
    rm "/home/$USER/.gtkrc-2.0"
    cp  "/etc/openflexos/home/user/.gtkrc-2.0" "/home/$USER/.gtkrc-2.0"
fi

THEMES_FILE="$HOME/.config/themes.json"
GTK2_FILE="$HOME/.gtkrc-2.0"

# Ensure jq exists
if ! command -v jq &>/dev/null; then
    echo "jq is required."
    exit 1
fi

THEME=$(jq -r '.current' "$THEMES_FILE")

BG=$(jq -r ".themes.\"$THEME\".bg" "$THEMES_FILE")
FG=$(jq -r ".themes.\"$THEME\".fg" "$THEMES_FILE")
ACCENT=$(jq -r ".themes.\"$THEME\".color1" "$THEMES_FILE")

cat > "$GTK2_FILE" <<EOF
# Auto-generated GTK2 theme
# Current Theme: $THEME
gtk-color-scheme = "bg_color:${BG}\nfg_color:${FG}\ntxt_color:${FG}\nbase_color:${BG}\nselected_bg_color:${ACCENT}\nselected_fg_color:${FG}"

style "custom-theme" {
    bg[NORMAL] = "${BG}"
    fg[NORMAL] = "${FG}"
    base[NORMAL] = "${BG}"
    text[NORMAL] = "${FG}"

    bg[SELECTED] = "${ACCENT}"
    fg[SELECTED] = "${FG}"
}

class "GtkWidget" style "custom-theme"
EOF

echo "✔️ Generated $GTK2_FILE"

