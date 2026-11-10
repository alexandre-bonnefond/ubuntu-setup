#!/usr/bin/env bash

# Clipboard history in rofi ($mod2+v), cliphist keeps the history in the
# background ('wl-paste --watch cliphist store' in the sway config).
#
#   Enter         copy the selected item to the clipboard
#   Shift+Delete  remove the selected item from the history
#
# Installation: sudo apt install cliphist wl-clipboard

MAX_ITEMS=100
THEME="$HOME/.config/rofi/menu-list.rasi"

notify() {
  notify-send -u "${2:-low}" -t 3000 "Clipboard" "$1" -h string:x-canonical-private-synchronous:clipboard
}

if ! command -v cliphist >/dev/null 2>&1 || ! command -v wl-copy >/dev/null 2>&1; then
  notify "cliphist is not installed:\nsudo apt install cliphist wl-clipboard" critical
  exit 1
fi

ROW=0
while true; do

  # newest first, one "<id><TAB><preview>" line per item, only the preview is shown
  mapfile -t LINES < <(cliphist -preview-width 200 list | head -n "$MAX_ITEMS")

  if [ "${#LINES[@]}" -eq 0 ]; then
    notify "The clipboard history is empty"
    exit 0
  fi

  CHOICE=$(printf '%s\n' "${LINES[@]}" | cut -f 2- | rofi -dmenu -i -format i -no-custom -selected-row "$ROW" \
    -p "Clipboard" -mesg "Enter: copy   ·   Shift+Delete: remove" \
    -kb-delete-entry "" -kb-custom-1 "Shift+Delete" \
    -theme "$THEME" -theme-str 'window { width: 900px; }' -theme-str 'listview { lines: 12; }')
  CODE=$?

  { [ -z "$CHOICE" ] || [ "$CHOICE" -lt 0 ]; } && exit 0

  case "$CODE" in
    0) printf '%s' "${LINES[$CHOICE]}" | cliphist decode | wl-copy; exit 0 ;;
    10) printf '%s' "${LINES[$CHOICE]}" | cliphist delete; ROW="$CHOICE" ;;
    *) exit 0 ;;
  esac

done
