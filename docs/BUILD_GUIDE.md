# Build Guide / 构建指南

Complete guide for building ClickMate on Windows and macOS.

完整的 ClickMate 构建指南，支持 Windows 和 macOS 平台。

---

## 📋 Prerequisites / 环境准备

### Common Requirements / 通用要求

1. **Flutter SDK** (3.10+)
   - Download: https://flutter.dev/docs/get-started/install
   - Add to system PATH
   - Run `flutter doctor` to verify

2. **Git**
   - Download: https://git-scm.com/downloads

---

## 🪟 Windows Build / Windows 构建

### Requirements / 环境要求

1. **CMake**
   ```cmd
   winget install Kitware.CMake
   ```
   Or download from: https://cmake.org/download/

2. **C++ Compiler** (choose one)

   **Option A: Visual Studio (Recommended)**
   - Download Visual Studio 2019 or later
   - Select "Desktop development with C++" workload

   **Option B: MinGW**
   ```cmd
   # Using MSYS2
   pacman -S mingw-w64-x86_64-gcc
   pacman -S mingw-w64-x86_64-cmake
   ```

### Build Steps / 构建步骤

#### Method 1: Auto Script (Recommended) / 自动脚本（推荐）

```cmd
# Debug build and run
scripts\quick_start.bat

# Release build
scripts\build_release.bat
```

#### Method 2: Manual Build / 手动构建

```cmd
# 1. Get dependencies
flutter pub get

# 2. Build C++ DLL (if needed)
cd native
mkdir build && cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release
copy Release\mouse_controller.dll ..\src\

# 3. Build Flutter app
cd ..\..
flutter build windows --debug
# or
flutter build windows --release

# 4. Run
build\windows\x64\runner\Debug\clickmate.exe
```

### Output Files / 输出文件

```
build\windows\x64\runner\
├── Debug\
│   ├── clickmate.exe
│   ├── flutter_windows.dll
│   ├── mouse_controller.dll
│   └── data\
└── Release\
    └── (same structure)
```

---

## 🍎 macOS Build / macOS 构建

### Requirements / 环境要求

1. **Xcode** (12.0+)
   ```bash
   xcode-select --install
   ```

2. **CocoaPods**
   ```bash
   sudo gem install cocoapods
   ```

3. **Clang** (included with Xcode)

### Build Steps / 构建步骤

#### Method 1: Flutter Command (Recommended) / Flutter 命令（推荐）

```bash
# 1. Get dependencies
flutter pub get
cd macos && pod install && cd ..

# 2. Build native library (if needed)
cd native/src
clang++ -shared -fPIC -framework Cocoa -framework Carbon -framework CoreGraphics \
  -o libmouse_controller.dylib mouse_controller_macos.mm
cd ../..

# 3. Build and run
flutter run -d macos

# Or build release
flutter build macos --release
```

#### Method 2: Xcode Build / Xcode 构建

```bash
# Open in Xcode
open macos/Runner.xcworkspace

# Build from Xcode (⌘+B)
```

### Output Files / 输出文件

```
build/macos/Build/Products/
├── Debug/
│   └── ClickMate.app
└── Release/
    └── ClickMate.app
```

### macOS Permissions / macOS 权限

ClickMate requires **Accessibility** permission for:
- Global hotkey registration
- Mouse control

To grant permission:
1. Open **System Preferences** → **Security & Privacy** → **Privacy**
2. Select **Accessibility** in the left panel
3. Click the lock icon and authenticate
4. Add ClickMate.app to the list

---

## 🔧 Native Library Build / 原生库构建

### Windows DLL

```cmd
cd native/src

# Using cl.exe (MSVC)
cl /LD mouse_controller.cpp /Fe:mouse_controller.dll user32.lib

# Using g++ (MinGW)
g++ -shared -o mouse_controller.dll mouse_controller.cpp -luser32
```

### macOS Dynamic Library

```bash
cd native/src

clang++ -shared -fPIC \
  -framework Cocoa \
  -framework Carbon \
  -framework CoreGraphics \
  -o libmouse_controller.dylib \
  mouse_controller_macos.mm
```

---

## 🐛 Troubleshooting / 故障排查

### Common Issues / 常见问题

#### Q: Flutter doctor shows issues
```bash
flutter doctor -v
# Follow the suggestions to fix
```

#### Q: CMake can't find compiler (Windows)
- Ensure Visual Studio or MinGW is in PATH
- Restart terminal after installation

#### Q: Pod install fails (macOS)
```bash
cd macos
pod deintegrate
pod install --repo-update
```

#### Q: DLL/dylib not found
```bash
# Windows - check DLL location
dir native\src\mouse_controller.dll

# macOS - check dylib location
ls -la native/src/libmouse_controller.dylib
```

#### Q: Hotkeys not working

**Windows:**
- Run as Administrator
- Check if another app uses the same hotkey

**macOS:**
- Grant Accessibility permission
- Restart the app after granting permission

#### Q: App crashes on startup

**Windows:**
```cmd
scripts\diagnose.bat
```

**macOS:**
```bash
# Check console for errors
flutter run -d macos --verbose
```

---

## 📁 Project Structure / 项目结构

```
ClickMate/
├── lib/                          # Flutter source code
│   ├── main.dart                # Main application
│   ├── mouse_controller_bindings.dart  # FFI bindings
│   ├── mouse_controller_service.dart   # Business logic
│   └── l10n/                    # Localization
│
├── native/src/                   # Native code
│   ├── mouse_controller.cpp     # Windows implementation
│   ├── mouse_controller.h       # Header file
│   ├── mouse_controller.dll     # Windows binary
│   ├── mouse_controller_macos.mm  # macOS implementation
│   └── libmouse_controller.dylib  # macOS binary
│
├── windows/                      # Windows platform
│   ├── CMakeLists.txt
│   └── runner/
│       └── main.cpp             # Windows entry point
│
├── macos/                        # macOS platform
│   ├── Podfile
│   └── Runner/
│       ├── MainFlutterWindow.swift
│       └── AppDelegate.swift
│
└── scripts/                      # Build scripts (Windows)
    ├── build_release.bat
    ├── quick_start.bat
    └── diagnose.bat
```

---

## 🚀 Development Tips / 开发技巧

### Hot Reload / 热重载

```bash
# Flutter hot reload works for UI changes
flutter run -d windows  # or macos
# Press 'r' for hot reload
# Press 'R' for hot restart
```

### Debug Logging / 调试日志

```dart
// In Dart code
print('Debug message');
LoggerService.instance.info('Info message');
LoggerService.instance.error('Error message');
```

### Native Code Debugging / 原生代码调试

**Windows:** Use Visual Studio debugger
**macOS:** Use Xcode debugger or lldb

---

## 📚 Resources / 相关资源

- [Flutter Documentation](https://docs.flutter.dev/)
- [Flutter Desktop](https://docs.flutter.dev/desktop)
- [Dart FFI](https://dart.dev/guides/libraries/c-interop)
- [window_manager](https://pub.dev/packages/window_manager)

---

**Last Updated**: 2024-11-29  
**Version**: 2.0.0
