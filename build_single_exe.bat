@echo off
chcp 65001 >nul
echo ========================================
echo 鼠标自动控制器 - 单EXE打包工具
echo ========================================
echo.

REM 检查是否安装了Enigma Virtual Box
set "EVB_PATH=C:\Program Files (x86)\Enigma Virtual Box\enigmavb.exe"
set "EVB_PATH2=C:\Program Files\Enigma Virtual Box\enigmavb.exe"

if exist "%EVB_PATH%" (
    set "ENIGMA=%EVB_PATH%"
    goto :found_enigma
)

if exist "%EVB_PATH2%" (
    set "ENIGMA=%EVB_PATH2%"
    goto :found_enigma
)

echo [×] 未找到 Enigma Virtual Box
echo.
echo 请先安装 Enigma Virtual Box (免费工具)
echo 下载地址: https://enigmaprotector.com/en/downloads.html
echo.
echo 安装后请重新运行此脚本
echo.
pause
exit /b 1

:found_enigma
echo [√] 找到 Enigma Virtual Box
echo.

REM 步骤1: 确保DLL存在
if not exist "native\src\mouse_controller.dll" (
    echo [×] 未找到 mouse_controller.dll
    echo 请先编译C++ DLL
    pause
    exit /b 1
)
echo [1/5] 检查DLL文件... OK
echo.

REM 步骤2: 复制DLL到根目录
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
echo [2/5] 复制DLL到根目录... OK
echo.

REM 步骤3: 构建Release版本
echo [3/5] 构建Flutter Release版本...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [×] 构建失败
    pause
    exit /b 1
)
echo [√] 构建成功
echo.

REM 步骤4: 复制mouse_controller.dll到Release目录
set "RELEASE_DIR=build\windows\x64\runner\Release"
if not exist "%RELEASE_DIR%" (
    echo [×] Release目录不存在
    pause
    exit /b 1
)

copy /Y "native\src\mouse_controller.dll" "%RELEASE_DIR%\" >nul 2>&1
echo [4/5] 复制DLL到Release目录... OK
echo.

REM 步骤5: 创建Enigma配置文件
echo [5/5] 生成打包配置...
set "EVB_PROJECT=build\enigma_config.evb"
set "INPUT_EXE=%RELEASE_DIR%\mouse_control.exe"
set "OUTPUT_EXE=build\鼠标自动控制器.exe"

(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<project^>
echo   ^<inputPath^>%CD%\%INPUT_EXE%^</inputPath^>
echo   ^<outputPath^>%CD%\%OUTPUT_EXE%^</outputPath^>
echo   ^<files^>
echo     ^<file^>
echo       ^<source^>%CD%\%RELEASE_DIR%\flutter_windows.dll^</source^>
echo       ^<destination^>%%DEFAULT FOLDER%%^</destination^>
echo     ^</file^>
echo     ^<file^>
echo       ^<source^>%CD%\%RELEASE_DIR%\mouse_controller.dll^</source^>
echo       ^<destination^>%%DEFAULT FOLDER%%^</destination^>
echo     ^</file^>
echo     ^<folder^>
echo       ^<source^>%CD%\%RELEASE_DIR%\data^</source^>
echo       ^<destination^>%%DEFAULT FOLDER%%\data^</destination^>
echo     ^</folder^>
echo   ^</files^>
echo ^</project^>
) > "%EVB_PROJECT%"

echo [√] 配置文件生成完成
echo.

echo ========================================
echo 开始打包单EXE文件...
echo ========================================
echo.

"%ENIGMA%" "%EVB_PROJECT%"

if exist "%OUTPUT_EXE%" (
    echo.
    echo ========================================
    echo ✓ 打包成功！
    echo ========================================
    echo.
    echo 输出文件: %OUTPUT_EXE%
    echo 文件大小: 
    for %%A in ("%OUTPUT_EXE%") do echo   %%~zA 字节 ^(约 %%~zA B^)
    echo.
    echo 您可以直接运行这个exe文件，无需其他依赖！
    echo.
) else (
    echo.
    echo [×] 打包失败
    echo 请检查Enigma Virtual Box是否正常工作
    echo.
)

pause

