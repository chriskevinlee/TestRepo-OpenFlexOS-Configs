#!/usr/bin/env bash

if [ -L /home/$USER/.config/ohmyposh/base.toml ]; then
    rm /home/$USER/.config/ohmyposh/base.toml
    cp  /etc/openflexos/home/user/config/ohmyposh/base.toml /home/$USER/.config/ohmyposh/base.toml 
fi

THEME_FILE="$HOME/.config/themes.json"
TOML_FILE="$HOME/.config/ohmyposh/base.toml"

THEME=$(jq -r '.current' "$THEME_FILE")

# Extract colors
bg=$(jq -r ".themes[\"$THEME\"].bg" "$THEME_FILE")
fg=$(jq -r ".themes[\"$THEME\"].fg" "$THEME_FILE")
color3=$(jq -r ".themes[\"$THEME\"].color3" "$THEME_FILE")
color2=$(jq -r ".themes[\"$THEME\"].color2" "$THEME_FILE")
color1=$(jq -r ".themes[\"$THEME\"].color1" "$THEME_FILE")
color4=$(jq -r ".themes[\"$THEME\"].color4" "$THEME_FILE")

# Generate base.toml dynamically
cat > "$TOML_FILE" <<EOF
"$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json"
version = 3
# Current Theme: $THEME

[[blocks]]
alignment = "left"
type = "prompt"

  [[blocks.segments]]
  background = "$color1"
  foreground = "$fg"
  leading_diamond = "╭─"
  style = "diamond"
  template = "{{ .UserName }}@{{ .HostName }}"
  type = "shell"

  [[blocks.segments]]
  background = "$color3"
  foreground = "$fg"
  powerline_symbol = ""
  style = "powerline"
  template = "{{ .Path }} "
  type = "path"
    [blocks.segments.properties]
    folder_icon = "  "
    home_icon = " "
    style = "full"

  [[blocks.segments]]
  background = "$color2"
  foreground = "$fg"
  powerline_symbol = ""
  style = "powerline"
  template = "{{ .UpstreamIcon }}{{ .HEAD }}{{ if .BranchStatus }} {{ .BranchStatus }}{{ end }}"
  type = "git"
    [blocks.segments.properties]
    branch_icon = " "
    fetch_status = true
    fetch_upstream_icon = true

  [[blocks.segments]]
  background = "$color1"
  foreground = "$fg"
  style = "diamond"
  template = "  {{ .FormattedMs }}⠀"
  trailing_diamond = ""
  type = "executiontime"

[[blocks]]
alignment = "right"
type = "prompt"

  [[blocks.segments]]
  background = "$color4"
  foreground = "$fg"
  leading_diamond = ""
  style = "diamond"
  template = " {{ if .WSL }}WSL at {{ end }}{{.Icon}} "
  type = "os"
    [blocks.segments.properties]
    linux = ""
    macos = ""
    windows = ""

  [[blocks.segments]]
  type = "text"
  style = "plain"
  background = "$color2"
  foreground = "$fg"
  template = "On"

  [[blocks.segments]]
  background = "$color3"
  foreground = "$fg"
  style = "diamond"
  template = " {{ .Name }} "
  type = "shell"

[[blocks]]
alignment = "left"
newline = true
type = "prompt"

  [[blocks.segments]]
  foreground = "$color4"
  style = "plain"
  template = "╰─"
  type = "text"

  [[blocks.segments]]
  foreground = "$color1"
  style = "plain"
  template = " "
  type = "status"
    [blocks.segments.properties]
    always_enabled = true
EOF

echo "✅ Oh-My-Posh theme updated to '$THEME'."

