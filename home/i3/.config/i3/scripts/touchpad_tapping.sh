#!/usr/bin/env bash

set -euo pipefail

touchpad_name="$(xinput list --name-only | grep -i 'touchpad' | head -n 1 || true)"

if [ -z "${touchpad_name}" ]; then
  exit 0
fi

# Enable tap-to-click.
xinput set-prop "${touchpad_name}" "libinput Tapping Enabled" 1 || true

# Ensure two-finger tap maps to right click (lrm mapping).
# Property is [lrm, lmr].
xinput set-prop "${touchpad_name}" "libinput Tapping Button Mapping Enabled" 1 0 || true

# Enable clickfinger method so two-finger click maps to right click.
# The property is a pair: [button_areas, clickfinger].
xinput set-prop "${touchpad_name}" "libinput Click Method Enabled" 0 1 || true
