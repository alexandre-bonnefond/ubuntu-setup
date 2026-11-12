#!/usr/bin/env bash

# Network menu ($mod2+w, network icon in the bar): pick a Wi-Fi network, switch the Wi-Fi
# on or off, open the connection editor (saved networks, VPN, static IP).
# network_menu.sh wifi goes straight to the Wi-Fi networks (right click on the icon).
#
# swaybar cannot open the menu of a tray icon, so nm-applet is of no use there, hence
# this menu. It talks to NetworkManager with nmcli, which saves the passwords.

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

BAR_SIGNAL=15  # signal= of the [network] block in the i3blocks config

WIFI=$''
LOCKED=$''
POWER=$''
EDIT=$''

notify() {
  notify-send -u "${2:-low}" -t 4000 "Network" "$1" -h string:x-canonical-private-synchronous:network
}

refresh_bar() {
  pkill -RTMIN+$BAR_SIGNAL i3blocks
}

# #{ wifi_menu: the networks in range, the picked one is connected

wifi_menu() {

  notify "Looking for Wi-Fi networks..."

  # in use (*), signal %, security, name: strongest first, a name is listed once
  # (several access points), hidden networks have no name
  # (fields joined with the unit separator: with tabs, read would drop the empty
  # security of an open network)
  local -a NETWORKS=()
  local -A SEEN=()
  local IN_USE SIGNAL SECURITY SSID
  local SEP=$'\x1f'
  while IFS=: read -r IN_USE SIGNAL SECURITY SSID; do
    [ -n "$SSID" ] && [ -z "${SEEN[$SSID]}" ] || continue
    SEEN[$SSID]=1
    NETWORKS+=("$IN_USE$SEP$SIGNAL$SEP$SECURITY$SEP$SSID")
  done < <(nmcli --terse --escape no --fields IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan yes 2>/dev/null | sort -t: -k2,2nr)

  if [ "${#NETWORKS[@]}" -eq 0 ]; then
    notify "No Wi-Fi network in range"
    return
  fi

  local -a ENTRIES=()
  local ACTIVE="" ICON i
  for i in "${!NETWORKS[@]}"; do
    IFS=$SEP read -r IN_USE SIGNAL SECURITY SSID <<< "${NETWORKS[$i]}"
    [ -n "$SECURITY" ] && ICON=$LOCKED || ICON=$WIFI
    ENTRIES+=("$ICON"$'\t'"$SSID   $SIGNAL %")
    [ "$IN_USE" = "*" ] && ACTIVE=$i
  done

  local PICK
  PICK=$(MENU_STYLE=list rofi_menu "Wi-Fi" "Select a network to connect to it" "$ACTIVE" "${ENTRIES[@]}") || return
  IFS=$SEP read -r IN_USE _ SECURITY SSID <<< "${NETWORKS[$PICK]}"

  if [ "$IN_USE" = "*" ]; then
    notify "Already connected to $SSID"
    return
  fi

  # a network that was used before has a saved connection, with its password
  local ERR
  if nmcli -t -f NAME connection show | grep -Fxq "$SSID"; then
    notify "Connecting to $SSID..."
    if ERR=$(nmcli connection up id "$SSID" 2>&1); then
      notify "Connected to $SSID"
    else
      notify "$ERR\nA changed password: Edit connections in this menu" critical
    fi
    return
  fi

  local -a PASSWORD=()
  if [ -n "$SECURITY" ]; then
    local TYPED SHOWN
    SHOWN="${SSID//&/"&amp;"}"
    SHOWN="${SHOWN//</"&lt;"}"
    TYPED=$(rofi -dmenu -password -p "Password" -mesg "$SHOWN" -theme "$MENU_ROFI_DIR/menu-list.rasi" \
      -theme-str 'listview { lines: 0; }' -theme-str 'entry { placeholder: ""; }' </dev/null) || return
    [ -n "$TYPED" ] || return
    PASSWORD=(password "$TYPED")
  fi

  notify "Connecting to $SSID..."
  if ERR=$(nmcli device wifi connect "$SSID" "${PASSWORD[@]}" 2>&1); then
    notify "Connected to $SSID"
  else
    # e.g. a wrong password: the connection would be kept and tried again without asking
    nmcli connection delete id "$SSID" >/dev/null 2>&1
    notify "$ERR" critical
  fi
}

# #}

command -v nmcli >/dev/null 2>&1 || { notify "nmcli (NetworkManager) is not installed" critical; exit 1; }

if [ "$1" = "wifi" ]; then
  wifi_menu
  refresh_bar
  exit 0
fi

# the connections in use, without the virtual ones (tailscale, docker, loopback)
CONNECTED=$(nmcli -t -f TYPE,STATE,CONNECTION device 2>/dev/null |
  awk -F: '($1 == "wifi" || $1 == "ethernet") && $2 == "connected" { printf "%s%s: %s", sep, ($1 == "wifi" ? "Wi-Fi" : "Wired"), $3; sep = "   ·   " }')
IP=$(ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+')
MESSAGE="${CONNECTED:-Not connected}"
[ -n "$IP" ] && MESSAGE+="   ·   $IP"

if [ "$(nmcli radio wifi 2>/dev/null)" = "enabled" ]; then
  RADIO=on
  TOGGLE="$POWER"$'\tWi-Fi off'
else
  RADIO=off
  TOGGLE="$POWER"$'\tWi-Fi on'
fi

ACTIONS=(wifi toggle edit)
CHOICE=$(rofi_menu "Network" "$MESSAGE" "" \
  "$WIFI"$'\tWi-Fi networks' \
  "$TOGGLE" \
  "$EDIT"$'\tEdit connections') || exit 0

case "${ACTIONS[$CHOICE]}" in

  wifi)
    if [ "$RADIO" = off ]; then
      nmcli radio wifi on
      sleep 2  # the first scan
    fi
    wifi_menu
    ;;

  toggle)
    if [ "$RADIO" = on ]; then
      nmcli radio wifi off && notify "Wi-Fi off"
    else
      nmcli radio wifi on && notify "Wi-Fi on"
    fi
    ;;

  edit)
    setsid -f nm-connection-editor >/dev/null 2>&1
    ;;

esac

refresh_bar
