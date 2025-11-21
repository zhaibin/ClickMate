@echo off
chcp 65001 >nul
cd /d "%~dp0\.."

echo ========================================
echo   鼠标自动控制器 - 构建发布版
echo ========================================
echo.

:: 1. 检查DLL
echo [1/4] 检查DLL文件...
if not exist "native\src\mouse_controller.dll" (
    echo [!] 缺少 mouse_controller.dll
    pause
    exit /b 1
)
echo [OK] DLL文件存在
echo.

:: 2. Flutter构建
echo [2/4] 构建Release版本...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [!] 构建失败
    pause
    exit /b 1
)
echo [OK] 构建完成
echo.

:: 3. 创建便携版
echo [3/4] 创建便携版...
set RELEASE_DIR=build\windows\x64\runner\Release
set VERSION=1.3.1
set OUTPUT_DIR=releases\v%VERSION%
set PORTABLE_DIR=%OUTPUT_DIR%\MouseControl_v%VERSION%_Portable

if not exist "releases" mkdir "releases"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"
mkdir "%PORTABLE_DIR%"

:: 复制主程序和核心DLL
copy "%RELEASE_DIR%\mouse_control.exe" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\flutter_windows.dll" "%PORTABLE_DIR%\" >nul

:: 复制插件DLL
copy "%RELEASE_DIR%\window_manager_plugin.dll" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\screen_retriever_windows_plugin.dll" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\mouse_controller.dll" "%PORTABLE_DIR%\" >nul

:: 复制资源文件
xcopy "%RELEASE_DIR%\data" "%PORTABLE_DIR%\data\" /E /I /Y >nul

:: 创建使用说明
(
echo ========================================
echo   鼠标自动控制器 v%VERSION%
echo ========================================
echo.
echo 快捷键:
echo   Ctrl + Shift + 1  开始/停止点击
echo   Ctrl + Shift + 2  捕获鼠标位置
echo.
echo 功能:
echo   - 自动跟踪模式^(默认^): 实时跟随鼠标
echo   - 手动输入模式: 固定坐标点击
echo   - 点击输入框切换到手动模式
echo.
echo 使用:
echo   1. 右键以管理员身份运行
echo   2. 设置点击间隔等参数
echo   3. 按 Ctrl+Shift+1 开始点击
echo.
echo 注意: 需要管理员权限
) > "%PORTABLE_DIR%\使用说明.txt"

echo [OK] 便携版已创建
echo.

:: 4. 创建ZIP
echo [4/4] 打包ZIP...
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\鼠标自动控制器_v%VERSION%_便携版.zip' -Force"
echo [OK] ZIP已创建
echo.

echo ========================================
echo   发布文件已创建在: releases\v%VERSION%\
echo   - MouseControl_v%VERSION%_Portable\ (便携版文件夹)
echo   - 鼠标自动控制器_v%VERSION%_便携版.zip (分发文件)
echo ========================================
echo.
echo 发布路径: %CD%\%OUTPUT_DIR%
echo.
pause

