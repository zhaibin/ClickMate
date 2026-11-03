# ClickMate

<div align="center">

![ClickMate Logo](assets/icons/icon_128.png)

**Cross-Platform Mouse Auto Clicker**

智能鼠标自动点击工具，支持 Windows 和 macOS。

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-blue.svg)](#-平台支持)
[![Version](https://img.shields.io/badge/Version-2.2.2-green.svg)](#-版本)
[![Languages](https://img.shields.io/badge/Languages-11-orange.svg)](#-多语言支持)
[![License](https://img.shields.io/badge/License-Personal%20Use-lightgrey.svg)](#-许可证)

[使用说明](#-使用说明) · [构建](docs/BUILD_GUIDE.md) · [打包](docs/打包发布指南.md) · [多语言](docs/MULTILINGUAL_GUIDE.md) · [macOS 安装](docs/macOS_INSTALL_GUIDE.md)

</div>

---

## 主要功能

- 自动点击左键、右键或中键，间隔至少 10 毫秒
- 自动跟踪鼠标，或锁定手动输入的坐标
- 全局快捷键。默认 Windows 为 `Ctrl+Shift+1/2`，macOS 为 `⌘+Shift+1/2`；可改为 Ctrl、Alt、Shift 或无修饰键，也支持 F1–F12
- 最近 10 次点击记录，时间精确到毫秒
- 随机间隔和随机位置偏移
- 多份命名配置，重启后恢复上次界面
- 鼠标自动移到目标位置
- 偏离目标区域时暂停，静止约 5 秒后回到目标并继续
- 启动后检查 GitHub Releases，可下载并安装更新
- 11 种界面语言，首次启动跟随系统语言

## 平台支持

| 平台 | 状态 | 最低版本 |
|------|------|----------|
| Windows | 完整支持 | Windows 10 1809+ |
| macOS | 完整支持 | macOS 12.0+ |
| Linux | 未支持 | — |

macOS 最低版本以工程配置为准：`macos/Podfile` 与 `MACOSX_DEPLOYMENT_TARGET` 均为 12.0。

## 快速开始

### Windows

```bat
START.bat
```

调试输出用 `scripts\run_debug.bat`。快捷键注册失败时，再用 `scripts\run_as_admin.bat`。

### macOS

开发运行：

```bash
flutter pub get
clang++ -shared -fPIC -framework Cocoa -framework Carbon -framework CoreGraphics \
  -o libmouse_controller.dylib native/src/mouse_controller_macos.mm
flutter run -d macos
```

可分发的应用和 DMG 用 `bash scripts/build_dmg.sh`。只执行 `flutter build macos --release` 不会把 `libmouse_controller.dylib` 放进 app bundle。

首次运行需要在辅助功能中授权 ClickMate。从网络下载的未签名包若提示已损坏，按 [macOS 安装指南](docs/macOS_INSTALL_GUIDE.md) 处理。

## 使用说明

### 自动跟踪（默认）

启动后跟随当前鼠标位置。按开始/停止快捷键开始点击，再按一次停止。启动后会短暂忽略快捷键，避免残留按键误触发。

### 手动坐标

点击 X 或 Y 输入框进入手动模式，填写坐标后可用「移动」按钮核对位置。加载命名配置时会切到手动模式。

### 配置

标题栏菜单 →「管理配置」可保存、加载、重命名和删除配置。参数修改会写入会话设置，下次启动恢复。

### 快捷键

| 功能 | 默认 Windows | 默认 macOS |
|------|----------------|------------|
| 开始/停止 | `Ctrl+Shift+1` | `⌘+Shift+1` |
| 捕获坐标 | `Ctrl+Shift+2` | `⌘+Shift+2` |

在「快捷键设置」中可改主键和修饰键。macOS 上界面里的 Ctrl 对应 Command。注册失败时，先检查是否被其他软件占用，以及原生库是否加载成功。

### 点击历史

窗口底部保留最近 10 次：序号、`HH:MM:SS.mmm`、坐标、按键（左键蓝、右键橙、中键紫）。

### 自动暂停 / 恢复

勾选后，鼠标偏离目标超过阈值会暂停。默认阈值 100 像素，最小 10 像素。鼠标在任意位置静止约 5 秒后，会移回目标并继续点击。

### 自动更新

启动约 3 秒后对照 GitHub Releases。也可以从标题栏菜单手动检查。比较的是 `lib/version.dart` 里的 `appVersion` 和最新 Release tag。Windows 优先下载文件名含 `setup` 或 `installer` 的 `.exe`，否则用其他 `.exe`，再退回 `.zip`。macOS 下载 `.dmg`。

## 多语言支持

首次启动读取系统语言。简体与繁体按地区区分：`TW`、`HK`、`MO` 为繁体，其余中文为简体。不支持的语言使用英语。

| 语言 | 代码 |
|------|------|
| English | `en` |
| 简体中文 | `zh_CN` |
| 繁體中文 | `zh_TW` |
| Français | `fr` |
| Español | `es` |
| Português | `pt` |
| Deutsch | `de` |
| Русский | `ru` |
| Italiano | `it` |
| 日本語 | `ja` |
| 한국어 | `ko` |

在标题栏菜单中切换，选择会立刻保存。翻译维护见 [多语言指南](docs/MULTILINGUAL_GUIDE.md)。

## 打包发布

版本号以根目录 `VERSION` 为准，并与 `lib/version.dart`、`pubspec.yaml` 保持一致。当前为 **2.2.2**。

```bat
scripts\build_release.bat
```

```bash
bash scripts/build_dmg.sh
```

输出：

- `releases/v2.2.2/ClickMate_v2.2.2_Portable.zip`
- `releases/v2.2.2/ClickMate_v2.2.2_macOS.dmg`

Windows 安装包需另用 Inno Setup，自动更新会优先选择安装程序。步骤见 [打包发布指南](docs/打包发布指南.md)。

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter，Dart SDK `^3.10.0` |
| Windows 原生 | C++ / Win32 |
| macOS 原生 | Objective-C++ / CoreGraphics / Carbon |
| 窗口 | window_manager 0.5.1，固定 400×720 |
| 原生调用 | dart:ffi |
| 点击配置 | shared_preferences |
| 更新 | http + GitHub Releases API |

## 项目结构

```
ClickMate/
├── START.bat
├── VERSION
├── README.md
├── CHANGELOG.md
├── lib/                         # Flutter 源码
│   ├── main.dart
│   ├── version.dart
│   ├── mouse_controller_service.dart
│   ├── mouse_controller_bindings.dart
│   ├── click_config.dart
│   ├── upgrade_service.dart
│   ├── logger_service.dart
│   ├── language_preference.dart
│   └── l10n/app_localizations.dart
├── native/src/                  # mouse_controller.dll / .dylib / 源码
├── windows/
├── macos/
├── scripts/
│   ├── build_release.bat        # Windows 便携版
│   ├── build_dmg.sh             # macOS DMG
│   ├── START.bat
│   ├── quick_start.bat
│   ├── run_debug.bat
│   ├── run_as_admin.bat
│   ├── diagnose.bat
│   ├── test_hotkey.bat
│   ├── sign_release.bat
│   └── generate_icons.py
├── docs/
│   ├── BUILD_GUIDE.md
│   ├── 打包发布指南.md
│   ├── MULTILINGUAL_GUIDE.md
│   └── macOS_INSTALL_GUIDE.md
└── assets/icons/
```

仓库里的 `logs/` 不是运行时日志目录。

## 开发与数据位置

```bat
scripts\diagnose.bat
scripts\test_hotkey.bat
```

| 数据 | Windows | macOS |
|------|---------|-------|
| 命名配置、会话、快捷键 | `%APPDATA%\xants\ClickMate\shared_preferences.json` | 应用 UserDefaults（`com.xants.clickmate`） |
| 语言 | `%USERPROFILE%\Documents\ClickMate\language.txt` | `~/Documents/ClickMate/language.txt` |
| 日志 | `%USERPROFILE%\Documents\ClickMate\logs\` | `~/Documents/ClickMate/logs/` |

日志文件按日期命名（`app_YYYYMMDD.log`），文件日志只记录警告和错误，并保留约 7 天。旧的 `Documents\MouseControl` 会在启动时迁移到 `ClickMate`。

## 注意事项

**Windows**

1. 默认快捷键不强制管理员权限。注册失败时再尝试管理员身份运行，并检查快捷键冲突和 `mouse_controller.dll`。
2. 开发时 DLL 位于 `native/src/`。便携版中 DLL 与 `clickmate.exe` 同目录。
3. 目标系统需要 Visual C++ 2022 运行库。

**macOS**

1. 需要辅助功能权限，授权后重启应用。
2. 分发必须使用 `scripts/build_dmg.sh`，以便把动态库放进 `Contents/Frameworks/`。
3. 未签名包会被 Gatekeeper 拦截。见 [macOS 安装指南](docs/macOS_INSTALL_GUIDE.md)。

请勿在禁止自动化操作的游戏或应用中使用。本工具仅供学习和个人使用。

## 常见问题

**快捷键没有反应**

- Windows：运行 `scripts\diagnose.bat`，查看是否出现热键注册成功的日志。排除占用后再试管理员运行。
- macOS：确认辅助功能已勾选 ClickMate，然后重启应用。
- 刚启动的一瞬间快捷键会被忽略，这是为了丢掉残留按键。

**找不到原生库**

Windows 确认 `native/src/mouse_controller.dll` 存在。macOS 按上面的 `clang++` 命令编译到项目根目录，供 `flutter run -d macos` 加载；发布包则依赖 `build_dmg.sh`。

**停止后仍点了一下**

2.2.2 已阻止停止之后仍执行已排队的延迟点击。若仍出现，请确认运行的是该版本或更新的构建。

## 版本

当前版本 **v2.2.2**。版本记录见 [CHANGELOG.md](CHANGELOG.md)。

发版时同时更新 `VERSION`、`lib/version.dart`、`pubspec.yaml`、`CHANGELOG.md` 和本文件的版本标记。

## 许可证

仅供学习和个人使用。

仓库：https://github.com/zhaibin/ClickMate  
网站：https://clickmate.xants.net
