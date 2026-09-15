# Security model

This project sits on the input path, so its permissions deserve more scrutiny than ordinary desktop
configuration.

## Privileged changes

`install.sh` requests administrator authorization to install only:

- `/usr/local/bin/linux-3-finger-drag`
- `/etc/udev/rules.d/69-mac-like-touchpad.rules`

The long-running service runs as the logged-in user. It is not setuid and does not run as root.

## Device access

The udev rule grants `uaccess` to devices that systemd identifies as touchpads and to `/dev/uinput`.
It deliberately does not add the user to the `input` group, which could expose keyboard and other raw
input events.

## Downloads

- The drag engine is pinned to upstream commit
  `ae22defe47156e13476f08dce6cd98e5aaa49227`. The release binary is checked against a SHA-256 value
  embedded in the installer. Release builds also pin Rust 1.98.1 and remap build paths so the binary
  is reproducible without leaking the builder's home directory.
- The GNOME extension is downloaded over HTTPS from `extensions.gnome.org` for the detected GNOME
  version. Its embedded UUID must match the expected project UUID.

## Recovery

The drag engine exclusively grabs the physical touchpad while running. If input behaves incorrectly,
use the keyboard to stop it:

```bash
systemctl --user stop three-finger-drag.service
```

The kernel releases the device when the process exits. The service uses `Restart=on-failure`; to keep
it stopped, disable it as well:

```bash
systemctl --user disable --now three-finger-drag.service
```

## Reporting vulnerabilities

Open a GitHub security advisory for this repository instead of publishing a vulnerability as a public
issue. For vulnerabilities in a third-party component, also contact its upstream maintainer.
