# 详细构建指南

## 环境准备

### 1. 安装 CMake

从官网下载并安装 CMake：https://cmake.org/download/

或使用 winget 安装：
```cmd
winget install Kitware.CMake
```

### 2. 安装编译器（选择其一）

#### 选项 A: MinGW（推荐）

1. 下载 MinGW-w64：https://www.mingw-w64.org/downloads/
2. 或使用 MSYS2 安装：
   ```cmd
   # 安装 MSYS2 后运行
   pacman -S mingw-w64-x86_64-gcc
   pacman -S mingw-w64-x86_64-cmake
   ```
3. 将 MinGW 的 bin 目录添加到系统 PATH

#### 选项 B: Visual Studio

1. 下载并安装 Visual Studio 2019 或更高版本
2. 在安装时选择"使用 C++ 的桌面开发"工作负载

### 3. 安装 Flutter

1. 从官网下载 Flutter SDK：https://flutter.dev/docs/get-started/install/windows
2. 解压到合适的位置（如 C:\flutter）
3. 将 Flutter 的 bin 目录添加到系统 PATH
4. 运行 `flutter doctor` 检查环境

## 构建步骤

### 方法 1: 使用自动构建脚本（推荐）

```cmd
cd mouse_control
build_native.bat
```

### 方法 2: 手动构建

#### 使用 MinGW

```cmd
cd mouse_control\native
mkdir build
cd build
cmake .. -G "MinGW Makefiles"
cmake --build . --config Release

# 复制 DLL 到 Flutter 构建目录
mkdir ..\..\build\windows\x64\runner\Release
copy mouse_controller.dll ..\..\build\windows\x64\runner\Release\

mkdir ..\..\build\windows\x64\runner\Debug
copy mouse_controller.dll ..\..\build\windows\x64\runner\Debug\
```

#### 使用 Visual Studio

```cmd
cd mouse_control\native
mkdir build
cd build
cmake .. -G "Visual Studio 17 2022" -A x64
cmake --build . --config Release

# 复制 DLL 到 Flutter 构建目录
mkdir ..\..\build\windows\x64\runner\Release
copy Release\mouse_controller.dll ..\..\build\windows\x64\runner\Release\

mkdir ..\..\build\windows\x64\runner\Debug
copy Release\mouse_controller.dll ..\..\build\windows\x64\runner\Debug\
```

### 运行应用

```cmd
cd mouse_control
flutter pub get
flutter run -d windows
```

## 常见问题

### Q: CMake 找不到编译器
A: 确保已将编译器的 bin 目录添加到系统 PATH，重启命令提示符后重试。

### Q: 找不到 mouse_controller.dll
A: 确保已成功编译 C++ 库并将 DLL 复制到正确的位置。

### Q: Flutter 应用启动时报错
A: 检查是否已运行 `flutter pub get`，并确保 DLL 文件在正确的位置。

### Q: 热键不工作
A: 确保以管理员权限运行应用，某些系统上全局热键需要管理员权限。

## 调试技巧

### 检查 DLL 是否正确加载

在 [main.dart](lib/main.dart) 的 `initState` 方法中查看错误信息。

### 启用详细日志

```dart
// 在 mouse_controller_service.dart 中添加打印语句
print('Mouse position: $x, $y');
```

### 测试 C++ 库

创建一个简单的 C++ 测试程序：

```cpp
#include "mouse_controller.h"
#include <iostream>

int main() {
    int x, y;
    getMousePosition(&x, &y);
    std::cout << "Mouse position: " << x << ", " << y << std::endl;
    return 0;
}
```

编译并运行以验证 C++ 库是否正常工作。
