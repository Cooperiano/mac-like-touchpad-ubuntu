# Windows Precision Touchpad profile (beta)

[简体中文](README.zh-CN.md)

This directory provides a reversible, no-admin optimization profile for Windows 10 and 11 laptops
with a [Precision Touchpad](https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/windows-precision-touchpad-implementation-guide).

It enables natural scrolling, tap-to-click, two-finger secondary click, tap-and-drag, pinch zoom,
and a more responsive palm-rejection threshold. It also opens the Windows Touchpad settings so the
supported four-finger desktop gestures can be selected.

## Install

Open PowerShell in the repository root. The default execution policy does not need to be changed:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install.ps1
```

Then open **Advanced gestures** and set four-finger swipes to **Switch desktops and show desktop**.
Sign out and back in if the changes do not take effect immediately.

Check the profile:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\status.ps1
```

Restore every value to its pre-install state:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\uninstall.ps1
```

The first installation stores the original values in
`%LOCALAPPDATA%\MacLikeTouchpad\precision-touchpad-backup.json`. Reinstalling does not overwrite
that original backup. The uninstaller restores only the named values and then removes the backup.

## Three-finger drag limitation

This Windows profile does **not** claim to provide system-wide three-finger drag. Windows sends
Precision Touchpad contacts to its own gesture recognizer. The public
[`TouchpadGesturesController`](https://learn.microsoft.com/en-us/windows/win32/input-precisiontouchpad/touchpadgesturescontroller)
API ignores controllers in background processes, while Precision Touchpad HID collections are
opened exclusively by the system input stack. A portable background utility therefore cannot
safely implement the Ubuntu drag engine's behavior.

The supported fallback is tap, lift, then tap-and-drag. A true system-wide implementation would
need a hardware-aware, signed input filter driver, Windows Hardware Lab Kit testing, and testing on
each supported touchpad. That is tracked separately from this safe user profile.

## Exactly what changes

All changes are documented DWORD values under
`HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PrecisionTouchPad`:

| Value | Setting |
|---|---|
| `AAPThreshold=1` | More responsive taps while retaining palm rejection |
| `LeaveOnWithMouse=1` | Keep the touchpad on when a mouse is connected |
| `PanEnabled=1` | Enable two-finger scrolling |
| `RightClickZoneEnabled=0` | Disable the bottom-right click zone |
| `ScrollDirection=1` | Reverse the Windows default for touch-style natural scrolling |
| `TapAndDrag=1` | Enable tap-tap-drag |
| `TapsEnabled=1` | Enable one-finger tap-to-click |
| `TwoFingerTapEnabled=1` | Enable two-finger secondary click |
| `ZoomEnabled=1` | Enable pinch zoom |

The value names and ranges come from Microsoft's
[Precision Touchpad tuning guidance](https://learn.microsoft.com/en-us/windows-hardware/design/component-guidelines/touchpad-tuning-guidelines).
No undocumented three- or four-finger registry values are modified.
