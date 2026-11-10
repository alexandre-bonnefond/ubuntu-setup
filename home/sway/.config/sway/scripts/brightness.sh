#!/bin/bash

# Screen brightness control through systemd-logind.
#
# Works without root and without being in the 'video' group (which 'light'
# needs), logind allows the user of the active session to set the backlight.
#
# Usage: brightness_logind.sh [+|-|<percent>]

STEP=5     # [%]
MINIMAL=1  # [%]

DEVICE=$(ls /sys/class/backlight/ | head -n 1)
if [ -z "$DEVICE" ]; then
  echo "No backlight device found"
  exit 1
fi

MAX=$(cat "/sys/class/backlight/$DEVICE/max_brightness")
CURRENT=$(cat "/sys/class/backlight/$DEVICE/brightness")
PERCENT=$(( (CURRENT * 100 + MAX / 2) / MAX ))

if [ $# -eq 0 ]; then
  echo "Current brightness is: $PERCENT%"
  exit 0
elif [ "$1" == "+" ]; then
  PERCENT=$(( PERCENT + STEP ))
elif [ "$1" == "-" ]; then
  PERCENT=$(( PERCENT - STEP ))
else
  PERCENT=$1
fi

[ "$PERCENT" -gt 100 ] && PERCENT=100
[ "$PERCENT" -lt "$MINIMAL" ] && PERCENT=$MINIMAL

busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto org.freedesktop.login1.Session \
  SetBrightness ssu backlight "$DEVICE" $(( MAX * PERCENT / 100 ))

notify-send -u low -t 1000 "Brightness $PERCENT%" -h int:value:"$PERCENT" \
  -h string:x-canonical-private-synchronous:brightness -i display-brightness-symbolic
