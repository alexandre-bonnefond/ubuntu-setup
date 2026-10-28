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

# #{ i3blocks 1.5 from source (Ubuntu ships 1.4, with the old config format)

if [ "$APT" = 1 ] && ! i3blocks -V 2>/dev/null | grep -q '^i3blocks 1\.5'; then
  BUILD=$(mktemp -d)
  git clone --depth 1 --branch 1.5 https://github.com/vivien/i3blocks "$BUILD/i3blocks"
  (cd "$BUILD/i3blocks" && ./autogen.sh && ./configure && make && sudo make install)
  rm -rf "$BUILD"
fi

# #}

# #{ link the configs

if [ "$DRY_RUN" = 1 ]; then
  stow --simulate --verbose --no-folding -d "$REPO/home" -t "$HOME" "${PACKAGES[@]}"
  exit 0
fi

stow --no-folding -d "$REPO/home" -t "$HOME" "${PACKAGES[@]}"

# #}

# #{ active palette, dark unless one is already chosen

PALETTE="$HOME/.config/ubuntu-setup/palette"
if [ ! -e "$PALETTE" ]; then
  mkdir -p "$(dirname "$PALETTE")"
  ln -sfn "$REPO/palettes/dark" "$PALETTE"
fi

# #}

echo "linked: ${PACKAGES[*]}"
