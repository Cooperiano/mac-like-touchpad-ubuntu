# Mac-like Touchpad for Ubuntu and Windows

[简体中文](README.zh-CN.md) · [Zhihu article draft](docs/zhihu-article.md)

A focused, auditable setup for the touchpad behaviors many macOS users miss on Ubuntu and Windows.

| Platform | Three-finger drag | Four-finger desktops | Install |
|---|---|---|---|
| Ubuntu GNOME Wayland | Continuous, system-wide | Animated, system-native | `./install.sh` |
| Windows Precision Touchpad (beta) | Tap-tap-drag fallback | System-native | `.\windows\install.ps1` |

See the [Windows guide](windows/README.md) for the reversible Windows 10/11 optimization profile
and the technical reason a normal background app cannot safely provide global three-finger drag.

## Ubuntu

The Ubuntu setup covers the two gestures many macOS users miss most:

- three fingers drag windows, files, and text selections;
- four fingers switch workspaces, navigate Overview, and reveal the desktop.

The setup targets Ubuntu 24.04 with GNOME 45–48 on Wayland. It uses
[`linux-3-finger-drag`](https://github.com/lmr97/linux-3-finger-drag) for the drag engine and
[`Touchpad Gesture Customization`](https://github.com/HieuTNg/touchpad-gesture-customization)
for animated four-finger GNOME gestures.

## Gesture map

| Gesture | Action |
|---|---|
| Three-finger move | Drag the item under the pointer |
| Four-finger swipe left/right | Switch workspaces |
| Four-finger swipe up/down | Enter or leave Overview |
| Four-finger pinch | Show the desktop |
| Two-finger scroll | Natural scrolling |
| Two-finger click/tap | Secondary click |

Three-finger GNOME navigation is deliberately disabled so it cannot conflict with dragging.

## Why this is a combination

GNOME Wayland provides smooth compositor-driven gestures, but Ubuntu 24.04 ships libinput 1.25,
which predates native three-finger drag. The drag engine therefore sits below the desktop:

```text
physical touchpad
       │
       ▼
linux-3-finger-drag
       ├── synthetic touchpad ──► GNOME/libinput (1, 2 and 4 fingers)
       └── virtual mouse ────────► left-button drag (3 fingers)
```

Stopping the user service immediately releases the physical touchpad.

## Install

Review the scripts, then run:

```bash
git clone https://github.com/Cooperiano/mac-like-touchpad-ubuntu.git
cd mac-like-touchpad-ubuntu
./install.sh
```

The installer asks for administrator authorization once to place exactly two system files:

- `/usr/local/bin/linux-3-finger-drag`
- `/etc/udev/rules.d/69-mac-like-touchpad.rules`

It does **not** add your account to the broad `input` group. The udev rule grants the active
desktop user access only to devices identified as touchpads and to `/dev/uinput`.

Log out and back in after installation. On Ubuntu, the installer selects `Ubuntu on Wayland`
for the next login when that session is available.

## Verify

```bash
./status.sh
```

For service logs:

```bash
journalctl --user -u three-finger-drag.service -e
```

Emergency stop, using the keyboard if necessary:

```bash
systemctl --user stop three-finger-drag.service
```

The touchpad is returned to the desktop as soon as the process stops.

## Tune dragging

Edit `~/.config/linux-3-finger-drag/3fd-config.json`:

```json
{
  "acceleration": 1.0,
  "dragEndDelay": 0,
  "entryDebounce": 50,
  "probeDelay": 15,
  "pressGrace": 75
}
```

- Raise `acceleration` if dragging feels slow.
- Set `dragEndDelay` to a small number of milliseconds to allow lifting and repositioning three
  fingers before the drag is released.
- Keep `entryDebounce` and `pressGrace` at their defaults unless three- and four-finger gestures
  are being misclassified.

The configuration is hot-reloaded except for logging options.

## Uninstall

```bash
./uninstall.sh
```

Uninstalling removes the runtime, service, udev rule, and GNOME extension. It preserves the drag
configuration, touchpad preferences, and selected login session.

## Compatibility and limits

- Tested design: Ubuntu 24.04, GNOME 46, Wayland, ELAN I²C-HID touchpad, hybrid Intel/NVIDIA GPU.
- Release `v0.2.0` provides an x86-64 drag-engine binary and the Windows profile scripts.
- GNOME 45–48 is supported by the installer. Other desktops and GNOME releases are not yet tested.
- This cannot reproduce Apple's haptic click, Force Touch hardware, or exact pointer acceleration.
- Some legacy screen-capture, remote-control, automation, and global-hotkey tools behave
  differently on Wayland. X11 remains selectable from the login screen.

## Supply chain and attribution

The drag binary in release `v0.2.0` is built from upstream commit
`ae22defe47156e13476f08dce6cd98e5aaa49227` and checked against a SHA-256 value embedded in the
installer. The GNOME extension is downloaded from `extensions.gnome.org` for the detected GNOME
version and its UUID is verified before installation.

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and [SECURITY.md](SECURITY.md).

## License

The orchestration scripts and documentation in this repository are MIT licensed. Third-party
components retain their original licenses.
