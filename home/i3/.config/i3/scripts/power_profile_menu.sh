#!/usr/bin/env bash

# Power profile menu (power-profiles-daemon), opened from the i3 bar.
#
# - Power saver: lower CPU clocks and boost off, quieter and cooler, longest battery
# - Balanced: the default, full speed when needed, saves power when idle
# - Performance: CPU kept at high clocks, fastest, more heat/fan, shortest battery

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

BAR_SIGNAL=13  # signal= of the [power_profile] block in the i3blocks config

command -v powerprofilesctl >/dev/null 2>&1 || exit 1

PROFILES=(power-saver balanced performance)
CURRENT=$(powerprofilesctl get 2>/dev/null)

ACTIVE=""
for i in "${!PROFILES[@]}"; do
  [ "${PROFILES[$i]}" == "$CURRENT" ] && ACTIVE="$i"
done

CHOICE=$(rofi_menu "Power profile" "Saver: quiet, cool, longest battery   ·   Balanced: default   ·   Performance: fastest, more fan and heat" "$ACTIVE" \
  $'\tPower saver' \
  $'\tBalanced' \
  $'\tPerformance') || exit 0

if ERR=$(powerprofilesctl set "${PROFILES[$CHOICE]}" 2>&1); then
  notify-send -u low -t 1500 "Power profile: ${PROFILES[$CHOICE]}" -h string:x-canonical-private-synchronous:powerprofile
else
  notify-send -u critical -t 5000 "Power profile" "$ERR" -h string:x-canonical-private-synchronous:powerprofile
fi

pkill -RTMIN+$BAR_SIGNAL i3blocks
