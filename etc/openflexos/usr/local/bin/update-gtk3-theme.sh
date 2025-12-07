#!/usr/bin/env bash
# Generate GTK3 override colors from themes.json
# Creates: ~/.config/gtk-3.0/gtk.css and gtk-dark.css
# Works with Viola-Dark-GTK as the base theme.

if [ -L /home/$USER/.config/gtk-3.0/gtk.css ]; then
    rm /home/$USER/.config/gtk-3.0/gtk.css
    cp  /etc/openflexos/home/user/config/gtk-3.0/gtk.css /home/$USER/.config/gtk-3.0/gtk.css
fi


THEMES_FILE="$HOME/.config/themes.json"
GTK_DIR="$HOME/.config/gtk-3.0"
GTK_CSS="$GTK_DIR/gtk.css"
GTK_DARK="$GTK_DIR/gtk-dark.css"

# Ensure jq exists
if ! command -v jq &>/dev/null; then
    echo "Error: jq is required (install it first)"
    exit 1
fi

# Read current theme name
CURRENT_THEME=$(jq -r '.current' "$THEMES_FILE")

# Extract colors from themes.json
BG=$(jq -r ".themes.\"$CURRENT_THEME\".bg" "$THEMES_FILE")
FG=$(jq -r ".themes.\"$CURRENT_THEME\".fg" "$THEMES_FILE")
HOVER=$(jq -r ".themes.\"$CURRENT_THEME\".color1" "$THEMES_FILE")

if [[ -z "$BG" || "$BG" == "null" ]]; then
    echo "Error: could not read bg color for theme '$CURRENT_THEME'"
    exit 1
fi

mkdir -p "$GTK_DIR"

cat > "$GTK_CSS" <<EOF
/* Auto-generated GTK3 override */
/* Current Theme: $CURRENT_THEME */

/* ========================= */
/*  MAIN BACKGROUND / TEXT   */
/* ========================= */

/* Main widget background + text */
@define-color theme_bg_color_breeze        $BG;
@define-color theme_base_color_breeze      $BG;
@define-color theme_fg_color_breeze        $FG;
@define-color theme_text_color_breeze      $FG;

/* Unfocused window backgrounds */
@define-color theme_unfocused_bg_color_breeze   $BG;
@define-color theme_unfocused_base_color_breeze $BG;
@define-color theme_unfocused_fg_color_breeze   $FG;
@define-color theme_unfocused_text_color_breeze $FG;

/* Content / view background (lists, text areas, etc.) */
@define-color content_view_bg_breeze       $BG;

/* Titlebar / headerbar backgrounds */
@define-color theme_titlebar_background_breeze       $BG;
@define-color theme_titlebar_background_light_breeze $BG;

/* Tooltip background + text */
@define-color tooltip_background_breeze    $BG;
@define-color tooltip_text_breeze          $FG;

/* ========================= */
/*  HOVER / SELECTION COLORS */
/* ========================= */

/* View hover decoration */
@define-color theme_view_hover_decoration_color_breeze    $HOVER;

/* Hovered row / widget background */
@define-color theme_hovering_selected_bg_color_breeze     $HOVER;

/* Selected row background + text */
@define-color theme_selected_bg_color_breeze              $HOVER;
@define-color theme_selected_fg_color_breeze              #ffffff;

/* Button hover / focus */
@define-color theme_button_decoration_hover_breeze        $HOVER;
@define-color theme_button_decoration_focus_breeze        $HOVER;
EOF

# Some GTK setups read gtk-dark.css instead of gtk.css for dark themes
cp "$GTK_CSS" "$GTK_DARK"

echo "✔ GTK3 overrides generated for theme '$CURRENT_THEME':"
echo "   $GTK_CSS"
echo "   $GTK_DARK"
echo "   BG    = $BG"
echo "   FG    = $FG"
echo "   HOVER = $HOVER"

