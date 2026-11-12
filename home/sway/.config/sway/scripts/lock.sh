#!/usr/bin/env bash

# Screen locker: swaylock-plugin with the tree_cycle animation on each screen (saver_tree),
# the password ring is drawn over it while typing. swaylock-plugin is swaylock with a
# program drawing the background, install.sh builds it (and windowtolayer, used by
# saver_tree): without them this is plain swaylock, a dark screen.
#
# Run by swayidle (sway config) on `loginctl lock-session` (Lock in the power menu), before
# suspend (lid, power menu) and after 10 minutes without input. Returns once the screen is
# locked (-f), the locker stays in the background.
#
# lock.sh --test unlocks by itself after 30 seconds: to try the animation and the password
# without the risk of staying locked out.
# Stuck on the lock screen: Ctrl+Alt+F3, log in, pkill -USR1 swaylock (USR1 unlocks).

SCRIPTS=$(dirname "$(readlink -f "$0")")
COLOR=0B1220

# already locked, e.g. the lid closed on a locked screen (the name swaylock-plugin is cut
# to 15 characters by the kernel, it still starts with swaylock)
pgrep -u "$USER" swaylock >/dev/null && exit 0

if command -v swaylock-plugin >/dev/null && command -v windowtolayer >/dev/null; then
  LOCKER=(swaylock-plugin --command-each "$SCRIPTS/saver_tree")
else
  LOCKER=(swaylock)
fi

if [ "$1" = "--test" ]; then
  setsid -f sh -c "sleep 30; pkill -USR1 -u $USER swaylock" >/dev/null 2>&1
fi

"${LOCKER[@]}" -f -c "$COLOR" && exit 0

# swaylock-plugin did not start: the plain locker rather than no lock at all
[ "${LOCKER[0]}" != swaylock ] && swaylock -f -c "$COLOR" && exit 0

notify-send -u critical -t 5000 "Lock" "Could not lock the screen" \
  -h string:x-canonical-private-synchronous:lock
exit 1
