# ClickMate

<div align="center">

![ClickMate Logo](assets/icons/icon_128.png)

**Cross-Platform Mouse Auto Clicker**

智能鼠标自动点击工具，支持 Windows 和 macOS 双平台

[![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS-blue.svg)](#)
[![Version](https://img.shields.io/badge/Version-2.2.2-green.svg)](#)
[![Languages](https://img.shields.io/badge/Languages-11-orange.svg)](#-多语言支持)
[![License](https://img.shields.io/badge/License-Personal%20Use-lightgrey.svg)](#)

[主要功能](#-主要功能) | [构建指南](docs/BUILD_GUIDE.md) | [打包指南](docs/打包发布指南.md)

</div>

---

## ✨ 主要功能

- 🖱️ **自动鼠标点击** - 支持左键/右键/中键
- 🎯 **双模式切换** - 自动跟踪模式 & 手动输入模式
- ⌨️ **全局快捷键** - Windows 使用 Ctrl+Shift+1/2，macOS 使用 ⌘+Shift+1/2
- 📊 **点击历史** - 记录最近10次点击（毫秒精度）
- 🎲 **智能随机** - 随机间隔和位置偏移
- 💾 **配置管理** - 保存/加载/管理多个配置
- 🔄 **智能移动** - 鼠标自动定位到目标位置
- 🛡️ **智能暂停/恢复** - 偏离目标区域时暂停，静止后自动回到目标继续
- 📥 **自动更新** - 启动后检查 GitHub Releases，支持下载安装更新
- 🌍 **多语言支持** - 11种语言，自动检测系统语言
- 🎨 **现代界面** - 无边框窗口，自定义标题栏

---

## 🖥️ 平台支持

| 平台 | 状态 | 最低版本 |
|------|------|----------|
| **Windows** | ✅ 完整支持 | Windows 10 1809+ |
| **macOS** | ✅ 完整支持 | macOS 10.15+ |
| Linux | 🚧 计划中 | - |

---

## 🚀 快速开始

### Windows

**方式1：直接启动（推荐）**
```bash
START.bat
```

**方式2：调试模式**
```bash
scripts\run_debug.bat
```

**方式3：管理员模式（快捷键注册受限时）**
```bash
scripts\run_as_admin.bat
```

### macOS

**方式1：命令行启动**
```bash
flutter run -d macos
```

**方式2：编译后运行**
```bash
bash scripts/build_dmg.sh
open build/macos/Build/Products/Release/ClickMate.app
```

> `scripts/build_dmg.sh` 会构建 Release app 并把 `libmouse_controller.dylib` 复制到 app bundle。仅执行 `flutter build macos --release` 适合本地构建验证，但发布或直接打开 `.app` 时可能缺少动态库。

> ⚠️ **macOS 权限提示**：首次运行需要在「系统偏好设置 → 安全性与隐私 → 辅助功能」中授权应用程序。

> 📥 **下载安装包后显示"已损坏"？** 查看 [macOS 安装指南](docs/macOS_INSTALL_GUIDE.md) 了解解决方案。

---

## 📖 使用说明

### 自动跟踪模式（默认）

1. 启动应用后自动开启
2. 实时跟随鼠标位置
3. 按 `Ctrl+Shift+1` (Windows) 或 `⌘+Shift+1` (macOS) 开始点击
4. 再次按下停止

### 手动输入模式

1. 点击 X 或 Y 输入框切换到手动模式
2. 输入固定坐标
3. 点击「移动」按钮测试位置
4. 或点击 🔄 按钮切换模式

### 配置管理

1. 点击标题栏菜单 → 「管理配置」
2. 保存当前配置（自动或手动）
3. 加载配置时自动恢复所有参数
4. 支持重命名和删除配置
5. 重启应用自动加载上次配置

### 快捷键

| 功能 | Windows | macOS |
|------|---------|-------|
| 开始/停止点击 | `Ctrl+Shift+1` | `⌘+Shift+1` |
| 捕获鼠标位置 | `Ctrl+Shift+2` | `⌘+Shift+2` |

> 💡 Windows 下快捷键通过 `RegisterHotKey` 注册；如果注册失败，通常是快捷键冲突、权限限制或 DLL 未加载。可尝试以管理员身份运行。

### 点击历史

窗口底部显示最近10次点击：
- **序号** - 1-10
- **时间** - HH:MM:SS.mmm（毫秒精度）
- **位置** - (X, Y)
- **按键** - 左键(蓝)/右键(橙)/中键(紫)

### 智能暂停/恢复

启用「自动暂停/恢复」后，应用会监控鼠标是否偏离目标区域：

1. 偏离目标超过阈值时自动暂停点击
2. 鼠标在任意位置静止 5 秒后，自动移动回目标位置
3. 回到目标后继续点击，减少多任务切换时的误触

偏离阈值可在主界面设置，默认值为 100px。

### 自动更新

应用启动约 3 秒后会检查 GitHub Releases 最新版本，也可以通过标题栏菜单手动「检查更新」。更新逻辑使用 `lib/version.dart` 中的 `appVersion` 与最新 Release tag 比较。

---

## 🌍 多语言支持

支持11种语言，首次启动自动检测系统语言：

| 语言 | Language |
|------|----------|
| 🇺🇸 English | 英语 |
| 🇨🇳 简体中文 | Simplified Chinese |
| 🇹🇼 繁體中文 | Traditional Chinese |
| 🇫🇷 Français | 法语 |
| 🇪🇸 Español | 西班牙语 |
| 🇵🇹 Português | 葡萄牙语 |
| 🇩🇪 Deutsch | 德语 |
| 🇷🇺 Русский | 俄语 |
| 🇮🇹 Italiano | 意大利语 |
| 🇯🇵 日本語 | 日语 |
| 🇰🇷 한국어 | 韩语 |

点击标题栏菜单切换语言，选择自动保存。

---

## 📦 打包发布

### Windows

```bash
scripts\build_release.bat
```

自动完成：检查 DLL → 构建 Release → 创建便携版 → 打包 ZIP

输出文件：
- 便携版: `releases\v2.2.2\ClickMate_v2.2.2_Portable.zip`

> Windows 安装包需要额外使用 Inno Setup；自动更新会优先选择 Release 中包含 `setup` 或 `installer` 的 `.exe` 资源，其次选择普通 `.exe`，最后回退到 `.zip`。

### macOS

```bash
bash scripts/build_dmg.sh
```

输出：
- App: `build/macos/Build/Products/Release/ClickMate.app`
- DMG: `releases/v2.2.2/ClickMate_v2.2.2_macOS.dmg`

> 仅运行 `flutter build macos --release` 不会自动把 `libmouse_controller.dylib` 放入 app bundle。发布 DMG 请使用 `scripts/build_dmg.sh`。

---

## 🔧 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter（需包含 Dart SDK 3.10+；`pubspec.yaml` 要求 `^3.10.0`） |
| Windows 原生 | C++ / Windows API |
| macOS 原生 | Objective-C++ / CoreGraphics / Carbon |
| 窗口管理 | window_manager 0.5.1 |
| FFI | dart:ffi |
| 存储 | SharedPreferences |
| 文件路径 | path_provider |
| 网络更新 | http + GitHub Releases API |

---

## 📁 项目结构

```
ClickMate/
├── START.bat                    # Windows 快捷启动
├── README.md                    # 项目说明
├── CHANGELOG.md                 # 更新日志
├── VERSION                      # 版本号
│
├── lib/                         # Flutter 源码
│   ├── main.dart               # 主应用
│   ├── mouse_controller_service.dart
│   ├── mouse_controller_bindings.dart
│   ├── click_config.dart       # 配置模型
│   ├── config_management_dialog.dart
│   ├── language_preference.dart
│   ├── logger_service.dart
│   ├── upgrade_service.dart
│   ├── version.dart
│   └── l10n/
│       └── app_localizations.dart  # 多语言翻译
│
├── native/src/                  # 原生代码
│   ├── mouse_controller.cpp    # Windows 实现
│   ├── mouse_controller.h
│   ├── mouse_controller.dll    # Windows DLL
│   ├── mouse_controller_macos.mm  # macOS 实现
│   └── libmouse_controller.dylib  # macOS 动态库
│
├── windows/                     # Windows 平台配置
├── macos/                       # macOS 平台配置
│
├── scripts/                     # 构建脚本
│   ├── START.bat               # 主启动脚本
│   ├── quick_start.bat         # 智能启动
│   ├── run_debug.bat           # 调试模式
│   ├── run_as_admin.bat        # 管理员模式
│   ├── build_release.bat       # 发布打包
│   ├── diagnose.bat            # 诊断工具
│   └── test_hotkey.bat         # 快捷键测试
│
├── docs/                        # 文档
│   ├── BUILD_GUIDE.md          # 构建指南
│   ├── 打包发布指南.md          # 打包说明
│   └── MULTILINGUAL_GUIDE.md   # 多语言指南
│
├── assets/icons/                # 应用图标
└── logs/                        # 仓库内示例/旧日志；运行时日志写入用户 Documents/ClickMate/logs
```

---

## 🛠️ 开发调试

### 诊断工具 (Windows)
```bash
scripts\diagnose.bat
```
检查：DLL 文件、Flutter 环境、Windows 版本、管理员权限

### 快捷键测试 (Windows)
```bash
scripts\test_hotkey.bat
```
专门测试快捷键功能

### 日志位置

| 平台 | 路径 |
|------|------|
| Windows | `%USERPROFILE%\Documents\ClickMate\logs\` |
| macOS | `~/Documents/ClickMate/logs/` |

---

## ⚠️ 注意事项

### Windows
1. **快捷键注册** - 默认使用 `Ctrl+Shift+1/2`；如注册失败，可检查快捷键冲突或尝试管理员身份运行
2. **DLL 文件** - 确保 `mouse_controller.dll` 在 `native/src/` 目录
3. **快捷键冲突** - 如有冲突可在应用内更改

### macOS
1. **辅助功能权限** - 首次运行需授权「辅助功能」权限
2. **动态库** - 确保 `libmouse_controller.dylib` 已编译
3. **代码签名** - 发布版本需要签名才能正常运行

### 通用
- 请勿在禁止脚本的游戏或应用中使用
- 本工具仅供学习和个人使用

---

## 🐛 常见问题

### 快捷键不工作？

**Windows:**
- 运行 `scripts\diagnose.bat` 检查
- 查看控制台是否显示 `Hotkey ... Success`
- 如果提示快捷键被占用或权限受限，再尝试以管理员身份运行

**macOS:**
- 检查「系统偏好设置 → 安全性与隐私 → 辅助功能」是否授权
- 重启应用后重试

### 找不到原生库？

**Windows:**
```bash
scripts\diagnose.bat
# 确保 native/src/mouse_controller.dll 存在；脚本会复制到项目根目录供 flutter run/test 加载
```

**macOS:**
```bash
# 编译到项目根目录，供 flutter run -d macos 加载
clang++ -shared -fPIC -framework Cocoa -framework Carbon -framework CoreGraphics \
  -o libmouse_controller.dylib native/src/mouse_controller_macos.mm
```

### 打包后无法运行？

- 使用官方打包脚本
- 确保所有依赖文件在同一目录
- Windows 检查 VC++ 运行时

---

## 📊 版本信息

**当前版本**: v2.2.2

**版本来源**: `VERSION` 与 `lib/version.dart`

**支持系统**: Windows 10/11, macOS 10.15+

### v2.2.2 修复

- 🐛 修复停止自动点击后仍可能执行已排队延迟点击的问题
- ⌨️ 启动后短暂延迟响应快捷键，避免残留按键状态误触发开始/停止
- 📁 用户数据路径从旧 `MouseControl` 目录迁移到 `ClickMate` 目录
- 🧪 补充服务、配置、日志、语言、菜单、快捷键、升级等测试覆盖
- ✅ 完成 macOS 与 Windows 11 VM 的真实目标窗口自动点击验证

### v2.2.0 功能

- 🛡️ 智能自动暂停/恢复系统
- 📏 可配置偏离阈值
- 🌍 自动暂停/恢复相关文案覆盖 11 种语言

### v2.1.0 功能

- 📥 自动升级系统
- 🔎 启动后检查更新，支持手动检查
- 💾 下载进度展示和一键安装
- 🍎 修复 macOS DMG 分发时动态库加载问题

### v2.0.0 功能

- 🍎 macOS 支持
- 🎨 自定义标题栏
- 📦 Windows/macOS 分发打包
- 🚀 启动窗口优化

### v1.1.0 功能

- 💾 配置管理系统（保存/加载/管理多个配置）
- 🔄 智能鼠标移动
- ⚡ 恢复默认设置按钮
- 🎨 统一菜单设计

### v1.0.0 功能

- 🖱️ 自动鼠标点击
- 🎯 双模式切换
- ⌨️ 全局快捷键
- 📊 点击历史记录
- 🌍 11种语言支持

---

## 📄 许可证

本项目仅供学习和个人使用。

---

<div align="center">

**🎉 开始使用**

Windows: `START.bat` | macOS: `flutter run -d macos`

📖 [构建指南](docs/BUILD_GUIDE.md) | 📦 [打包指南](docs/打包发布指南.md) | 🌍 [多语言指南](docs/MULTILINGUAL_GUIDE.md)

**Repository**: https://github.com/zhaibin/ClickMate

</div>
