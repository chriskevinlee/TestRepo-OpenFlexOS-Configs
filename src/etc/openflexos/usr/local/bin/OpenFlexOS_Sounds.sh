#!/bin/bash

# ================================================================
# Description: This Script sets login, lock, logout, reboot, suspend, hibernate, and power off sounds
# Author: Chris Lee
# Dependencies: mpv (or another audio player)
# Usage: add to autostart or source in other scripts
# Notes:
# ================================================================

# Enable or disable sounds
active_sounds=yes

# Detect window manager to set sounds directory
if pgrep -x qtile >/dev/null; then
    WM="qtile"
elif pgrep -x openbox >/dev/null; then
    WM="openbox"
else
    WM="unknown"
fi

# Set sounds directory depending on WM
if [[ "$WM" == "qtile" ]]; then
    sounds_dir="$HOME/.config/qtile/sounds/"
elif [[ "$WM" == "openbox" ]]; then
    sounds_dir="$HOME/.config/openbox/sounds/"
fi

# Sound file definitions
login_sound="game-bonus-144751.mp3"
lock_sound="ambient-piano-logo-165357.mp3"
logout_sound="marimba-win-f-2-209688.mp3"
reboot_sound="introduction-sound-201413.mp3"
suspend_sound="cozy-weaves-soft-logo-176378.mp3"
hibernate_sound="lovelyboot1-103697.mp3"
poweroff_sound="retro-audio-logo-94648.mp3"