@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo ========================================
echo 快捷键问题诊断工具
echo ========================================
echo.

echo [检查1] DLL文件
echo ----------------------------------------
if exist "native\src\mouse_controller.dll" (
    echo ✓ 源DLL存在: native\src\mouse_controller.dll
    for %%A in ("native\src\mouse_controller.dll") do echo   大小: %%~zA 字节
) else (
    echo × 源DLL不存在！
    echo   请先编译DLL: compile_dll.ps1
)

if exist "mouse_controller.dll" (
    echo ✓ 根目录DLL存在: mouse_controller.dll
    for %%A in ("mouse_controller.dll") do echo   大小: %%~zA 字节
) else (
    echo × 根目录DLL不存在！
    echo   正在复制...
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    if exist "mouse_controller.dll" (
        echo ✓ 复制成功
    ) else (
        echo × 复制失败
    )
)
echo.

echo [检查2] Flutter环境
echo ----------------------------------------
flutter --version | findstr "Flutter"
echo.

echo [检查3] Windows版本
echo ----------------------------------------
ver
echo.

echo [检查4] 管理员权限
echo ----------------------------------------
net session >nul 2>&1
if %errorlevel% == 0 (
    echo ✓ 当前以管理员权限运行
) else (
    echo × 当前非管理员权限
    echo   建议: 右键点击此文件，选择"以管理员身份运行"
)
echo.

echo ========================================
echo 诊断完成
echo ========================================
echo.
echo 建议操作:
echo 1. 如果DLL文件缺失，请先编译
echo 2. 建议以管理员身份运行应用
echo 3. 使用 test_hotkey.bat 启动并查看日志
echo.

pause

