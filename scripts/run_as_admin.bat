@echo off
REM 切换到项目根目录
cd /d "%~dp0\.."

REM 检查管理员权限
net session >nul 2>&1
if %errorlevel% == 0 (
    echo ========================================
    echo Mouse Control - Admin Mode
    echo ========================================
    echo.
    echo [OK] Running with admin privileges
    echo.
    
    echo [1/3] Check project directory...
    if exist "pubspec.yaml" (
        echo [OK] Found pubspec.yaml
    ) else (
        echo [ERROR] pubspec.yaml not found!
        echo Current directory: %CD%
        pause
        exit /b 1
    )
    echo.
    
    echo [2/3] Copy DLL file...
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    if %errorlevel% == 0 (
        echo [OK] DLL copied
    ) else (
        echo [WARNING] DLL copy failed, but continuing...
    )
    echo.
    
    echo [3/3] Starting application...
    echo ========================================
    echo.
    echo Watch for these messages:
    echo - "Hotkey system init: Success" = OK
    echo - "Hotkey register: Success" = OK
    echo - Press Ctrl+Shift+S to test
    echo.
    echo ========================================
    echo.
    
    flutter run -d windows
    
    pause
) else (
    echo ========================================
    echo Admin Privileges Required
    echo ========================================
    echo.
    echo Right-click this file and select
    echo "Run as administrator"
    echo.
    pause
)

