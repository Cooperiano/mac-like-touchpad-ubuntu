#!/usr/bin/env bash
set -Eeuo pipefail

readonly PROJECT_REPOSITORY="Cooperiano/mac-like-touchpad-ubuntu"
readonly PROJECT_VERSION="v0.1.0"
readonly DRAG_ASSET="linux-3-finger-drag-x86_64"
readonly DRAG_SHA256="19629266b757c076bd025cd16f6385561bca61539d8fcdf2eb0ffd40168f101d"
readonly DRAG_UPSTREAM_COMMIT="ae22defe47156e13476f08dce6cd98e5aaa49227"
readonly EXTENSION_UUID="touchpad-gesture-customization@coooolapps.com"

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
assume_yes=false
local_binary="${MAC_LIKE_TOUCHPAD_LOCAL_BINARY:-}"
temp_dir=""

log() { printf '\n==> %s\n' "$*"; }
warn() { printf 'warning: %s\n' "$*" >&2; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Usage: ./install.sh [--yes] [--local-binary PATH]

Installs macOS-style three-finger drag and GNOME four-finger gestures.

  --yes                Skip the confirmation prompt.
  --local-binary PATH  Use a locally built linux-3-finger-drag binary.
  -h, --help           Show this help.
EOF
}

cleanup() {
  if [[ -n "$temp_dir" && "$temp_dir" == /tmp/mac-like-touchpad.* && -d "$temp_dir" ]]; then
    rm -rf -- "$temp_dir"
  fi
}
trap cleanup EXIT

while (($#)); do
  case "$1" in
    --yes) assume_yes=true ;;
    --local-binary)
      shift
      (($#)) || die "--local-binary requires a path"
      local_binary="$1"
      ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
  shift
done

[[ $EUID -ne 0 ]] || die "run this script as your desktop user, not root"
[[ $(uname -m) == "x86_64" ]] || die "v0.1.0 currently provides an x86_64 binary only"

for command in curl gdbus gnome-extensions gnome-shell gsettings install python3 sha256sum sudo systemctl udevadm; do
  command -v "$command" >/dev/null || die "missing required command: $command"
done

gnome_version="$(gnome-shell --version | awk '{print $3}')"
gnome_major="${gnome_version%%.*}"
[[ "$gnome_major" =~ ^[0-9]+$ ]] || die "could not detect the GNOME Shell version"
if ((gnome_major < 45 || gnome_major > 48)); then
  die "GNOME $gnome_version is outside the tested range (45-48)"
fi

cat <<EOF
This installs:
  - macOS-style three-finger drag
  - four-finger workspace and overview gestures on GNOME Wayland
  - a per-user systemd service
  - a least-privilege udev rule for touchpads and uinput

GNOME: $gnome_version
Session: ${XDG_SESSION_TYPE:-unknown}
Pinned drag engine commit: $DRAG_UPSTREAM_COMMIT
EOF

if [[ $assume_yes != true ]]; then
  read -r -p "Continue? [y/N] " answer
  [[ "$answer" == "y" || "$answer" == "Y" ]] || exit 0
fi

temp_dir="$(mktemp -d /tmp/mac-like-touchpad.XXXXXXXX)"

log "Obtaining the verified drag engine"
drag_binary="$temp_dir/$DRAG_ASSET"
if [[ -n "$local_binary" ]]; then
  [[ -x "$local_binary" ]] || die "local binary is not executable: $local_binary"
  install -m 0755 "$local_binary" "$drag_binary"
else
  curl --proto '=https' --tlsv1.2 -fL \
    "https://github.com/$PROJECT_REPOSITORY/releases/download/$PROJECT_VERSION/$DRAG_ASSET" \
    -o "$drag_binary"
fi
printf '%s  %s\n' "$DRAG_SHA256" "$drag_binary" | sha256sum --check --status \
  || die "drag engine checksum verification failed"

log "Downloading the GNOME-compatible gesture extension"
extension_info="$temp_dir/extension-info.json"
extension_zip="$temp_dir/$EXTENSION_UUID.zip"
curl --proto '=https' --tlsv1.2 -fsSL \
  "https://extensions.gnome.org/extension-info/?uuid=$EXTENSION_UUID&shell_version=$gnome_major" \
  -o "$extension_info"
extension_path="$(python3 - "$extension_info" <<'PY'
import json, sys
with open(sys.argv[1], encoding="utf-8") as handle:
    print(json.load(handle)["download_url"])
PY
)"
[[ "$extension_path" == /download-extension/* ]] || die "unexpected GNOME extension download URL"
curl --proto '=https' --tlsv1.2 -fL "https://extensions.gnome.org$extension_path" -o "$extension_zip"
python3 - "$extension_zip" "$EXTENSION_UUID" <<'PY'
import json, sys, zipfile
with zipfile.ZipFile(sys.argv[1]) as archive:
    metadata = json.loads(archive.read("metadata.json"))
if metadata.get("uuid") != sys.argv[2]:
    raise SystemExit("extension UUID mismatch")
PY

log "Requesting administrator authorization for two fixed system files"
sudo -v
sudo install -o root -g root -m 0755 "$drag_binary" /usr/local/bin/linux-3-finger-drag
sudo install -o root -g root -m 0644 \
  "$script_dir/assets/69-mac-like-touchpad.rules" \
  /etc/udev/rules.d/69-mac-like-touchpad.rules
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=input --action=change
sudo udevadm trigger --subsystem-match=misc --action=change

log "Installing the user service and default profile"
install -d "$HOME/.config/linux-3-finger-drag" "$HOME/.config/systemd/user"
if [[ ! -f "$HOME/.config/linux-3-finger-drag/3fd-config.json" ]]; then
  install -m 0644 "$script_dir/assets/3fd-config.json" \
    "$HOME/.config/linux-3-finger-drag/3fd-config.json"
else
  warn "preserving existing three-finger-drag configuration"
fi
install -m 0644 "$script_dir/assets/three-finger-drag.service" \
  "$HOME/.config/systemd/user/three-finger-drag.service"

log "Installing and configuring four-finger gestures"
gnome-extensions install --force "$extension_zip"
extension_dir="$HOME/.local/share/gnome-shell/extensions/$EXTENSION_UUID"
schema_dir="$extension_dir/schemas"
[[ -f "$schema_dir/gschemas.compiled" ]] || die "extension schema was not installed"

GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization horizontal-swipe-3-fingers-gesture 'NONE'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization vertical-swipe-3-fingers-gesture 'NONE'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization pinch-3-finger-gesture 'NONE'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization horizontal-swipe-4-fingers-gesture 'WORKSPACE_SWITCHING'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization vertical-swipe-4-fingers-gesture 'OVERVIEW_NAVIGATION'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization pinch-4-finger-gesture 'SHOW_DESKTOP'
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization follow-natural-scroll true
GSETTINGS_SCHEMA_DIR="$schema_dir" gsettings set org.gnome.shell.extensions.touchpad-gesture-customization touchpad-speed-scale 1.0

python3 - "$EXTENSION_UUID" <<'PY'
import ast, subprocess, sys
uuid = sys.argv[1]
raw = subprocess.check_output(
    ["gsettings", "get", "org.gnome.shell", "enabled-extensions"], text=True
).strip()
extensions = ast.literal_eval(raw)
if uuid not in extensions:
    extensions.append(uuid)
subprocess.check_call(
    ["gsettings", "set", "org.gnome.shell", "enabled-extensions", repr(extensions)]
)
PY

log "Applying the Mac-like touchpad baseline"
gsettings set org.gnome.desktop.peripherals.touchpad send-events 'enabled'
gsettings set org.gnome.desktop.peripherals.touchpad accel-profile 'adaptive'
gsettings set org.gnome.desktop.peripherals.touchpad speed 0.35
gsettings set org.gnome.desktop.peripherals.touchpad natural-scroll true
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag-lock false
gsettings set org.gnome.desktop.peripherals.touchpad click-method 'fingers'
gsettings set org.gnome.desktop.peripherals.touchpad tap-button-map 'lrm'
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
gsettings set org.gnome.desktop.peripherals.touchpad disable-while-typing true

if [[ -f /usr/share/wayland-sessions/ubuntu-wayland.desktop ]]; then
  gdbus call --system \
    --dest org.freedesktop.Accounts \
    --object-path "/org/freedesktop/Accounts/User$(id -u)" \
    --method org.freedesktop.Accounts.User.SetXSession ubuntu-wayland >/dev/null \
    || warn "could not make Ubuntu on Wayland the next login session"
fi

log "Enabling the three-finger drag service"
systemctl --user daemon-reload
systemctl --user enable --now three-finger-drag.service
sleep 1
if ! systemctl --user is-active --quiet three-finger-drag.service; then
  journalctl --user -u three-finger-drag.service -n 40 --no-pager >&2
  die "the service did not start; run ./status.sh for diagnostics"
fi

cat <<'EOF'

Installed successfully.

  Three fingers: drag windows, files, and text selections
  Four fingers left/right: switch workspaces
  Four fingers up/down: open or leave Overview
  Four-finger pinch: show the desktop

Log out and back in to load the Wayland extension. Run ./status.sh to verify.
EOF
