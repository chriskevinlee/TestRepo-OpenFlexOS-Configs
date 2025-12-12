#!/bin/bash
clear

set -e

# Prevent running as root
if [[ "$EUID" -eq 0 ]]; then
    echo "Do NOT run this script as root."
    exit 1
fi

# Relaunch inside Alacritty if not already running there
if [[ -z "$ALACRITTY_WINDOW_ID" ]]; then
    exec alacritty -e bash -c "$0; echo; read -rp 'Press Enter to close...'"
fi

echo "=== Arch Linux Cleanup Script ==="
echo

human() {
    numfmt --to=iec --suffix=B "$1"
}

get_size() {
    du -sb "$1" 2>/dev/null | awk '{print $1}'
}

TOTAL_SAVED=0

echo

# 1. Orphaned dependencies
orphans=$(pacman -Qqtd 2>/dev/null || true)

if [[ -n "$orphans" ]]; then
    echo "Orphaned dependencies found:"
    echo "$orphans"
    echo
    read -rp "Remove these orphaned packages? [y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        BEFORE=$(df --output=used / | tail -1)
        sudo pacman -Rns $orphans
        AFTER=$(df --output=used / | tail -1)
        SAVED=$(( (BEFORE - AFTER) * 1024 ))
        TOTAL_SAVED=$((TOTAL_SAVED + SAVED))
        echo "Freed: $(human $SAVED)"
    else
        echo "Skipped orphan removal."
    fi
else
    echo "No orphaned dependencies found."
fi

echo

# 2. Pacman cache
read -rp "Clean pacman package cache (pacman -Sc)? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    BEFORE=$(get_size /var/cache/pacman/pkg)
    sudo pacman -Sc
    AFTER=$(get_size /var/cache/pacman/pkg)
    SAVED=$((BEFORE - AFTER))
    TOTAL_SAVED=$((TOTAL_SAVED + SAVED))
    echo "Freed: $(human $SAVED)"
else
    echo "Skipped pacman cache cleanup."
fi

echo

# 3. User cache
read -rp "Delete ALL user cache (~/.cache/*)? (aggressive) [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    BEFORE=$(get_size ~/.cache)
    rm -rf ~/.cache/*
    AFTER=$(get_size ~/.cache)
    SAVED=$((BEFORE - AFTER))
    TOTAL_SAVED=$((TOTAL_SAVED + SAVED))
    echo "Freed: $(human $SAVED)"
else
    echo "Skipped user cache cleanup."
fi

echo

# 4. Journal cleanup
read -rp "Delete systemd journal logs older than 7 days? [y/N]: " answer
if [[ "$answer" =~ ^[Yy]$ ]]; then
    BEFORE=$(journalctl --disk-usage | awk '{print $4}' | sed 's/[^0-9.]//g')
    sudo journalctl --vacuum-time=7d
    AFTER=$(journalctl --disk-usage | awk '{print $4}' | sed 's/[^0-9.]//g')
    echo "Journal cleanup completed."
else
    echo "Skipped journal cleanup."
fi

echo
echo "=============================="
echo "Total disk space freed: $(human $TOTAL_SAVED)"
echo "Cleanup complete."
