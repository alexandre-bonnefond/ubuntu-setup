#!/usr/bin/env bash

# Searchable cheatsheet of the i3 shortcuts and bar icons ($mod2+slash, ? icon in the bar).
# Entries come from ~/.config/i3/cheatsheet.tsv, Enter runs the entry's
# command when it has one (e.g., opens that menu).

SHEET="$HOME/.config/i3/cheatsheet.tsv"
THEME="$HOME/.config/rofi/menu-list.rasi"

mapfile -t ROWS < <(grep -v '^#' "$SHEET" | grep -v '^\s*$')

# the replacements are quoted, in bash 5.2 an unquoted & stands for the matched text
escape() {
  local s="${1//&/"&amp;"}"
  s="${s//</"&lt;"}"
  echo "${s//>/"&gt;"}"
}

ENTRIES=""
for ROW in "${ROWS[@]}"; do
  IFS=$'\t' read -r SECTION KEYS DESCRIPTION COMMAND <<< "$ROW"
  # monospace, padded columns for the section and the keys
  printf -v LEFT '%-11s %-28s' "$SECTION" "$KEYS"
  MARK=""
  [ -n "$COMMAND" ] && MARK="  <span alpha='60%'>↵</span>"
  ENTRIES+="<span font_desc='DejaVu Sans Mono 10' alpha='65%'>$(escape "${LEFT:0:12}")</span><span font_desc='DejaVu Sans Mono 10' weight='bold'>$(escape "${LEFT:12}")</span>$(escape "$DESCRIPTION")$MARK"$'\n'
done

CHOICE=$(printf '%s' "$ENTRIES" | rofi -dmenu -i -markup-rows -format i -no-custom \
  -p "Cheatsheet" -mesg "Alt = Mod1   ·   Super = Windows key   ·   ↵ = Enter opens it   ·   type to search" \
  -theme "$THEME" -theme-str 'window { width: 1050px; }' -theme-str 'listview { lines: 20; spacing: 2px; }' -theme-str 'element { padding: 5px 14px; }')

[ -z "$CHOICE" ] || [ "$CHOICE" -lt 0 ] && exit 0

IFS=$'\t' read -r _ _ _ COMMAND <<< "${ROWS[$CHOICE]}"
[ -n "$COMMAND" ] && setsid -f bash -c "$COMMAND" >/dev/null 2>&1 </dev/null
exit 0
