#!/usr/bin/env bash

# Rofi menu for switching between saved monitor setups (~/.screenlayout/*.conf).
#
# A layout is a list of sway 'output' commands, one per screen, e.g.
#
#   output eDP-1 mode 1920x1080@60.000Hz pos 0 0 scale 1 transform normal
#   output HDMI-A-1 disable
#
# The menu also saves the current setup as a new layout, and opens wdisplays to
# arrange the screens with the mouse (then save it from this menu). The bar and
# the workspaces follow the screens by themselves, no restart needed.
#
# Launched from the i3blocks [screenlayout] block and by $mod2+m.

LAYOUT_DIR="${SCREENLAYOUT_DIR:-$HOME/.screenlayout}"

# detach, so that the bar block does not wait for the menu
if [ -z "${SCREEN_LAYOUT_MENU_DETACHED:-}" ]; then
  SCREEN_LAYOUT_MENU_DETACHED=1 setsid -f "$0" "$@" >/dev/null 2>&1 </dev/null
  exit 0
fi

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 2000 "Screen layout" "$1" -h string:x-canonical-private-synchronous:screenlayout
}

OUTPUTS_JSON=$(swaymsg -t get_outputs)

# active outputs, one "NAME WxH+X+Y" per line (the mode, not the scaled size)
current_setup() {
  echo "$OUTPUTS_JSON" | jq -r '.[] | select(.active) | "\(.name) \(.current_mode.width)x\(.current_mode.height)+\(.rect.x)+\(.rect.y)"' | sort
}

# the same for a saved layout
layout_setup() {
  awk '
    $1 != "output" { next }
    {
      name = $2; mode = ""; x = 0; y = 0; off = 0
      for (i = 3; i <= NF; i++) {
        if ($i == "mode" || $i == "resolution" || $i == "res") { mode = $(i + 1); sub(/@.*/, "", mode) }
        if ($i == "pos" || $i == "position") { x = $(i + 1); y = $(i + 2) }
        if ($i == "disable") off = 1
      }
      if (!off && mode != "") print name, mode "+" x "+" y
    }' "$1" | sort
}

# the current setup as sway commands, every screen (the disabled ones too)
save_current() {
  echo "$OUTPUTS_JSON" | jq -r '.[] |
    if .active then
      "output \(.name) mode \(.current_mode.width)x\(.current_mode.height)@\(.current_mode.refresh / 1000)Hz pos \(.rect.x) \(.rect.y) scale \(.scale) transform \(.transform)"
    else
      "output \(.name) disable"
    end'
}

mkdir -p "$LAYOUT_DIR"
shopt -s nullglob
LAYOUTS=("$LAYOUT_DIR"/*.conf)

# build the menu entries and find which layout is currently active
CURRENT=$(current_setup)
CURRENT_NAME="custom"
ACTIVE_ROW=""
ENTRIES=()
for i in "${!LAYOUTS[@]}"; do
  NAME=$(basename "${LAYOUTS[$i]}" .conf)
  SETUP=$(layout_setup "${LAYOUTS[$i]}")
  # laptop icon when only the internal panel is used, monitor icon otherwise
  if echo "$SETUP" | grep -Evq '^(eDP|LVDS|DSI)'; then
    ENTRIES+=($'\t'"${NAME^}")
  else
    ENTRIES+=($'\t'"${NAME^}")
  fi
  if [ -z "$ACTIVE_ROW" ] && [ "$SETUP" == "$CURRENT" ]; then
    ACTIVE_ROW="$i"
    CURRENT_NAME="$NAME"
  fi
done
SAVE_ROW=${#ENTRIES[@]}
ENTRIES+=($'\tSave current')
ENTRIES+=($'\tArrange')

CONNECTED=$(echo "$OUTPUTS_JSON" | jq -r '[.[].name] | join(", ")')

CHOICE=$(rofi_menu "Screens: $CURRENT_NAME" "Connected: $CONNECTED" "$ACTIVE_ROW" "${ENTRIES[@]}") || exit 0

if [ "$CHOICE" -eq "$SAVE_ROW" ]; then

  NAME=$(rofi -dmenu -p "Layout name" -theme "$MENU_ROFI_DIR/menu-list.rasi" -theme-str 'listview { lines: 0; }' </dev/null)
  NAME=$(echo "$NAME" | tr -cs '[:alnum:]_-' '_' | sed 's/^_*//; s/_*$//')
  [ -z "$NAME" ] && exit 0
  save_current > "$LAYOUT_DIR/$NAME.conf"
  notify "Saved '$NAME'"

elif [ "$CHOICE" -gt "$SAVE_ROW" ]; then

  # arrange the screens with the mouse, applied live, then 'Save current'
  if command -v wdisplays >/dev/null 2>&1; then
    wdisplays
  else
    notify "wdisplays is not installed:\nsudo apt install wdisplays" critical
  fi

else

  LAYOUT="${LAYOUTS[$CHOICE]}"
  NAME=$(basename "$LAYOUT" .conf)

  # one swaymsg per screen, a failing line does not stop the others
  FAILED=0
  while read -r line; do
    case "$line" in output\ *) swaymsg "$line" >/dev/null || FAILED=1 ;; esac
  done < "$LAYOUT"

  if [ "$FAILED" -eq 1 ]; then
    notify "Some screens of '$NAME' could not be set" critical
    exit 1
  fi
  notify "Switched to '$NAME'"

fi
