#!/usr/bin/env bash

# Power menu: lock, logout, suspend, reboot, shutdown.
# Launched by $mod2+f and from the power icon in the bar.
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

# -f: swaylock forks once the screen is locked (like i3lock), the menu returns
lock() {
  swaylock -f -c 0B1220 && return 0
  notify "Could not lock the screen" critical
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
  logout) swaymsg exit ;;
  # swayidle locks the screen before the suspend (sway config)
  suspend) systemctl suspend ;;
  hibernate)
    if can Hibernate; then
      systemctl hibernate
    else
      notify "Hibernation is disabled by Ubuntu (polkit).\nSee the comment at the top of ~/.config/sway/scripts/power_menu.sh" critical
    fi
    ;;
  reboot) systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
