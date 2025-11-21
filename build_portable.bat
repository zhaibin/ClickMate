@echo off
chcp 65001 >nul
echo ========================================
echo 鼠标自动控制器 - 便携版打包
echo ========================================
echo.

REM 步骤1: 构建Release
echo [1/4] 构建Flutter Release版本...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [×] 构建失败
    pause
    exit /b 1
)
echo [√] 构建成功
echo.

REM 步骤2: 创建便携版目录
set "PORTABLE_DIR=build\MouseControl_Portable"
set "RELEASE_DIR=build\windows\x64\runner\Release"

if exist "%PORTABLE_DIR%" (
    rmdir /s /q "%PORTABLE_DIR%"
)
mkdir "%PORTABLE_DIR%" 2>nul

echo [2/4] 创建便携版目录... OK
echo.

REM 步骤3: 复制所有必需文件
echo [3/4] 复制文件...

copy /Y "%RELEASE_DIR%\mouse_control.exe" "%PORTABLE_DIR%\" >nul 2>&1
copy /Y "%RELEASE_DIR%\flutter_windows.dll" "%PORTABLE_DIR%\" >nul 2>&1
copy /Y "native\src\mouse_controller.dll" "%PORTABLE_DIR%\" >nul 2>&1

xcopy /E /I /Y "%RELEASE_DIR%\data" "%PORTABLE_DIR%\data" >nul 2>&1

echo [√] 文件复制完成
echo.

REM 步骤4: 创建说明文件
echo [4/4] 创建说明文件...

(
echo 鼠标自动控制器 - 便携版
echo ================================
echo.
echo 版本: 1.1.0
echo 更新日期: 2024-11-21
echo.
echo 使用说明:
echo 1. 直接运行 mouse_control.exe
echo 2. 点击右上角键盘图标设置快捷键
echo 3. 设置目标位置和点击参数
echo 4. 使用快捷键开始/停止点击
echo.
echo 文件说明:
echo - mouse_control.exe: 主程序
echo - flutter_windows.dll: Flutter运行库
echo - mouse_controller.dll: 鼠标控制库
echo - data/: 应用资源文件
echo.
echo 注意事项:
echo - 所有文件必须在同一目录
echo - 某些功能可能需要管理员权限
echo - 建议使用 Ctrl+Shift+不常用的键 作为快捷键
echo.
echo 技术支持:
echo - 查看 CHANGELOG.md 了解更新内容
echo - 查看 完整代码说明.md 了解详细信息
echo.
) > "%PORTABLE_DIR%\使用说明.txt"

copy /Y "CHANGELOG.md" "%PORTABLE_DIR%\" >nul 2>&1
copy /Y "完整代码说明.md" "%PORTABLE_DIR%\" >nul 2>&1

echo [√] 说明文件创建完成
echo.

REM 步骤5: 创建ZIP压缩包
echo ========================================
echo 创建ZIP压缩包...
echo ========================================
echo.

set "ZIP_FILE=build\鼠标自动控制器_v1.1.0_便携版.zip"

if exist "%ZIP_FILE%" del "%ZIP_FILE%"

powershell -command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%ZIP_FILE%' -CompressionLevel Optimal"

if exist "%ZIP_FILE%" (
    echo.
    echo ========================================
    echo ✓ 便携版打包成功！
    echo ========================================
    echo.
    echo 输出目录: %PORTABLE_DIR%
    echo 压缩包: %ZIP_FILE%
    echo.
    echo 文件列表:
    dir /B "%PORTABLE_DIR%"
    echo.
    echo 您可以:
    echo 1. 直接使用 %PORTABLE_DIR% 目录
    echo 2. 分发 ZIP 压缩包
    echo.
) else (
    echo.
    echo [×] 压缩失败，但文件夹已创建
    echo 便携版目录: %PORTABLE_DIR%
    echo.
)

echo 打开便携版目录...
explorer "%PORTABLE_DIR%"

pause

