#!/bin/bash

THEME_JSON="$HOME/.config/MyThemes/MyThemes.json"
CURRENT_THEME=$(jq -r '.Current_Theme' "$THEME_JSON")

# Extract color values
BG=$(jq -r ".Themes[\"$CURRENT_THEME\"].background" "$THEME_JSON")
FG=$(jq -r ".Themes[\"$CURRENT_THEME\"].foreground" "$THEME_JSON")
RED=$(jq -r ".Themes[\"$CURRENT_THEME\"].red" "$THEME_JSON")
GREEN=$(jq -r ".Themes[\"$CURRENT_THEME\"].green" "$THEME_JSON")
YELLOW=$(jq -r ".Themes[\"$CURRENT_THEME\"].yellow" "$THEME_JSON")
BLUE=$(jq -r ".Themes[\"$CURRENT_THEME\"].blue" "$THEME_JSON")
MAGENTA=$(jq -r ".Themes[\"$CURRENT_THEME\"].magenta" "$THEME_JSON")
CYAN=$(jq -r ".Themes[\"$CURRENT_THEME\"].cyan" "$THEME_JSON")
GRAY=$(jq -r ".Themes[\"$CURRENT_THEME\"].gray" "$THEME_JSON")

POSH_THEME="$HOME/.config/ohmyposh/base.toml"

cat <<EOF > "$POSH_THEME"
"\$schema" = "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/schema.json"
version = 3

[[blocks]]
alignment = "left"
type = "prompt"

  [[blocks.segments]]
  background = "$RED"
  foreground = "$FG"
  leading_diamond = "╭─"
  style = "diamond"
  template = "{{ .UserName }}@{{ .HostName }}"
  type = "shell"

  [[blocks.segments]]
  background = "$YELLOW"
  foreground = "$FG"
  powerline_symbol = ""
  style = "powerline"
  template = "{{ .Path }} "
  type = "path"
    [blocks.segments.properties]
    folder_icon = "  "
    home_icon = " "
    style = "full"

  [[blocks.segments]]
  background = "$GREEN"
  background_templates = [
    "{{ if or (.Working.Changed) (.Staging.Changed) }}#ffeb95{{ end }}",
    "{{ if and (gt .Ahead 0) (gt .Behind 0) }}#c5e478{{ end }}",
    "{{ if gt .Ahead 0 }}#C792EA{{ end }}",
    "{{ if gt .Behind 0 }}#C792EA{{ end }}"
  ]
  foreground = "$FG"
  powerline_symbol = ""
  style = "powerline"
  template = " {{ .UpstreamIcon }}{{ .HEAD }}{{if .BranchStatus }} {{ .BranchStatus }}{{ end }}{{ if .Working.Changed }}  {{ .Working.String }}{{ end }}{{ if and (.Working.Changed) (.Staging.Changed) }} |{{ end }}{{ if .Staging.Changed }}<#ef5350>  {{ .Staging.String }}</>{{ end }} "
  type = "git"
    [blocks.segments.properties]
    branch_icon = " "
    fetch_status = true
    fetch_upstream_icon = true

  [[blocks.segments]]
  background = "$GRAY"
  foreground = "$FG"
  style = "diamond"
  template = "  {{ .FormattedMs }}⠀"
  trailing_diamond = ""
  type = "executiontime"
    [blocks.segments.properties]
    style = "roundrock"
    threshold = 0

[[blocks]]
alignment = "right"
type = "prompt"

  [[blocks.segments]]
  background = "$MAGENTA"
  foreground = "$FG"
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
  background = "$RED"
  foreground = "$FG"
  template = "On"

  [[blocks.segments]]
  background = "$YELLOW"
  foreground = "$FG"
  style = "diamond"
  template = " {{ .Name }} "
  type = "shell"

[[blocks]]
alignment = "left"
newline = true
type = "prompt"

  [[blocks.segments]]
  foreground = "$MAGENTA"
  style = "plain"
  template = "╰─"
  type = "text"

  [[blocks.segments]]
  foreground = "$CYAN"
  foreground_templates = [ "{{ if gt .Code 0 }}#ef5350{{ end }}" ]
  style = "plain"
  template = " "
  type = "status"
    [blocks.segments.properties]
    always_enabled = true
EOF
