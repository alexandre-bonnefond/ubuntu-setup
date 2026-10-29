#!/usr/bin/env bash

# Power menu: lock, logout, suspend, reboot, shutdown.
# Launched by $mod2+f and from the power icon in the i3 bar.
#
# Hibernate is not in the menu: Ubuntu disables hibernation in polkit (/usr/share/polkit-1/rules.d/com.ubuntu.desktop.rules).
# When swap and resume= are set up, it can be enabled for sudoers with:
#
#   sudo tee /etc/polkit-1/rules.d/10-enable-hibernate.rules <<'EOF'
#   polkit.addRule(function(action, subject) {
#     if ((action.id == "org.freedesktop.login1.hibernate" ||
#          action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
#          action.id == "org.freedesktop.login1.handle-hibernate-key") &&
#         subject.isInGroup("sudo")) {
#       return polkit.Result.YES;
#     }
#   });
#   EOF

source "$(dirname "$(readlink -f "$0")")/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 5000 "Power menu" "$1" -h string:x-canonical-private-synchronous:powermenu
}

# name of the app holding an active mouse/keyboard grab, asks X to log its grabs
grab_holder() {
  local log
  log=$(ls -t /var/log/Xorg.0.log ~/.local/share/xorg/Xorg.0.log 2>/dev/null | head -n 1)
  [ -r "$log" ] && command -v xdotool >/dev/null 2>&1 || return
  local lines
  lines=$(wc -l < "$log")
  xdotool key XF86LogGrabInfo
  sleep 0.3
  tail -n +"$(( lines + 1 ))" "$log" | awk '/Active grab/ { getline; sub(/.*client pid [0-9]+ /, ""); print $1; exit }' | xargs -r basename
}

# i3lock fails when another app holds the mouse/keyboard (e.g., a stuck drag or menu)
lock() {
  i3lock -c 0B1220 && return 0
  local holder
  holder=$(grab_holder)
  notify "Could not lock the screen${holder:+, '$holder' is holding the mouse/keyboard.\nClose it or click into it, then try again}" critical
  return 1
}

# logind answers yes/no/challenge, Ubuntu disables hibernation by default
can() {
  busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "Can$1" 2>/dev/null | grep -Eq '"(yes|challenge)"'
}

BATTERY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)
MESSAGE="Uptime: $(uptime -p | sed 's/^up //')"
[ -n "$BATTERY" ] && MESSAGE+="   ·   Battery: $BATTERY%"

ACTIONS=(lock logout suspend reboot shutdown)
CHOICE=$(rofi_menu "$USER@$(hostname)" "$MESSAGE" "" \
  $'\tLock' \
  $'\tLogout' \
  $'\tSuspend' \
  $'\tReboot' \
  $'\tShutdown') || exit 0

case "${ACTIONS[$CHOICE]}" in
  lock) lock ;;
  logout) i3-msg exit ;;
  suspend) lock && systemctl suspend ;;
  hibernate)
    if can Hibernate; then
      lock && systemctl hibernate
    else
      notify "Hibernation is disabled by Ubuntu (polkit).\nSee the comment at the top of ~/.config/i3/scripts/power_menu.sh" critical
    fi
    ;;
  reboot) systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
