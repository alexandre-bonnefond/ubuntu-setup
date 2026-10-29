#!/usr/bin/env bash

# Clipboard history in rofi ($mod2+v), CopyQ keeps the history in the background.
#
#   Enter         copy the selected item to the clipboard
#   Shift+Delete  remove the selected item from the history
#
# Installation: sudo apt install copyq

MAX_ITEMS=100
THEME="$HOME/.config/rofi/menu-list.rasi"

notify() {
  notify-send -u "${2:-low}" -t 3000 "Clipboard" "$1" -h string:x-canonical-private-synchronous:clipboard
}

if ! command -v copyq >/dev/null 2>&1; then
  notify "CopyQ is not installed:\nsudo apt install copyq" critical
  exit 1
fi

# the server is started by i3, start it here in case it is not running
if ! copyq eval 1 >/dev/null 2>&1; then
  copyq --start-server >/dev/null 2>&1
  sleep 1
fi

ROW=0
while true; do

  # one line per item, newlines and repeated spaces squashed
  ITEMS=$(copyq eval -- "
    var n = Math.min(size(), $MAX_ITEMS);
    for (var i = 0; i < n; ++i) {
      var text = str(read('text/plain', i)).replace(/\s+/g, ' ').trim();
      print((text.length > 0 ? text.substring(0, 200) : '[image or other data]') + '\n');
    }")

  if [ -z "$ITEMS" ]; then
    notify "The clipboard history is empty"
    exit 0
  fi

  CHOICE=$(printf '%s' "$ITEMS" | rofi -dmenu -i -format i -no-custom -selected-row "$ROW" \
    -p "Clipboard" -mesg "Enter: copy   ·   Shift+Delete: remove" \
    -kb-delete-entry "" -kb-custom-1 "Shift+Delete" \
    -theme "$THEME" -theme-str 'window { width: 900px; }' -theme-str 'listview { lines: 12; }')
  CODE=$?

  [ -z "$CHOICE" ] || [ "$CHOICE" -lt 0 ] && exit 0

  case "$CODE" in
    0) copyq select "$CHOICE"; exit 0 ;;
    10) copyq remove "$CHOICE"; ROW="$CHOICE" ;;
    *) exit 0 ;;
  esac

done
