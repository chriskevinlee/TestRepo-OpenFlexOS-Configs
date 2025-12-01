#!/usr/bin/env bash
# Regenerate dmenu theme file from the master theme JSON
# Current Theme: $THEME

THEME_FILE="$HOME/.config/themes.json"
OUTPUT_FILE="$HOME/.config/dmenu_theme.conf"

THEME=$(jq -r '.current' "$THEME_FILE")
# Current Theme: $THEME

# Extract colors
nb=$(jq -r ".themes[\"$THEME\"].bg" "$THEME_FILE")
nf=$(jq -r ".themes[\"$THEME\"].fg" "$THEME_FILE")
sb=$(jq -r ".themes[\"$THEME\"].color1" "$THEME_FILE")
sf=$(jq -r ".themes[\"$THEME\"].bg" "$THEME_FILE")

# Create the dmenu theme file
mkdir -p "$(dirname "$OUTPUT_FILE")"
cat > "$OUTPUT_FILE" <<EOF
# Auto-generated dmenu theme
DMENU_NB="$nb"
DMENU_NF="$nf"
DMENU_SB="$sb"
DMENU_SF="$sf"
DMENU_OPTS="-nb \$DMENU_NB -nf \$DMENU_NF -sb \$DMENU_SB -sf \$DMENU_SF -l 15 -i"
EOF

echo "✅ Generated dmenu theme for '$THEME' → $OUTPUT_FILE"

