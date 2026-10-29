#!/usr/bin/env bash

# Searchable cheatsheet of the shortcuts, aliases and bar icons ($mod2+slash, ? icon in the bar).
#
# - one tab per section of ~/.config/i3/cheatsheet.tsv, plus 'All' to search everything,
#   Ctrl+Tab / Ctrl+Shift+Tab or a click switch the tabs
# - Enter runs the entry's command when it has one (e.g., opens that menu)
# - each tab is a rofi script mode: rofi runs 'cheatsheet.sh --tab NAME' to list its rows,
#   and again with ROFI_RETV=1 and ROFI_INFO=<row number> when a row is picked. The row is
#   saved and its command runs once rofi is closed (a menu could not open while rofi is up).

SHEET="$HOME/.config/i3/cheatsheet.tsv"
THEME="$HOME/.config/rofi/cheatsheet.rasi"
PICKED="${XDG_RUNTIME_DIR:-/tmp}/cheatsheet-picked"

rows() {
  grep -v '^#' "$SHEET" | grep -v '^\s*$'
}

# the replacements are quoted, in bash 5.2 an unquoted & stands for the matched text
escape() {
  local s="${1//&/"&amp;"}"
  s="${s//</"&lt;"}"
  echo "${s//>/"&gt;"}"
}

# #{ one tab (called by rofi)

if [ "$1" = "--tab" ]; then

  TAB=$2

  case "${ROFI_RETV:-0}" in
    0) ;;
    1) echo "$ROFI_INFO" > "$PICKED"; exit 0 ;;
    *) exit 0 ;;  # typed text that matches no entry
  esac

  printf '\0markup-rows\x1ftrue\n'
  printf '\0no-custom\x1ftrue\n'
  printf '\0message\x1f%s\n' "Alt = Mod1   ·   Super = Windows key   ·   Ctrl+A = tmux prefix   ·   ↵ = Enter opens it   ·   Ctrl+Tab = next tab"

  N=0
  while IFS=$'\t' read -r SECTION KEYS DESCRIPTION COMMAND; do
    N=$(( N + 1 ))
    [ "$TAB" = All ] || [ "$SECTION" = "$TAB" ] || continue
    # monospace, padded columns for the section (only in 'All') and the keys
    LEFT=""
    [ "$TAB" = All ] && printf -v LEFT "<span font_desc='DejaVu Sans Mono 10' alpha='65%%'>%s</span>" "$(escape "$(printf '%-11s ' "$SECTION")")"
    # padded by characters (printf pads by bytes, the arrows are 3 bytes)
    PAD=$(( 28 - ${#KEYS} ))
    (( PAD < 1 )) && PAD=1
    printf -v KEYS '%s%*s' "$KEYS" "$PAD" ''
    MARK=""
    [ -n "$COMMAND" ] && MARK="  <span alpha='60%'>↵</span>"
    printf '%s<span font_desc='"'DejaVu Sans Mono 10'"' weight='"'bold'"'>%s</span>%s%s\0info\x1f%s\n' \
      "$LEFT" "$(escape "$KEYS")" "$(escape "$DESCRIPTION")" "$MARK" "$N"
  done < <(rows)

  exit 0
fi

# #}

# #{ the cheatsheet

# tabs in the order of the sheet, then All
mapfile -t TABS < <(rows | cut -f1 | awk '!seen[$0]++')
MODES=""
for TAB in "${TABS[@]}" All; do
  MODES+="$TAB:$(readlink -f "$0") --tab $TAB,"
done

rm -f "$PICKED"
rofi -modes "${MODES%,}" -show "${TABS[0]}" -theme "$THEME"

[ -f "$PICKED" ] || exit 0
N=$(cat "$PICKED")
rm -f "$PICKED"

IFS=$'\t' read -r _ _ _ COMMAND < <(rows | sed -n "${N}p")
[ -n "$COMMAND" ] && setsid -f bash -c "$COMMAND" >/dev/null 2>&1 </dev/null
exit 0

# #}
