#!/usr/bin/env bash

# Moves the pointer to the top left corner of the focused window (mouse mode, b).

read -r X Y < <(swaymsg -t get_tree | jq -r '.. | objects | select(.focused == true) | "\(.rect.x) \(.rect.y)"' | head -n 1)
[ -n "$X" ] && swaymsg "seat seat0 cursor set $X $Y" >/dev/null
