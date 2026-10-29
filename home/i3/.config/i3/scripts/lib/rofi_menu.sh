#!/usr/bin/env bash

# Shared rofi menu for the i3 menus (power, screen layout, colorscheme, ...),
# so that they all look the same as the $mod+d launcher.
#
# Usage (source this file):
#
#   rofi_menu "Title" "message under the entries" ACTIVE_ROW \
#     $'\tLock' $'\tShutdown' ...
#
# - each entry is "<FontAwesome glyph><TAB><label>"
# - ACTIVE_ROW is the index of the entry to highlight as the current state, or ""
# - prints the index of the selected entry, prints nothing when cancelled
#
# The style is one of the templates ~/.config/rofi/menu-<style>.rasi, taken
# from $MENU_STYLE or from the file ~/.config/rofi/menu_style.

MENU_ROFI_DIR="$HOME/.config/rofi"

rofi_menu() {

  local title="$1"
  local message="$2"
  local active="$3"
  shift 3

  local style="${MENU_STYLE:-}"
  if [ -z "$style" ] && [ -f "$MENU_ROFI_DIR/menu_style" ]; then
    style=$(tr -d '[:space:]' < "$MENU_ROFI_DIR/menu_style")
  fi
  [ -f "$MENU_ROFI_DIR/menu-$style.rasi" ] || style="tiles"

  # icon above the label for the grid styles, next to it for the list
  local icon_size=26
  local joint=$'\n'
  if [ "$style" = "list" ]; then
    icon_size=14
    joint="     "
  fi

  local entries=""
  local entry glyph label
  for entry in "$@"; do
    glyph="${entry%%$'\t'*}"
    label="${entry#*$'\t'}"
    label="${label//&/&amp;}"
    label="${label//</&lt;}"
    entries+="<span font_desc='FontAwesome $icon_size'>$glyph</span>$joint$label|"
  done
  entries="${entries%|}"

  local args=(-dmenu -i -markup-rows -sep '|' -format i -p "$title" -theme "$MENU_ROFI_DIR/menu-$style.rasi")
  [ -n "$message" ] && args+=(-mesg "$message")

  # no empty rows, the tiles have 3 columns
  case "$style" in
    tiles) args+=(-theme-str "listview { lines: $(( ($# + 2) / 3 )); }") ;;
    list) args+=(-theme-str "listview { lines: $#; }") ;;
  esac
  [ -n "$active" ] && args+=(-a "$active" -selected-row "$active")

  local choice
  choice=$(printf '%s' "$entries" | rofi "${args[@]}")

  # cancelled, or a typed text that does not match any entry
  if [ -z "$choice" ] || [ "$choice" -lt 0 ]; then
    return 1
  fi

  echo "$choice"
}
