# Windows 精确式触摸板优化（Beta）

[English](README.md)

这套脚本适用于带有[精确式触摸板](https://learn.microsoft.com/zh-cn/windows-hardware/design/component-guidelines/windows-precision-touchpad-implementation-guide)的
Windows 10 / 11 笔记本。它只修改当前用户的微软公开配置，不需要管理员权限，并且可以完整恢复。

它会启用自然滚动、轻触点击、双指右键、轻触拖动、双指滚动和缩放，并调整触摸灵敏度；随后打开
Windows 触摸板设置，由你选择系统原生的四指桌面手势。

## 安装

在仓库根目录打开 PowerShell。无需永久修改系统的脚本执行策略：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\install.ps1
```

随后进入“高级手势”，把四指轻扫设为“切换桌面和显示桌面”。如果配置没有立刻生效，注销并
重新登录一次。

检查当前状态：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\status.ps1
```

恢复安装前的全部值：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\windows\uninstall.ps1
```

第一次安装会把原始值保存到
`%LOCALAPPDATA%\MacLikeTouchpad\precision-touchpad-backup.json`。重复安装不会覆盖这份原始备份；
卸载器只恢复本项目涉及的项目，完成后删除备份。

## 三指拖动的限制

这个 Windows 版本**不会声称已经实现全局三指拖动**。Windows 会把精确式触摸板触点交给系统
手势识别器；公开的
[`TouchpadGesturesController`](https://learn.microsoft.com/zh-cn/windows/win32/input-precisiontouchpad/touchpadgesturescontroller)
API 会忽略后台进程，而精确式触摸板的 HID 集合又被系统输入栈独占。普通后台工具因此无法安全地
复制 Ubuntu 版本的连续三指拖动。

当前可靠的替代是：轻触一次、抬起，再次轻触并拖动。真正的全局三指拖动需要针对硬件的签名输入
筛选驱动、Windows 硬件实验室工具包测试，以及多款触摸板的实机验证；这条路线会单独跟踪。

## 修改内容

脚本只修改
`HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\PrecisionTouchPad` 下微软有文档记录的 DWORD：

| 值 | 效果 |
|---|---|
| `AAPThreshold=1` | 在保留掌压抑制的同时提高响应性 |
| `LeaveOnWithMouse=1` | 外接鼠标时仍保留触摸板 |
| `PanEnabled=1` | 启用双指滚动 |
| `RightClickZoneEnabled=0` | 关闭右下角点击区 |
| `ScrollDirection=1` | 反转 Windows 默认方向，得到触屏式自然滚动 |
| `TapAndDrag=1` | 启用轻触—轻触拖动 |
| `TapsEnabled=1` | 启用单指轻触点击 |
| `TwoFingerTapEnabled=1` | 启用双指轻触右键 |
| `ZoomEnabled=1` | 启用双指缩放 |

值名和范围来自微软的
[精确式触摸板调优指南](https://learn.microsoft.com/zh-cn/windows-hardware/design/component-guidelines/touchpad-tuning-guidelines)。
脚本不会写入没有公开文档的三指或四指注册表项。
