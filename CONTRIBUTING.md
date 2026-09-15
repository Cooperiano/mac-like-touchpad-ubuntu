# Contributing

Bug reports should include:

- distribution and version;
- GNOME version;
- X11 or Wayland session;
- touchpad name from `/proc/bus/input/devices`;
- output from `./status.sh`;
- recent service logs, with private paths or usernames removed.

Before opening a pull request:

```bash
bash -n install.sh status.sh uninstall.sh
shellcheck install.sh status.sh uninstall.sh
python3 -m json.tool assets/3fd-config.json >/dev/null
```

Changes to the pinned drag engine must update all of the following together:

1. `DRAG_UPSTREAM_COMMIT` in `install.sh`;
2. `UPSTREAM_COMMIT` in `.github/workflows/release.yml`;
3. the binary SHA-256 in `install.sh`;
4. `THIRD_PARTY_NOTICES.md` when licensing or attribution changes.

Do not commit binaries, credentials, raw logs, usernames, or absolute home-directory paths.
