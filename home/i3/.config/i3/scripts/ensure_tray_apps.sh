#!/usr/bin/env bash

# (Re)starts the tray applets (nm-applet, blueman) with icons matching the bar.
#
# - GTK tray icons die with an X 'BadWindow' error when i3bar is torn down, e.g.,
#   during an i3 restart after changing the monitor setup, so this script is run
#   by 'exec_always' in the i3 config and starts whatever is missing.
# - The applets get their own XDG_CONFIG_HOME with a gtk-3.0/settings.ini using
#   the ubuntu-mono-dark/light icon theme (light icons for a dark bar and vice
#   versa), so the icon theme of the other apps is not touched. Their dconf
#   settings are shared through a symlink. When the colorscheme changes, the
#   applets are restarted with the new icons.

# let the old i3bar go away first (that is when the applets crash)
sleep "${1:-3}"

TRAY_CONFIG="$HOME/.cache/i3-tray-config"

# icon theme of the active palette ($mod2+c)
source "$HOME/.config/ubuntu-setup/palette/colors.sh"
ICON_THEME="$TRAY_ICON_THEME"
[ "$PALETTE_NAME" = dark ] && DARK=1 || DARK=0

mkdir -p "$TRAY_CONFIG/gtk-3.0"
[ -e "$TRAY_CONFIG/dconf" ] || ln -s "$HOME/.config/dconf" "$TRAY_CONFIG/dconf"
printf '[Settings]\ngtk-icon-theme-name=%s\ngtk-application-prefer-dark-theme=%s\n' "$ICON_THEME" "$DARK" > "$TRAY_CONFIG/gtk-3.0/settings.ini.new"

# icon theme changed since the applets were started -> restart them
RESTART=0
if ! cmp -s "$TRAY_CONFIG/gtk-3.0/settings.ini.new" "$TRAY_CONFIG/gtk-3.0/settings.ini"; then
  RESTART=1
fi
mv "$TRAY_CONFIG/gtk-3.0/settings.ini.new" "$TRAY_CONFIG/gtk-3.0/settings.ini"

# true when the process runs with our settings (and not, e.g., started by the session)
has_tray_config() {
  tr '\0' '\n' < "/proc/$1/environ" 2>/dev/null | grep -qx "XDG_CONFIG_HOME=$TRAY_CONFIG"
}

start() {
  XDG_CONFIG_HOME="$TRAY_CONFIG" setsid -f "$@" >/dev/null 2>&1
}

# network manager
if command -v nm-applet >/dev/null 2>&1; then
  PID=$(pgrep -x nm-applet | head -n 1)
  if [ -n "$PID" ] && { [ "$RESTART" -eq 1 ] || ! has_tray_config "$PID"; }; then
    kill "$PID"
    sleep 0.5
    PID=""
  fi
  [ -z "$PID" ] && start nm-applet
fi

# bluetooth, blueman-applet spawns blueman-tray only once when it starts
if command -v blueman-applet >/dev/null 2>&1; then

  APPLET_PID=$(pgrep -x blueman-applet | head -n 1)

  if [ -n "$APPLET_PID" ] && { [ "$RESTART" -eq 1 ] || ! has_tray_config "$APPLET_PID"; }; then

    kill "$APPLET_PID"
    pkill -x blueman-tray
    sleep 1
    start blueman-applet

  elif [ -z "$APPLET_PID" ]; then

    start blueman-applet

  # give a freshly started applet some time to spawn its tray icon
  elif ! pgrep -x blueman-tray >/dev/null && [ "$(ps -o etimes= -p "$APPLET_PID" | tr -d ' ')" -gt 20 ]; then

    kill "$APPLET_PID"
    sleep 1
    start blueman-applet

  fi
fi
