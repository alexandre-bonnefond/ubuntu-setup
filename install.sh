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

# #{ sway login entry for hybrid NVIDIA laptops

# The entry 'Sway (no NVIDIA)' of the login screen's gear menu starts sway through
# session/sway-session: on the integrated GPU only, so the NVIDIA GPU can power off
# when idle, and with --unsupported-gpu, without which sway refuses to start next to
# the proprietary NVIDIA driver.

SESSION=/usr/local/share/wayland-sessions/sway-no-nvidia.desktop
if [ "$APT" = 1 ] && grep -q '^nvidia ' /proc/modules; then
  sudo install -D -m 755 "$REPO/session/sway-session" /usr/local/bin/sway-session
  sudo mkdir -p "$(dirname "$SESSION")"
  printf '%s\n' '[Desktop Entry]' 'Name=Sway (no NVIDIA)' \
    'Comment=An i3-compatible Wayland compositor, on the integrated GPU only (the NVIDIA one can power off)' \
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
