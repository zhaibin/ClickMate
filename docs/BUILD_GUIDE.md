# 构建指南

在 Windows 或 macOS 上从源码构建 ClickMate。用户安装已发布的包时，请看 [macOS 安装指南](macOS_INSTALL_GUIDE.md)，不必按本文编译。

当前版本：2.2.2。Dart SDK 约束见 `pubspec.yaml` 的 `^3.10.0`。

## 环境

1. 安装 [Flutter](https://flutter.dev/docs/get-started/install)，加入 PATH，并执行 `flutter doctor`。
2. 安装 [Git](https://git-scm.com/downloads)。
3. 在仓库根目录执行 `flutter pub get`。

## Windows

另外需要：

- CMake 3.14+
- Visual Studio 2019 或更新版本，勾选「使用 C++ 的桌面开发」。MinGW 可以编译 DLL，但 Flutter Windows 目标以 Visual Studio 为准。

### 脚本

```bat
scripts\quick_start.bat
scripts\build_release.bat
```

`quick_start.bat` 用于调试运行。`build_release.bat` 生成便携版，详见 [打包发布指南](打包发布指南.md)。

### 手动构建

```bat
flutter pub get

cd native
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
copy Release\mouse_controller.dll ..\src\

cd ..\..
flutter build windows --debug
flutter build windows --release
```

已有 `native\src\mouse_controller.dll` 时，可跳过 CMake，直接 `flutter run -d windows`。

调试程序在 `build\windows\x64\runner\Debug\clickmate.exe`，发布程序在同级的 `Release\`。Flutter 构建会带上 `flutter_windows.dll` 和插件 DLL。原生 DLL 以 `native\src\mouse_controller.dll` 为准，发布脚本会把它复制到便携版目录。

也可以在 `native\src` 里直接编译 DLL：

```bat
cl /LD mouse_controller.cpp /Fe:mouse_controller.dll user32.lib
```

```bat
g++ -shared -o mouse_controller.dll mouse_controller.cpp -luser32
```

## macOS

另外需要 Xcode 13 或更新版本（部署目标是 macOS 12.0），以及其中的 Clang。首次还需要：

```bash
xcode-select --install
cd macos && pod install && cd ..
```

### 开发运行

动态库要放在项目根目录，`flutter run` 才能加载：

```bash
clang++ -shared -fPIC \
  -framework Cocoa -framework Carbon -framework CoreGraphics \
  -o libmouse_controller.dylib \
  native/src/mouse_controller_macos.mm

flutter run -d macos
```

热重载只覆盖 Dart 界面。改了 `.mm` 之后需要重新编译动态库并重启应用。

### 发布构建

```bash
bash scripts/build_dmg.sh
```

脚本会清理构建、编译动态库、执行 `flutter build macos --release`，再把库复制到：

`ClickMate.app/Contents/Frameworks/libmouse_controller.dylib`

并把 install name 设为 `@executable_path/../Frameworks/libmouse_controller.dylib`。

只运行 `flutter build macos --release` 适合确认工程能编过，打给别人用的包必须走 `build_dmg.sh`。否则启动时报无法加载 `libmouse_controller.dylib`。

用 Xcode 打开 `macos/Runner.xcworkspace` 也可以编译，同样不会自动完成动态库打包。

产物：

```
build/macos/Build/Products/Release/ClickMate.app
releases/v<VERSION>/ClickMate_v<VERSION>_macOS.dmg
```

### 辅助功能

点击、移动鼠标和注册全局快捷键都需要辅助功能权限。

- macOS 13 及以上：系统设置 → 隐私与安全性 → 辅助功能
- macOS 12：系统偏好设置 → 安全性与隐私 → 隐私 → 辅助功能

加入 ClickMate 并勾选，然后重启应用。

## 故障排查

| 现象 | 处理 |
|------|------|
| `flutter doctor` 报错 | 执行 `flutter doctor -v`，按提示安装缺失组件 |
| Windows 上 CMake 找不到编译器 | 安装带 C++ 工作负载的 Visual Studio，重开终端 |
| `pod install` 失败 | 在 `macos/` 执行 `pod deintegrate`，再执行 `pod install --repo-update` |
| 找不到 DLL / dylib | Windows 看 `native\src\mouse_controller.dll`；开发态 macOS 看项目根目录的 `libmouse_controller.dylib` |
| 快捷键无效 | Windows 检查占用，必要时管理员运行。macOS 授予辅助功能后重启 |
| 启动即崩溃 | Windows 运行 `scripts\diagnose.bat`。macOS 用 `flutter run -d macos --verbose` 看日志 |

运行时日志在 `Documents/ClickMate/logs/`，文件日志只保留警告和错误。

## 相关文档

- [打包发布指南](打包发布指南.md)
- [多语言指南](MULTILINGUAL_GUIDE.md)
- [Flutter 桌面](https://docs.flutter.dev/desktop)
- [Dart FFI](https://dart.dev/interop/c-interop)
