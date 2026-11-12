#!/usr/bin/env bash

# Installs the apt packages and links the configs into $HOME with GNU stow.
#
# usage: ./install.sh [--no-apt] [--dry-run] [PACKAGE...]
#
# - PACKAGE is a folder of home/ (e.g. tmux), all of them by default, so the
#   configs can be switched over one at a time.
# - stow links single files (--no-folding), so files the tools write next to
#   their config (btop logs, ranger history, ...) stay out of the repo.
# - stow changes nothing when a target already exists and is not one of its
#   links, it lists the conflicts instead: move those files away and rerun.
# - --dry-run shows what stow would link, without apt and without touching $HOME.

set -euo pipefail

REPO=$(cd "$(dirname "$0")" && pwd)

APT=1
DRY_RUN=0
PACKAGES=()
for arg in "$@"; do
  case "$arg" in
    --no-apt) APT=0 ;;
    --dry-run) DRY_RUN=1 ; APT=0 ;;
    -h|--help) sed -n '3,13p' "$0" | sed 's/^# \{0,1\}//' ; exit 0 ;;
    -*) echo "unknown option: $arg" >&2 ; exit 1 ;;
    *) PACKAGES+=("${arg%/}") ;;
  esac
done

if [ ${#PACKAGES[@]} -eq 0 ]; then
  for dir in "$REPO"/home/*/; do
    PACKAGES+=("$(basename "$dir")")
  done
fi

# #{ apt packages

if [ "$APT" = 1 ]; then
  sudo apt-get update
  grep -v -e '^#' -e '^$' "$REPO/packages.txt" | xargs sudo apt-get install -y
fi

# #}

# #{ lock screen: swaylock-plugin and windowtolayer from source (not packaged)

# swaylock-plugin is swaylock with a program drawing the background, windowtolayer lets
# that program be a terminal: together they show the tree_cycle animation on the lock
# screen (home/sway/.config/sway/scripts/lock.sh, plain swaylock without them).

if [ "$APT" = 1 ] && ! command -v swaylock-plugin >/dev/null; then
  BUILD=$(mktemp -d)
  git clone --depth 1 --branch v1.8.7 https://github.com/mstoeckl/swaylock-plugin "$BUILD/swaylock-plugin"
  (cd "$BUILD/swaylock-plugin" && meson setup build --buildtype=release -Dman-pages=disabled && ninja -C build)
  sudo install -m 755 "$BUILD/swaylock-plugin/build/swaylock-plugin" /usr/local/bin/
  # the password check: same PAM rules as swaylock (PAM only reads /etc/pam.d)
  sudo install -m 644 "$BUILD/swaylock-plugin/pam/swaylock-plugin" /etc/pam.d/swaylock-plugin
  rm -rf "$BUILD"
fi

if [ "$APT" = 1 ] && ! command -v windowtolayer >/dev/null; then
  BUILD=$(mktemp -d)
  git clone --depth 1 --branch v0.4.0 https://gitlab.freedesktop.org/mstoeckl/windowtolayer.git "$BUILD/windowtolayer"
  (cd "$BUILD/windowtolayer" && cargo build --release --locked)
  sudo install -m 755 "$BUILD/windowtolayer/target/release/windowtolayer" /usr/local/bin/
  rm -rf "$BUILD"
fi

# #}

# #{ sway login entry for hybrid NVIDIA laptops

# The entry 'Sway (NVIDIA on demand)' of the login screen's gear menu starts sway through
# session/sway-session: on the integrated GPU only, so the NVIDIA GPU can power off
# when idle, and with --unsupported-gpu, without which sway refuses to start next to
# the proprietary NVIDIA driver.

SESSION=/usr/local/share/wayland-sessions/sway-nvidia-on-demand.desktop
if [ "$APT" = 1 ] && grep -q '^nvidia ' /proc/modules; then
  sudo install -D -m 755 "$REPO/session/sway-session" /usr/local/bin/sway-session
  sudo mkdir -p "$(dirname "$SESSION")"
  printf '%s\n' '[Desktop Entry]' 'Name=Sway (NVIDIA on demand)' \
    'Comment=An i3-compatible Wayland compositor, on the integrated GPU, the NVIDIA one stays off until an app asks for it' \
    'Exec=/usr/local/bin/sway-session' 'Type=Application' 'DesktopNames=sway;wlroots' \
    | sudo tee "$SESSION" >/dev/null
fi

# #}

# #{ link the configs

if [ "$DRY_RUN" = 1 ]; then
  stow --simulate --verbose --no-folding -d "$REPO/home" -t "$HOME" "${PACKAGES[@]}"
  exit 0
fi

stow --no-folding -d "$REPO/home" -t "$HOME" "${PACKAGES[@]}"

# fonts shipped in home/fonts (e.g. the Tailscale logo of the bar)
fc-cache "$HOME/.local/share/fonts"

# #}

# #{ one line in ~/.bashrc sources the bash additions (~/.bashrc stays yours)

if [[ " ${PACKAGES[*]} " == *" bash "* ]] && ! grep -qs '\.config/bash/bashrc' "$HOME/.bashrc"; then
  printf '\n# ubuntu-setup (tmux in every terminal, aliases)\nsource ~/.config/bash/bashrc\n' >> "$HOME/.bashrc"
fi

# #}

# #{ active palette, dark unless one is already chosen

PALETTE="$HOME/.config/ubuntu-setup/palette"
if [ ! -e "$PALETTE" ]; then
  mkdir -p "$(dirname "$PALETTE")"
  ln -sfn "$REPO/palettes/dark" "$PALETTE"
fi

# #}

echo "linked: ${PACKAGES[*]}"
