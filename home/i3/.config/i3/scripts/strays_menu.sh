#!/usr/bin/env bash

# Strays menu, opened by right clicking the CPU block in the i3 bar.
#
# Lists the orphaned processes still burning CPU (~/.local/bin/strays: command, CPU % of one
# core, running time, folder), the picked one is killed with its children: SIGTERM, then
# SIGKILL when it is still there after 2 seconds.

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 3000 "Strays" "$1" -h string:x-canonical-private-synchronous:strays
}

mapfile -t STRAYS < <(~/.local/bin/strays -t | sort -t $'\t' -k2,2nr)
if [ "${#STRAYS[@]}" -eq 0 ]; then
  notify "No orphaned process above 10 % CPU"
  exit 0
fi

ENTRIES=()
for STRAY in "${STRAYS[@]}"; do
  IFS=$'\t' read -r PID CPU RUNNING FOLDER COMMAND <<< "$STRAY"
  ENTRIES+=($'\t'"${COMMAND:0:60}   $CPU %   $RUNNING   ${FOLDER/#$HOME/\~}")
done

PICK=$(MENU_STYLE=list rofi_menu "Strays" "Select a process to kill it (with its children)" "" "${ENTRIES[@]}") || exit 0
IFS=$'\t' read -r PID _ _ _ COMMAND <<< "${STRAYS[$PICK]}"

kill_tree() {
  local child
  for child in $(pgrep -P "$2"); do
    kill_tree "$1" "$child"
  done
  kill "-$1" "$2" 2>/dev/null
}

kill_tree TERM "$PID"
for _ in 1 2 3 4; do
  kill -0 "$PID" 2>/dev/null || break
  sleep 0.5
done
kill -0 "$PID" 2>/dev/null && kill_tree KILL "$PID"

if kill -0 "$PID" 2>/dev/null; then
  notify "Could not kill $PID: ${COMMAND:0:60}" critical
else
  notify "Killed $PID: ${COMMAND:0:60}"
  # the CPU block shows the warning again at its next check if another stray is left
  rm -f "${XDG_RUNTIME_DIR:-/tmp}"/i3blocks-cpu-stray.*
fi
