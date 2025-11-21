@echo off
REM Switch to project root
cd /d "%~dp0\.."

echo ========================================
echo Mouse Control - Debug Mode
echo ========================================
echo.

REM Check DLL file
if not exist "native\src\mouse_controller.dll" (
    echo [ERROR] mouse_controller.dll not found
    echo Location: native\src\mouse_controller.dll
    echo.
    echo Please compile DLL first!
    pause
    exit /b 1
)

echo [OK] DLL file found
echo.

REM Copy DLL to root
echo [1/3] Copy DLL to root directory...
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Copy successful
) else (
    echo [ERROR] Copy failed
    pause
    exit /b 1
)
echo.

REM Get dependencies
echo [2/3] Get Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies ready
echo.

REM Clean old build
echo [3/3] Clean old build...
if exist "build\windows\x64\runner\Debug\" (
    rmdir /s /q "build\windows\x64\runner\Debug\" >nul 2>&1
)
echo [OK] Clean complete
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

