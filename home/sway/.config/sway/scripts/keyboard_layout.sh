#!/usr/bin/env bash

# Applies the keyboard layouts of /etc/default/keyboard to sway, which ignores
# that file (it is what 'sudo dpkg-reconfigure keyboard-configuration' writes).
# Run by 'exec_always' in the sway config, so a reload picks up a change.
#
# e.g. XKBLAYOUT="us,fr" and XKBOPTIONS="grp:rctrl_rshift_toggle" give two
# layouts switched with Right Ctrl + Right Shift, the bar shows the active one.

CONFIG=/etc/default/keyboard
[ -r "$CONFIG" ] || exit 0

# shellcheck source=/dev/null
source "$CONFIG"

COMMANDS=()
[ -n "${XKBMODEL:-}" ] && COMMANDS+=("input type:keyboard xkb_model $XKBMODEL")
[ -n "${XKBLAYOUT:-}" ] && COMMANDS+=("input type:keyboard xkb_layout $XKBLAYOUT")
[ -n "${XKBVARIANT:-}" ] && COMMANDS+=("input type:keyboard xkb_variant $XKBVARIANT")
[ -n "${XKBOPTIONS:-}" ] && COMMANDS+=("input type:keyboard xkb_options $XKBOPTIONS")

for cmd in "${COMMANDS[@]}"; do
  swaymsg "$cmd" >/dev/null
done
