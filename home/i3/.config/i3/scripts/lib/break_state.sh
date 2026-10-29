#!/usr/bin/env bash

# Shared state of the break reminder, used by the i3blocks [break] block and by
# ~/.config/i3/scripts/break_menu.sh.
#
# Config (created with defaults on the first run): ~/.config/i3-break.conf
#   WORK_MINUTES   work time before a break
#   BREAK_MINUTES  length of a break
#   REMIND_MINUTES repeat the notification this often while a break is due
#   IDLE_MINUTES   being away (no keyboard/mouse, or suspended) this long counts as a break
#
# State: ~/.cache/i3-break/state
#   MODE   work | due | break | snooze | off
#   START  when the current work period started [epoch s]
#   UNTIL  end of the break or of the snooze [epoch s]
#   LAST_NOTIFY, LAST_TICK [epoch s]

BREAK_CONFIG="$HOME/.config/i3-break.conf"
BREAK_STATE_DIR="$HOME/.cache/i3-break"
BREAK_STATE="$BREAK_STATE_DIR/state"
BREAK_SIGNAL=14  # signal= of the [break] block in the i3blocks config

break_load() {

  WORK_MINUTES=25
  BREAK_MINUTES=5
  REMIND_MINUTES=5
  IDLE_MINUTES=5

  if [ ! -f "$BREAK_CONFIG" ]; then
    break_save_config
  fi
  source "$BREAK_CONFIG"

  NOW=$(date +%s)
  MODE=work
  START=$NOW
  UNTIL=0
  LAST_NOTIFY=0
  LAST_TICK=$NOW

  [ -f "$BREAK_STATE" ] && source "$BREAK_STATE"
}

break_save() {
  mkdir -p "$BREAK_STATE_DIR"
  printf 'MODE=%s\nSTART=%s\nUNTIL=%s\nLAST_NOTIFY=%s\nLAST_TICK=%s\n' \
    "$MODE" "$START" "$UNTIL" "$LAST_NOTIFY" "$LAST_TICK" > "$BREAK_STATE.tmp"
  mv "$BREAK_STATE.tmp" "$BREAK_STATE"
}

break_save_config() {
  mkdir -p "$(dirname "$BREAK_CONFIG")"
  cat > "$BREAK_CONFIG" <<EOF
# Break reminder (i3 bar), see ~/.config/i3/scripts/lib/break_state.sh
# work time before a break [min]
WORK_MINUTES=$WORK_MINUTES
# length of a break [min]
BREAK_MINUTES=$BREAK_MINUTES
# repeat the notification this often while a break is due [min]
REMIND_MINUTES=$REMIND_MINUTES
# being away this long counts as a break [min]
IDLE_MINUTES=$IDLE_MINUTES
EOF
}

break_refresh_bar() {
  pkill -RTMIN+$BREAK_SIGNAL i3blocks
}

break_notify() {
  notify-send -u "${3:-normal}" -t 15000 -i alarm-symbolic "$1" "$2" -h string:x-canonical-private-synchronous:break-reminder
}
