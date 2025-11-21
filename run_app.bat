@echo off
echo ========================================
echo 鼠标自动控制器 - 快速启动脚本
echo ========================================
echo.

REM 检查是否已编译C++库
if not exist "build\windows\x64\runner\Release\mouse_controller.dll" (
    if not exist "build\windows\x64\runner\Debug\mouse_controller.dll" (
        echo [警告] 未找到 mouse_controller.dll
        echo 请先运行 build_native.bat 编译C++库
        echo.
        choice /C YN /M "是否现在编译C++库"
        if errorlevel 2 goto :end
        if errorlevel 1 call build_native.bat
    )
)

echo.
echo 正在启动Flutter应用...
echo.

flutter pub get
if %errorlevel% neq 0 (
    echo Flutter依赖获取失败！
    pause
    exit /b 1
)

flutter run -d windows --release

:end
pause
