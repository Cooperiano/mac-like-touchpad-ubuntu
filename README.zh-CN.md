# 在 Ubuntu 和 Windows 上实现接近 Mac 的触控板操作

[English](README.md) · [知乎文章稿](docs/zhihu-article.md)

这是一套可审计、可恢复的 Ubuntu / Windows 触控板方案。

| 平台 | 三指拖动 | 四指桌面手势 | 安装 |
|---|---|---|---|
| Ubuntu GNOME Wayland | 全局连续拖动 | 原生动画 | `./install.sh` |
| Windows 精确式触摸板（Beta） | 轻触—轻触拖动替代 | 系统原生 | `.\windows\install.ps1` |

Windows 10 / 11 的可恢复优化配置、安装方法和三指拖动的系统限制，见
[Windows 中文说明](windows/README.zh-CN.md)。

## Ubuntu

Ubuntu GNOME 的完整组合方案解决两个最明显的体验缺口：

- 三指直接拖动窗口、文件和选中文字；
- 四指切换工作区、进入总览和显示桌面。

方案面向 Ubuntu 24.04、GNOME 45–48 和 Wayland。三指拖动由
[`linux-3-finger-drag`](https://github.com/lmr97/linux-3-finger-drag) 完成；四指动画手势由
[`Touchpad Gesture Customization`](https://github.com/HieuTNg/touchpad-gesture-customization)
完成。

## 手势表

| 手势 | 动作 |
|---|---|
| 三指移动 | 拖动光标下的窗口、文件或选区 |
| 四指左右滑动 | 切换工作区 |
| 四指上下滑动 | 进入或退出 GNOME 总览 |
| 四指捏合 | 显示桌面 |
| 双指滚动 | 自然滚动 |
| 双指点击/轻触 | 右键 |

三指 GNOME 导航会被主动关闭，避免与三指拖动争抢同一个手势。

## 工作原理

GNOME Wayland 能提供跟手的工作区动画，但 Ubuntu 24.04 自带的 libinput 1.25 尚无原生
三指拖动。因此拖动层工作在桌面系统下面：

```text
真实触控板
    │
    ▼
linux-3-finger-drag
    ├── 虚拟触控板 ──► GNOME/libinput（一指、双指和四指）
    └── 虚拟鼠标 ────► 三指转换成按住左键并移动
```

服务一旦停止，真实触控板会立即被释放。

## 安装

建议先阅读脚本，再执行：

```bash
git clone https://github.com/Cooperiano/mac-like-touchpad-ubuntu.git
cd mac-like-touchpad-ubuntu
./install.sh
```

安装时只会请求一次管理员授权，用于写入两个固定的系统文件：

- `/usr/local/bin/linux-3-finger-drag`
- `/etc/udev/rules.d/69-mac-like-touchpad.rules`

安装器不会把账号加入可以读取所有键盘输入的 `input` 组。udev 规则只向当前桌面用户授权
触控板和 `/dev/uinput`。

安装后注销并重新登录。若系统提供 `Ubuntu on Wayland`，安装器会把它设为下一次默认会话。

## 检查状态

```bash
./status.sh
```

查看服务日志：

```bash
journalctl --user -u three-finger-drag.service -e
```

如果触控板出现异常，可直接用键盘停止服务：

```bash
systemctl --user stop three-finger-drag.service
```

## 调整三指拖动

配置文件位于 `~/.config/linux-3-finger-drag/3fd-config.json`：

```json
{
  "acceleration": 1.0,
  "dragEndDelay": 0,
  "entryDebounce": 50,
  "probeDelay": 15,
  "pressGrace": 75
}
```

- 拖动太慢：适当提高 `acceleration`。
- 希望抬起三指后还能重新落下继续拖：给 `dragEndDelay` 设置一个较小的毫秒数。
- 除非三指和四指经常识别错误，否则建议保留其他默认阈值。

除日志选项外，修改后会自动热加载。

## 卸载

```bash
./uninstall.sh
```

卸载会移除运行程序、用户服务、udev 规则和 GNOME 扩展，但保留拖动参数、触控板偏好以及
当前选择的登录会话。

## 兼容性与边界

- 方案设计已在 Ubuntu 24.04、GNOME 46、Wayland、ELAN I²C-HID 触控板和 Intel/NVIDIA
  混合显卡环境中验证。
- `v0.2.0` 提供 x86-64 拖动程序和 Windows 优化脚本。
- 安装器支持 GNOME 45–48；其他桌面和 GNOME 版本尚未验证。
- 无法复制苹果触控板的线性马达、压力感应和完全相同的指针加速曲线。
- 某些老式录屏、远控、桌面自动化和全局快捷键工具在 Wayland 下行为不同；登录界面仍可
  随时切回 X11。

## 供应链与权限

`v0.2.0` 的拖动程序固定来自上游提交
`ae22defe47156e13476f08dce6cd98e5aaa49227`，安装器会用内置 SHA-256 校验二进制。GNOME
扩展按当前 GNOME 版本从 `extensions.gnome.org` 下载，并校验扩展 UUID。

第三方许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)，安全边界见
[SECURITY.md](SECURITY.md)。
