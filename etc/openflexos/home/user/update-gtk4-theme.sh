#!/usr/bin/env bash

THEMES_FILE="$HOME/.config/themes.json"
GTK4_FILE="$HOME/.config/gtk-4.0/gtk.css"

mkdir -p "$(dirname "$GTK4_FILE")"

if ! command -v jq &>/dev/null; then
    echo "jq is required."
    exit 1
fi

THEME=$(jq -r '.current' "$THEMES_FILE")

BG=$(jq -r ".themes.\"$THEME\".bg" "$THEMES_FILE")
FG=$(jq -r ".themes.\"$THEME\".fg" "$THEMES_FILE")
ACCENT=$(jq -r ".themes.\"$THEME\".color1" "$THEMES_FILE")

cat > "$GTK4_FILE" <<EOF
/* Auto-generated GTK4 theme */
/* Current Theme: $THEME */
/* Global */
window, * {
    background-color: ${BG};
    color: ${FG};
}

/* Buttons */
button {
    background-color: ${BG};
    color: ${FG};
    border-radius: 6px;
}

button:hover {
    background-color: ${ACCENT};
}

/* Entries */
entry {
    background-color: ${BG};
    color: ${FG};
    border: 1px solid ${ACCENT};
}

selection, text selection, entry selection {
    background-color: ${ACCENT};
    color: ${FG};
}
EOF

echo "✔️ Generated $GTK4_FILE"

