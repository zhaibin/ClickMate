@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo ========================================
echo 快捷键调试 - 启动测试
echo ========================================
echo.

echo [1/2] 复制DLL文件...
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
echo 完成
echo.

echo [2/2] 启动应用（请观察控制台日志）...
echo ========================================
echo.

flutter run -d windows

pause

