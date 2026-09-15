#!/usr/bin/env bash
set -Eeuo pipefail

readonly EXTENSION_UUID="touchpad-gesture-customization@coooolapps.com"

[[ $EUID -ne 0 ]] || { echo "Run as your desktop user, not root." >&2; exit 1; }

systemctl --user disable --now three-finger-drag.service 2>/dev/null || true

python3 - "$EXTENSION_UUID" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True
).strip()
extensions = [item for item in ast.literal_eval(raw) if item != uuid]
subprocess.check_call(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", repr(extensions)]
)
PY

gnome-extensions uninstall "$EXTENSION_UUID" 2>/dev/null || true
extension_dir="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
if [[ -d "$extension_dir" ]]; then
  rm -rf -- "$extension_dir"
fi

echo "Administrator authorization is required to remove the installed binary and udev rule."
sudo -v
sudo rm -f -- /usr/local/bin/linux-3-finger-drag
sudo rm -f -- /etc/udev/rules.d/69-mac-like-touchpad.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=input --action=change

rm -f -- "$HOME/.config/systemd/user/three-finger-drag.service"
systemctl --user daemon-reload

cat <<'EOF'
Uninstalled the runtime, service, udev rule, and GNOME extension.
The tuning file ~/.config/linux-3-finger-drag/3fd-config.json was preserved.
Touchpad settings and your selected login session were also preserved.
EOF
