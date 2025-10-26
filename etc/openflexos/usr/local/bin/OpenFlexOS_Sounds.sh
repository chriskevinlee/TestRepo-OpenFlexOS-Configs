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
login_sound="elegant-hitech-logo-165371.mp3"
lock_sound="hitech-logo-165392.mp3"
logout_sound="sport-theme-tv-logo-154233.mp3"
reboot_sound="radio-logo-154127.mp3"
suspend_sound="computer-startup-music-97699.mp3"
hibernate_sound="startup-sound-variation-6-316850.mp3"
poweroff_sound="sanyo-scp-device-shutdown-320506.mp3"
