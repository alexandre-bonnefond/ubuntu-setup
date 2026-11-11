#!/usr/bin/env bash

# Power menu: lock, logout, suspend, hibernate, reboot, shutdown.
# Launched by $mod2+f and from the power icon in the i3 bar.
#
# Suspend is suspend-then-hibernate: suspended, then hibernated when the battery runs low
# (or after HibernateDelaySec, /etc/systemd/sleep.conf.d/), plain suspend when hibernation
# is not available. Hibernate writes the session to the swap file and powers off.
#
# Hibernation needs a swap file at least the size of the RAM, resume= and resume_offset= on
# the kernel command line (/etc/default/grub) and RESUME= in /etc/initramfs-tools/conf.d/resume.
# Ubuntu also disables it in polkit (/usr/share/polkit-1/rules.d/com.ubuntu.desktop.rules),
# it can be enabled for sudoers with:
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

SCRIPTS=$(dirname "$(readlink -f "$0")")
source "$SCRIPTS/lib/rofi_menu.sh"

notify() {
  notify-send -u "${2:-low}" -t 5000 "Power menu" "$1" -h string:x-canonical-private-synchronous:powermenu
}

# xss-lock (i3 config) runs lock.sh on lock-session and before any suspend, so the screen is
# locked when the machine wakes up. Without xss-lock, lock.sh is run directly.
xss_lock() {
  pgrep -u "$USER" -x xss-lock >/dev/null
}

lock() {
  if xss_lock; then loginctl lock-session; else setsid -f "$SCRIPTS/lock.sh"; fi
}

# suspend / hibernate
sleep_as() {
  if xss_lock; then systemctl "$1"; else setsid -f "$SCRIPTS/lock.sh" -- systemctl "$1"; fi
}

# logind answers yes/no/challenge, Ubuntu disables hibernation by default
can() {
  busctl call org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager "Can$1" 2>/dev/null | grep -Eq '"(yes|challenge)"'
}

BATTERY=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n 1)
MESSAGE="Uptime: $(uptime -p | sed 's/^up //')"
[ -n "$BATTERY" ] && MESSAGE+="   ·   Battery: $BATTERY%"

ACTIONS=(lock logout suspend hibernate reboot shutdown)
CHOICE=$(rofi_menu "$USER@$(hostname)" "$MESSAGE" "" \
  $'\tLock' \
  $'\tLogout' \
  $'\tSuspend' \
  $'\tHibernate' \
  $'\tReboot' \
  $'\tShutdown') || exit 0

case "${ACTIONS[$CHOICE]}" in
  lock) lock ;;
  logout) i3-msg exit ;;
  suspend)
    if can SuspendThenHibernate; then sleep_as suspend-then-hibernate; else sleep_as suspend; fi
    ;;
  hibernate)
    if can Hibernate; then
      sleep_as hibernate
    else
      notify "Hibernation is disabled by Ubuntu (polkit).\nSee the comment at the top of ~/.config/i3/scripts/power_menu.sh" critical
    fi
    ;;
  reboot) systemctl reboot ;;
  shutdown) systemctl poweroff ;;
esac
