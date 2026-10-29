#!/usr/bin/env bash

# Rofi menu for switching between the monitor setups saved by arandr
# (~/.screenlayout/*.sh). After applying the setup, i3 is restarted
# (the same as $mod+Shift+r) so that the bar and workspaces follow the new outputs.
#
# Launched from the i3blocks [screenlayout] block and by $mod2+m.

LAYOUT_DIR="${SCREENLAYOUT_DIR:-$HOME/.screenlayout}"

# detach first, otherwise the i3 restart would kill this script when it is
# started from i3blocks (i3blocks is a child of i3bar)
if [ -z "${SCREEN_LAYOUT_MENU_DETACHED:-}" ]; then
  SCREEN_LAYOUT_MENU_DETACHED=1 setsid -f "$0" "$@" >/dev/null 2>&1 </dev/null
  exit 0
fi

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 2000 "Screen layout" "$1" -h string:x-canonical-private-synchronous:screenlayout
}

# active outputs, one "NAME WxH+X+Y" per line
current_setup() {
  xrandr --query | awk '/ connected/ { for (i = 3; i <= NF; i++) if ($i ~ /^[0-9]+x[0-9]+\+[0-9]+\+[0-9]+$/) { print $1, $i; break } }' | sort
}

# the same for a layout script exported by arandr
layout_setup() {
  tr ' ' '\n' < "$1" | awk '
    function flush() { if (name != "" && mode != "") { split(pos, p, "x"); print name, mode "+" p[1] "+" p[2] } }
    prev == "--output" { flush(); name = $0; mode = ""; pos = "0x0" }
    prev == "--mode"   { mode = $0 }
    prev == "--pos"    { pos = $0 }
    $0 == "--off"      { mode = "" }
    { prev = $0 }
    END { flush() }' | sort
}

shopt -s nullglob
LAYOUTS=("$LAYOUT_DIR"/*.sh)

if [ "${#LAYOUTS[@]}" -eq 0 ]; then
  notify "No layouts in $LAYOUT_DIR, save one with arandr first." critical
  setsid -f arandr >/dev/null 2>&1
  exit 1
fi

# build the menu entries and find which layout is currently active
CURRENT=$(current_setup)
CURRENT_NAME="custom"
ACTIVE_ROW=""
ENTRIES=()
for i in "${!LAYOUTS[@]}"; do
  NAME=$(basename "${LAYOUTS[$i]}" .sh)
  SETUP=$(layout_setup "${LAYOUTS[$i]}")
  # laptop icon when only the internal panel is used, monitor icon otherwise
  if echo "$SETUP" | grep -Evq '^(eDP|LVDS|DSI)'; then
    ENTRIES+=($'\uf108\t'"${NAME^}")
  else
    ENTRIES+=($'\uf109\t'"${NAME^}")
  fi
  if [ -z "$ACTIVE_ROW" ] && [ "$SETUP" == "$CURRENT" ]; then
    ACTIVE_ROW="$i"
    CURRENT_NAME="$NAME"
  fi
done
ENTRIES+=($'\uf013\tArandr')

CONNECTED=$(xrandr --query | awk '/ connected/ { print $1 }' | paste -sd ',' | sed 's/,/, /g')

CHOICE=$(rofi_menu "Screens: $CURRENT_NAME" "Connected: $CONNECTED" "$ACTIVE_ROW" "${ENTRIES[@]}") || exit 0

if [ "$CHOICE" -eq "${#LAYOUTS[@]}" ]; then

  # edit the setup by hand, i3 gets restarted once arandr is closed
  arandr
  NAME="arandr"

else

  LAYOUT="${LAYOUTS[$CHOICE]}"
  NAME=$(basename "$LAYOUT" .sh)

  if ! sh "$LAYOUT"; then
    notify "Failed to apply '$NAME'" critical
    exit 1
  fi

fi

# i3bar shows the tray on the primary output ('tray_output primary'), make
# sure there is one, prefer an external monitor
if ! xrandr --query | grep -Eq ' connected primary [0-9]+x[0-9]+\+'; then
  ACTIVE_OUTPUTS=$(current_setup | awk '{ print $1 }')
  PRIMARY=$(echo "$ACTIVE_OUTPUTS" | grep -Ev '^(eDP|LVDS|DSI)' | head -n 1)
  [ -z "$PRIMARY" ] && PRIMARY=$(echo "$ACTIVE_OUTPUTS" | head -n 1)
  [ -n "$PRIMARY" ] && xrandr --output "$PRIMARY" --primary
fi

# let the outputs settle, then restart i3 (same as $mod+Shift+r)
sleep 1
i3-msg restart >/dev/null

notify "Switched to '$NAME'"
