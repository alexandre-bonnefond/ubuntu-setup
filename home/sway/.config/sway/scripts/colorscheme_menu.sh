#!/usr/bin/env bash

# Dark/light colorscheme menu ($mod2+c), switches with ~/.local/bin/colorscheme.

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

case "$(~/.local/bin/colorscheme)" in
  dark) ACTIVE=0 ;;
  light) ACTIVE=1 ;;
  *) ACTIVE="" ;;
esac

SCHEMES=(dark light)
CHOICE=$(rofi_menu "Colorscheme" "" "$ACTIVE" \
  $'\tDark' \
  $'\tLight') || exit 0

~/.local/bin/colorscheme "${SCHEMES[$CHOICE]}" >/dev/null
