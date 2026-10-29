#!/usr/bin/env bash

# Tailscale menu, opened by clicking the tailscale icon in the i3 bar.
#
# Connect/disconnect, pick an exit node, copy IPs of this machine and of the
# peers, open the admin console. Changing the state without sudo needs the user
# to be the tailscale operator (once): sudo tailscale set --operator=$USER

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

BAR_SIGNAL=12  # signal= of the [tailscale] block in the i3blocks config

notify() {
  notify-send -u "${2:-low}" -t 3000 "Tailscale" "$1" -h string:x-canonical-private-synchronous:tailscale
}

refresh_bar() {
  pkill -RTMIN+$BAR_SIGNAL i3blocks
}

run() {
  local err
  if err=$(tailscale "$@" 2>&1); then
    return 0
  fi
  notify "$err" critical
  return 1
}

copy() {
  printf '%s' "$1" | xclip -selection clipboard
  notify "Copied $1"
}

STATUS=$(tailscale status --json 2>/dev/null)
STATE=$(echo "$STATUS" | jq -r '.BackendState // "Unknown"')
MY_IP=$(echo "$STATUS" | jq -r '.Self.TailscaleIPs[0] // empty')
MY_NAME=$(echo "$STATUS" | jq -r '.Self.HostName // empty')
# peers by their tailnet name (the HostName of some devices is just 'localhost')
NAME_JQ='((.DNSName // "") | split(".")[0]) as $n | if $n == "" then .HostName else $n end'
EXIT_NODE=$(echo "$STATUS" | jq -r "[.Peer[]? | select(.ExitNode) | $NAME_JQ][0] // \"none\"")

if [ "$STATE" == "Running" ]; then
  TOGGLE=$'\tDisconnect'
  TITLE="Tailscale: connected"
  MESSAGE="$MY_NAME   ·   $MY_IP   ·   exit node: $EXIT_NODE"
else
  TOGGLE=$'\tConnect'
  TITLE="Tailscale: ${STATE,,}"
  MESSAGE="$MY_NAME"
fi

ACTIONS=(toggle exit_node peers copy_ip admin)
CHOICE=$(rofi_menu "$TITLE" "$MESSAGE" "" \
  "$TOGGLE" \
  $'\tExit node' \
  $'\tPeers' \
  $'\tCopy my IP' \
  $'\tAdmin console') || exit 0

case "${ACTIONS[$CHOICE]}" in

  toggle)
    if [ "$STATE" == "Running" ]; then
      run down && notify "Disconnected"
    else
      run up && notify "Connected"
    fi
    ;;

  exit_node)
    # peers offering to be an exit node, the current one is highlighted
    mapfile -t NODES < <(echo "$STATUS" | jq -r ".Peer[]? | select(.ExitNodeOption) | \"\\($NAME_JQ)\\t\\(.Online)\\t\\(.ExitNode)\\t\\(.TailscaleIPs[0])\"" | sort)
    ENTRIES=($'\tNone')
    ACTIVE=0
    for i in "${!NODES[@]}"; do
      IFS=$'\t' read -r NAME ONLINE CURRENT <<< "${NODES[$i]}"
      [ "$ONLINE" == "true" ] && ICON=$'' || ICON=$''
      ENTRIES+=("$ICON"$'\t'"$NAME")
      [ "$CURRENT" == "true" ] && ACTIVE=$(( i + 1 ))
    done
    if [ "${#NODES[@]}" -eq 0 ]; then
      notify "No exit nodes available in your tailnet"
      exit 0
    fi
    PICK=$(rofi_menu "Exit node" "Traffic to the internet goes through the selected node" "$ACTIVE" "${ENTRIES[@]}") || exit 0
    if [ "$PICK" -eq 0 ]; then
      run set --exit-node= && notify "Exit node disabled"
    else
      IFS=$'\t' read -r NAME _ _ IP <<< "${NODES[$(( PICK - 1 ))]}"
      run set --exit-node="$IP" && notify "Using exit node $NAME"
    fi
    ;;

  peers)
    # online peers first, selecting one copies its IP
    mapfile -t PEERS < <(echo "$STATUS" | jq -r ".Peer[]? | \"\\(if .Online then 0 else 1 end)\\t\\($NAME_JQ)\\t\\(.TailscaleIPs[0])\\t\\(.Online)\"" | sort | cut -f2-)
    if [ "${#PEERS[@]}" -eq 0 ]; then
      notify "No peers in your tailnet"
      exit 0
    fi
    ENTRIES=()
    for PEER in "${PEERS[@]}"; do
      IFS=$'\t' read -r NAME IP ONLINE <<< "$PEER"
      [ "$ONLINE" == "true" ] && ICON=$'' || ICON=$''
      ENTRIES+=("$ICON"$'\t'"$NAME")
    done
    PICK=$(MENU_STYLE=list rofi_menu "Peers" "Select a peer to copy its IP" "" "${ENTRIES[@]}") || exit 0
    IFS=$'\t' read -r _ IP _ <<< "${PEERS[$PICK]}"
    copy "$IP"
    ;;

  copy_ip)
    [ -n "$MY_IP" ] && copy "$MY_IP" || notify "No Tailscale IP, are you connected?"
    ;;

  admin)
    xdg-open "https://login.tailscale.com/admin/machines" >/dev/null 2>&1 &
    ;;

esac

refresh_bar
