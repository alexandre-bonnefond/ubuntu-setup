#!/usr/bin/env bash

# Tailscale menu, opened by clicking the tailscale icon in the bar.
#
# Connect/disconnect, pick an exit node, copy the IP of this machine, open the admin
# console. Picking a peer offers: SSH into it (regular or Tailscale SSH), its remote
# desktop (RDP, with Remmina), copy its IP. Changing the state without sudo needs the user
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
  printf '%s' "$1" | wl-copy
  notify "Copied $1"
}

# #{ peer_menu NAME IP ONLINE OS TAILSCALE_SSH: SSH, Tailscale SSH, remote desktop, copy the IP

# remote_user NAME: asks for the user on the peer and prints it, yours first, then the
# users of ~/.ssh/config
remote_user() {
  local users
  users=$({ echo "$USER"; awk 'tolower($1) == "user" { print $2 }' ~/.ssh/config 2>/dev/null; } | awk 'NF && !seen[$0]++')
  rofi -dmenu -i -p "User on $1" -mesg "Ctrl+Enter: use what is typed" \
    -theme "$MENU_ROFI_DIR/menu-list.rasi" -theme-str "listview { lines: $(wc -l <<< "$users"); }" <<< "$users"
}

# in_terminal TITLE COMMAND...: in a kitty that stays open when the command fails, to read why
in_terminal() {
  local title=$1
  shift
  setsid -f kitty --title "$title" bash -c '"$@" || read -rsn1 -p "Ended with an error, press a key to close"' _ "$@" >/dev/null 2>&1
}

peer_menu() {
  local NAME=$1 IP=$2 ONLINE=$3 OS=$4 TAILSCALE_SSH=$5
  local STATE=online TAILSCALE_SSH_LABEL="Tailscale SSH"
  [ "$ONLINE" == "true" ] || STATE=offline
  [ "$TAILSCALE_SSH" == "true" ] || TAILSCALE_SSH_LABEL="Tailscale SSH (off)"

  local ACTIONS=(ssh tailscale_ssh desktop copy_ip)
  local CHOICE REMOTE_USER
  CHOICE=$(rofi_menu "$NAME" "$IP   ·   $OS   ·   $STATE" "" \
    $'\tSSH' \
    $'\t'"$TAILSCALE_SSH_LABEL" \
    $'\tRemote desktop' \
    $'\tCopy IP') || return

  case "${ACTIONS[$CHOICE]}" in

    # the peer's own SSH server (sshd): your keys or its password. By IP, the name
    # could be another machine of the local network.
    ssh)
      REMOTE_USER=$(remote_user "$NAME") && [ -n "$REMOTE_USER" ] || return
      in_terminal "ssh $NAME" ssh "$REMOTE_USER@$IP"
      ;;

    # the SSH server of the peer's tailscale: no keys, the tailnet identity and the
    # access controls decide. The peer must have it on (it then publishes host keys).
    tailscale_ssh)
      if [ "$TAILSCALE_SSH" != "true" ]; then
        notify "Tailscale SSH is off on $NAME. To turn it on, on $NAME:\nsudo tailscale set --ssh\nand an ssh rule in the access controls (admin console)" normal
        return
      fi
      REMOTE_USER=$(remote_user "$NAME") && [ -n "$REMOTE_USER" ] || return
      in_terminal "tailscale ssh $NAME" tailscale ssh "$REMOTE_USER@$NAME"
      ;;

    # Remmina asks for the user and the password, the peer needs an RDP server
    # (GNOME: Settings, System, Remote Desktop. Else xrdp)
    desktop)
      if ! command -v remmina >/dev/null 2>&1; then
        notify "Remote desktop needs Remmina:\nsudo apt install remmina remmina-plugin-rdp" critical
        return
      fi
      setsid -f remmina -c "rdp://$IP" >/dev/null 2>&1
      ;;

    copy_ip)
      copy "$IP"
      ;;

  esac
}

# #}

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
    # online peers first, the picked one opens its menu (SSH, remote desktop, copy its IP)
    mapfile -t PEERS < <(echo "$STATUS" | jq -r ".Peer[]? | \"\\(if .Online then 0 else 1 end)\\t\\($NAME_JQ)\\t\\(.TailscaleIPs[0])\\t\\(.Online)\\t\\(.OS | if . == null or . == \"\" then \"?\" else . end)\\t\\((.sshHostKeys // []) | length > 0)\"" | sort | cut -f2-)
    if [ "${#PEERS[@]}" -eq 0 ]; then
      notify "No peers in your tailnet"
      exit 0
    fi
    ENTRIES=()
    for PEER in "${PEERS[@]}"; do
      IFS=$'\t' read -r NAME IP ONLINE _ <<< "$PEER"
      [ "$ONLINE" == "true" ] && ICON=$'' || ICON=$''
      ENTRIES+=("$ICON"$'\t'"$NAME")
    done
    PICK=$(MENU_STYLE=list rofi_menu "Peers" "Select a peer: SSH, remote desktop, copy its IP" "" "${ENTRIES[@]}") || exit 0
    IFS=$'\t' read -r NAME IP ONLINE OS TAILSCALE_SSH <<< "${PEERS[$PICK]}"
    peer_menu "$NAME" "$IP" "$ONLINE" "$OS" "$TAILSCALE_SSH"
    ;;

  copy_ip)
    [ -n "$MY_IP" ] && copy "$MY_IP" || notify "No Tailscale IP, are you connected?"
    ;;

  admin)
    xdg-open "https://login.tailscale.com/admin/machines" >/dev/null 2>&1 &
    ;;

esac

refresh_bar
