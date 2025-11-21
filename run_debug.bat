@echo off
chcp 65001 >nul
echo ========================================
echo 鼠标自动控制器 - Debug运行
echo ========================================
echo.

REM 检查DLL文件
if not exist "native\src\mouse_controller.dll" (
    echo [错误] 未找到 mouse_controller.dll
    echo 位置: native\src\mouse_controller.dll
    echo.
    echo 请先编译DLL文件！
    pause
    exit /b 1
)

echo [√] 找到 DLL 文件
echo.

REM 复制DLL到根目录
echo [1/3] 复制DLL到根目录...
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
if %errorlevel% equ 0 (
    echo [√] 复制成功
) else (
    echo [×] 复制失败
    pause
    exit /b 1
)
echo.

REM 获取依赖
echo [2/3] 获取Flutter依赖...
call flutter pub get
if %errorlevel% neq 0 (
    echo [×] 依赖获取失败
    pause
    exit /b 1
)
echo [√] 依赖获取成功
echo.

REM 清理旧的构建
echo [3/3] 清理旧构建...
if exist "build\windows\x64\runner\Debug\" (
    rmdir /s /q "build\windows\x64\runner\Debug\" >nul 2>&1
)
echo [√] 清理完成
echo.

echo ========================================
echo 启动应用程序（Debug模式）...
echo ========================================
echo.
echo 提示：
echo - 控制台将显示调试信息
echo - 查看 "热键系统初始化" 和 "热键注册" 状态
echo - 如果显示失败，可能需要以管理员权限运行
echo.
echo ========================================
echo.

REM 运行应用
call flutter run -d windows

if %errorlevel% neq 0 (
    echo.
    echo [×] 应用启动失败！
    echo.
    echo 常见问题：
    echo 1. 确保已安装Visual Studio 2022
    echo 2. 确保DLL文件存在且可访问
    echo 3. 尝试以管理员身份运行此脚本
    echo.
)

pause

