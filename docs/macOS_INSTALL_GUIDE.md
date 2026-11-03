# macOS 安装指南

适用于从 DMG 安装 ClickMate。从源码编译请看 [构建指南](BUILD_GUIDE.md)。

系统要求：macOS 12.0 或更高。Apple 芯片和 Intel 都可以。

## 安装

1. 下载 `ClickMate_vX.X.X_macOS.dmg`。
2. 打开 DMG。
3. 把 ClickMate 拖入「应用程序」。
4. 从「应用程序」或启动台打开。

第一次打开会要求辅助功能权限。没有这项权限时，应用无法点击、移动鼠标或注册全局快捷键。

## 提示「已损坏，无法打开」

这是 Gatekeeper 给未签名下载文件加的隔离标记，不是包本身损坏。

在「终端」执行：

```bash
xattr -cr /Applications/ClickMate.app
```

应用还在「下载」里时：

```bash
xattr -cr ~/Downloads/ClickMate.app
```

然后重新打开。只在信任下载来源时去掉隔离标记。

也可以先尝试打开一次，再在设置里选择仍要打开：

- macOS 13 及以上：系统设置 → 隐私与安全性 → 仍要打开
- macOS 12：系统偏好设置 → 安全性与隐私 → 通用 → 仍要打开

## 提示「来自身份不明的开发者」

在 Finder 中按住 Control 点 ClickMate，选择「打开」，再在对话框里确认「打开」。只需做一次。

或者：

```bash
xattr -cr /Applications/ClickMate.app
open /Applications/ClickMate.app
```

## 辅助功能权限

- macOS 13 及以上：系统设置 → 隐私与安全性 → 辅助功能
- macOS 12：系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能

点锁图标解锁，加入 ClickMate 并勾选，然后完全退出再打开应用。只授权不重启时，快捷键可能仍然无效。

如果列表里有旧的 ClickMate 条目，先删掉再重新添加。从不同路径启动会变成不同的授权对象。

## 为什么会这样

当前公开发布的包没有使用 Apple Developer ID 签名和公证。macOS 会默认拦截从互联网下载的未签名应用。`xattr -cr` 只去掉隔离标记，不关闭系统完整性保护。

鼠标控制和全局快捷键必须使用辅助功能。应用未启用 App Sandbox，否则无法做这两件事。

## 从源码运行

```bash
git clone https://github.com/zhaibin/ClickMate.git
cd ClickMate
bash scripts/build_dmg.sh
open releases/v*/ClickMate_v*_macOS.dmg
```

开发调试也可以 `flutter run -d macos`。那需要先按构建指南编译 `libmouse_controller.dylib`。这种方式不会出现下载隔离标记，但辅助功能权限仍然需要。

## 还有问题

看 [README](../README.md) 的常见问题。构建失败看 [构建指南](BUILD_GUIDE.md)。其余情况到 GitHub 仓库提 issue。
