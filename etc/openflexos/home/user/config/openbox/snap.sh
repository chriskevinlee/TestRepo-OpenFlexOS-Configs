#!/bin/bash

# Gap from screen edges (optional)
GAP=10

# Get screen size
eval "$(xdotool getdisplaygeometry --shell)"
SCREEN_WIDTH=$DISPLAY_WIDTH
SCREEN_HEIGHT=$DISPLAY_HEIGHT

# Calculate half and quarter dimensions *safely*
HALF_WIDTH=$(( (SCREEN_WIDTH - GAP * 3) / 2 ))
HALF_HEIGHT=$(( (SCREEN_HEIGHT - GAP * 3) / 2 ))
FULL_WIDTH=$(( SCREEN_WIDTH - GAP * 2 ))
FULL_HEIGHT=$(( SCREEN_HEIGHT - GAP * 2 ))

# Positions
TOP=$GAP
BOTTOM=$((GAP + HALF_HEIGHT + GAP))
LEFT=$GAP
RIGHT=$((GAP + HALF_WIDTH + GAP))

# Which window to move
WIN_ID=$(xdotool getactivewindow)

case "$1" in
  left)
    xdotool windowmove $WIN_ID $LEFT $TOP \
             windowsize $WIN_ID $HALF_WIDTH $FULL_HEIGHT
    ;;
  right)
    xdotool windowmove $WIN_ID $RIGHT $TOP \
             windowsize $WIN_ID $HALF_WIDTH $FULL_HEIGHT
    ;;
  top)
    xdotool windowmove $WIN_ID $LEFT $TOP \
             windowsize $WIN_ID $FULL_WIDTH $HALF_HEIGHT
    ;;
  bottom)
    xdotool windowmove $WIN_ID $LEFT $BOTTOM \
             windowsize $WIN_ID $FULL_WIDTH $HALF_HEIGHT
    ;;
  topleft)
    xdotool windowmove $WIN_ID $LEFT $TOP \
             windowsize $WIN_ID $HALF_WIDTH $HALF_HEIGHT
    ;;
  topright)
    xdotool windowmove $WIN_ID $RIGHT $TOP \
             windowsize $WIN_ID $HALF_WIDTH $HALF_HEIGHT
    ;;
  bottomleft)
    xdotool windowmove $WIN_ID $LEFT $BOTTOM \
             windowsize $WIN_ID $HALF_WIDTH $HALF_HEIGHT
    ;;
  bottomright)
    xdotool windowmove $WIN_ID $RIGHT $BOTTOM \
             windowsize $WIN_ID $HALF_WIDTH $HALF_HEIGHT
    ;;
  *)
    echo "Usage: $0 {left|right|top|bottom|topleft|topright|bottomleft|bottomright}"
    exit 1
    ;;
esac
