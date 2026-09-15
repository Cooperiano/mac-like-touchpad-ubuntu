#!/usr/bin/env bash
set -u

readonly EXTENSION_UUID="touchpad-gesture-customization@coooolapps.com"
extension_dir="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"

printf 'Session: %s\n' "${XDG_SESSION_TYPE:-unknown}"
printf 'Desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'GNOME: '
gnome-shell --version 2>/dev/null || printf 'not found\n'

printf '\nThree-finger drag\n'
printf '  Binary: '
if [[ -x /usr/local/bin/linux-3-finger-drag ]]; then
  /usr/local/bin/linux-3-finger-drag --version 2>/dev/null || printf 'installed\n'
else
  printf 'missing\n'
fi
printf '  Service enabled: %s\n' "$(systemctl --user is-enabled three-finger-drag.service 2>/dev/null || true)"
printf '  Service active: %s\n' "$(systemctl --user is-active three-finger-drag.service 2>/dev/null || true)"

printf '\nFour-finger gestures\n'
if [[ -f "$extension_dir/metadata.json" ]]; then
  printf '  Extension files: installed\n'
  schema_dir="$extension_dir/schemas"
  if [[ -f "$schema_dir/gschemas.compiled" ]]; then
    GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings list-recursively \
      org.gnome.shell.extensions.touchpad-gesture-customization 2>/dev/null \
      | grep -E 'horizontal-swipe-[34]|vertical-swipe-[34]|pinch-[34]'
  fi
else
  printf '  Extension files: missing\n'
fi

printf '\nTouchpads\n'
awk '
  /^N: Name=/ { name=$0 }
  /^H: Handlers=/ && name ~ /[Tt]ouchpad/ { print "  " name " — " $0 }
' /proc/bus/input/devices

printf '\nRecent service errors\n'
journalctl --user -u three-finger-drag.service --since '-10 min' --no-pager 2>/dev/null \
  | grep -Ei 'error|fail|panic|denied' || printf '  none\n'
