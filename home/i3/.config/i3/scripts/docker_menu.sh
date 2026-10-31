#!/usr/bin/env bash

# Docker menu, opened by right clicking the docker logo in the i3 bar.
#
# Lists the running containers (name, image, uptime), the picked one gets a
# shell (bash, else sh) in kitty. The terminal stays open when docker exec fails
# (exit codes 125-127).

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 3000 "Docker" "$1" -h string:x-canonical-private-synchronous:docker
}

if ! LIST=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.RunningFor}}' 2>&1); then
  notify "$LIST" critical
  exit 1
fi

mapfile -t CONTAINERS < <(printf '%s\n' "$LIST" | grep .)
if [ "${#CONTAINERS[@]}" -eq 0 ]; then
  notify "No running container"
  exit 0
fi

ENTRIES=()
for CONTAINER in "${CONTAINERS[@]}"; do
  IFS=$'\t' read -r NAME IMAGE SINCE <<< "$CONTAINER"
  ENTRIES+=($'\t'"$NAME   $IMAGE   ${SINCE% ago}")
done

PICK=$(MENU_STYLE=list rofi_menu "Containers" "Select a container to open a shell in it" "" "${ENTRIES[@]}") || exit 0
NAME=${CONTAINERS[$PICK]%%$'\t'*}

setsid -f kitty --title "docker $NAME" sh -c '
  docker exec -it "$1" sh -c "command -v bash >/dev/null && exec bash || exec sh"
  [ $? -ge 125 ] && { echo; printf "Press Enter to close"; read -r _; }
' _ "$NAME" >/dev/null 2>&1
