#!/usr/bin/env bash

# Screen locker: xsecurelock with the tree_cycle animation on each screen (saver_tree), the
# password prompt drawn over it on a key press. xsecurelock stops the animation when it
# blanks the screen (after 10 minutes, XSECURELOCK_BLANK_TIMEOUT) and during suspend.
#
# Run by xss-lock (i3 config), which locks on `xset s activate` (Lock in the power menu),
# before suspend (lid, power menu) and after the X screen saver timeout (xset s, 10 min).
# Arguments go to xsecurelock: lock.sh -- CMD runs CMD once the screen is locked.

SCRIPTS=$(dirname "$(readlink -f "$0")")

export XSECURELOCK_SAVER="$SCRIPTS/saver_tree"
export XSECURELOCK_FONT="Inconsolata:size=14"
export XSECURELOCK_SHOW_DATETIME=1
export XSECURELOCK_AUTH_BACKGROUND_COLOR="#0B1220"
# compton/picom unmaps windows in an order that flashes xsecurelock's backup window
# ("INCOMPATIBLE COMPOSITOR, PLEASE FIX!") on unlock, the README's fix is to drop it
export XSECURELOCK_COMPOSITE_OBSCURER=0

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

xsecurelock "$@" &
LOCKER=$!

# before suspend, xss-lock -l hands over its sleep delay lock as this fd: xsecurelock closes
# it once the screen is locked, this script must not keep it open or suspend waits for it
[ -n "$XSS_SLEEP_LOCK_FD" ] && eval "exec $XSS_SLEEP_LOCK_FD<&-"

wait "$LOCKER" && exit 0

# xsecurelock fails when another app holds the mouse/keyboard (e.g., a stuck drag or menu)
HOLDER=$(grab_holder)
notify-send -u critical -t 5000 "Lock" \
  "Could not lock the screen${HOLDER:+, '$HOLDER' is holding the mouse/keyboard.\nClose it or click into it, then try again}" \
  -h string:x-canonical-private-synchronous:lock
exit 1
