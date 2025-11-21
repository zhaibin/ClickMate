@echo off
chcp 65001 >nul
echo ========================================
echo 鼠标自动控制器 - 安装程序制作
echo ========================================
echo.

REM 检查Inno Setup
set "INNO_PATH=C:\Program Files (x86)\Inno Setup 6\ISCC.exe"

if not exist "%INNO_PATH%" (
    echo [×] 未找到 Inno Setup
    echo.
    echo 请先安装 Inno Setup (免费工具)
    echo 下载地址: https://jrsoftware.org/isdl.php
    echo.
    pause
    exit /b 1
)

echo [√] 找到 Inno Setup
echo.

REM 步骤1: 构建Release
echo [1/3] 构建Flutter Release版本...
call flutter build windows --release
if %errorlevel% neq 0 (
    echo [×] 构建失败
    pause
    exit /b 1
)
echo.

REM 步骤2: 复制DLL
set "RELEASE_DIR=build\windows\x64\runner\Release"
copy /Y "native\src\mouse_controller.dll" "%RELEASE_DIR%\" >nul 2>&1
echo [2/3] 复制DLL文件... OK
echo.

REM 步骤3: 创建Inno Setup脚本
echo [3/3] 生成安装脚本...
set "ISS_FILE=build\installer.iss"

(
echo ; 鼠标自动控制器 安装脚本
echo [Setup]
echo AppName=鼠标自动控制器
echo AppVersion=1.1.0
echo AppPublisher=Your Name
echo DefaultDirName={autopf}\MouseControl
echo DefaultGroupName=鼠标自动控制器
echo OutputDir=%CD%\build
echo OutputBaseFilename=鼠标自动控制器_Setup
echo Compression=lzma2/max
echo SolidCompression=yes
echo ArchitecturesAllowed=x64
echo ArchitecturesInstallIn64BitMode=x64
echo.
echo [Languages]
echo Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
echo.
echo [Tasks]
echo Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加图标:"
echo.
echo [Files]
echo Source: "%CD%\%RELEASE_DIR%\mouse_control.exe"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%CD%\%RELEASE_DIR%\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%CD%\%RELEASE_DIR%\mouse_controller.dll"; DestDir: "{app}"; Flags: ignoreversion
echo Source: "%CD%\%RELEASE_DIR%\data\*"; DestDir: "{app}\data"; Flags: ignoreversion recursesubdirs createallsubdirs
echo.
echo [Icons]
echo Name: "{group}\鼠标自动控制器"; Filename: "{app}\mouse_control.exe"
echo Name: "{group}\卸载鼠标自动控制器"; Filename: "{uninstallexe}"
echo Name: "{autodesktop}\鼠标自动控制器"; Filename: "{app}\mouse_control.exe"; Tasks: desktopicon
echo.
echo [Run]
echo Filename: "{app}\mouse_control.exe"; Description: "启动鼠标自动控制器"; Flags: nowait postinstall skipifsilent
) > "%ISS_FILE%"

echo [√] 安装脚本生成完成
echo.

echo ========================================
echo 开始制作安装程序...
echo ========================================
echo.

"%INNO_PATH%" "%ISS_FILE%"

if exist "build\鼠标自动控制器_Setup.exe" (
    echo.
    echo ========================================
    echo ✓ 安装程序制作成功！
    echo ========================================
    echo.
    echo 输出文件: build\鼠标自动控制器_Setup.exe
    echo.
    echo 用户可以通过此安装程序安装应用
    echo.
) else (
    echo.
    echo [×] 制作失败
    echo.
)

pause

