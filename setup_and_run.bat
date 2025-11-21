@echo off
echo ========================================
echo 鼠标自动控制器 - 启动脚本
echo ========================================
echo.

REM 检查DLL文件
if not exist "native\src\mouse_controller.dll" (
    echo [错误] 未找到 mouse_controller.dll
    echo 请先编译DLL文件
    pause
    exit /b 1
)

echo [1/4] 检查DLL文件... OK
echo.

REM 复制DLL到根目录（用于Debug模式）
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
echo [2/4] 复制DLL到根目录... OK
echo.

REM 获取依赖
echo [3/4] 获取Flutter依赖...
call flutter pub get
if %errorlevel% neq 0 (
    echo [错误] Flutter依赖获取失败
    pause
    exit /b 1
)
echo.

REM 运行应用
echo [4/4] 启动应用程序...
echo.
echo ========================================
echo 应用正在启动，请稍候...
echo 提示：按 Ctrl+C 可以停止应用
echo ========================================
echo.
call flutter run -d windows

pause

