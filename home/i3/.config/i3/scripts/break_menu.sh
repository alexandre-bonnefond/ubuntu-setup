#!/usr/bin/env bash

# Break reminder menu, opened by clicking the [break] block in the i3 bar:
# take a break now, restart the work timer, snooze, turn off/on, settings.

DIR="$(dirname "$(readlink -f "$0")")"
source "$DIR/lib/rofi_menu.sh"
source "$DIR/lib/break_state.sh"

break_load

case "$MODE" in
  work) STATUS="next break in $(( (WORK_MINUTES * 60 - (NOW - START) + 59) / 60 )) min" ;;
  due) STATUS="a break is due" ;;
  break) STATUS="on a break, $(( (UNTIL - NOW + 59) / 60 )) min left" ;;
  snooze) STATUS="paused for $(( (UNTIL - NOW + 59) / 60 )) more min" ;;
  *) STATUS="turned off" ;;
esac

if [ "$MODE" == "off" ]; then
  TOGGLE=$'\tTurn on'
else
  TOGGLE=$'\tTurn off'
fi

ACTIONS=(break restart snooze toggle settings)
CHOICE=$(rofi_menu "Breaks: $STATUS" "Work $WORK_MINUTES min, then a $BREAK_MINUTES min break   ·   being away $IDLE_MINUTES min counts as a break" "" \
  $'\tTake a break now' \
  $'\tRestart the timer' \
  $'\tPause for 1 hour' \
  "$TOGGLE" \
  $'\tSettings') || exit 0

case "${ACTIONS[$CHOICE]}" in

  break)
    MODE=break
    UNTIL=$(( NOW + BREAK_MINUTES * 60 ))
    break_notify "Break started" "$BREAK_MINUTES min, see you soon." low
    ;;

  restart)
    MODE=work
    START=$NOW
    ;;

  snooze)
    MODE=snooze
    UNTIL=$(( NOW + 3600 ))
    ;;

  toggle)
    if [ "$MODE" == "off" ]; then
      MODE=work
      START=$NOW
    else
      MODE=off
    fi
    ;;

  settings)
    PRESETS=("25 5" "50 10" "45 15" "90 15")
    ACTIVE=""
    for i in "${!PRESETS[@]}"; do
      [ "${PRESETS[$i]}" == "$WORK_MINUTES $BREAK_MINUTES" ] && ACTIVE="$i"
    done
    PICK=$(rofi_menu "Break rhythm" "Work / break in minutes, the timer restarts with the new rhythm" "$ACTIVE" \
      $'\t25 / 5  (Pomodoro)' \
      $'\t50 / 10' \
      $'\t45 / 15' \
      $'\t90 / 15' \
      $'\tCustom') || exit 0

    if [ "$PICK" -lt "${#PRESETS[@]}" ]; then
      read -r WORK_MINUTES BREAK_MINUTES <<< "${PRESETS[$PICK]}"
    else
      # free input, e.g. "40 8"
      CUSTOM=$(rofi -dmenu -p "Work and break minutes" -mesg "e.g. 40 8   (current: $WORK_MINUTES $BREAK_MINUTES)" \
        -theme "$MENU_ROFI_DIR/menu-list.rasi" -theme-str 'listview { enabled: false; }' < /dev/null)
      read -r W B _ <<< "$CUSTOM"
      if ! [[ "$W" =~ ^[0-9]+$ && "$B" =~ ^[0-9]+$ ]] || [ "$W" -lt 1 ] || [ "$B" -lt 1 ]; then
        [ -n "$CUSTOM" ] && break_notify "Break reminder" "Expected two numbers of minutes, e.g. 40 8" low
        exit 0
      fi
      WORK_MINUTES=$W
      BREAK_MINUTES=$B
    fi

    break_save_config
    MODE=work
    START=$NOW
    break_notify "Break rhythm" "Work $WORK_MINUTES min, then a $BREAK_MINUTES min break." low
    ;;

esac

break_save
break_refresh_bar
