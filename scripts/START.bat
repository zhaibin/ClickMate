@echo off
cd /d "%~dp0\.."

echo ========================================
echo Mouse Auto Clicker
echo ========================================
echo.

REM Check if running as admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [WARNING] Not running as administrator
    echo Hotkey may not work without admin rights
    echo.
    echo Right-click this file and select
    echo "Run as administrator" to fix this
    echo.
    pause
    echo Continuing anyway...
    echo.
)

REM Check project files
if not exist "pubspec.yaml" (
    echo [ERROR] Wrong directory! pubspec.yaml not found
    echo Current: %CD%
    pause
    exit /b 1
)

REM Copy DLL
if exist "native\src\mouse_controller.dll" (
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    echo [OK] DLL ready
) else (
    echo [ERROR] DLL not found: native\src\mouse_controller.dll
    pause
    exit /b 1
)

echo.
echo Starting application...
echo.
echo Watch console for:
echo  - "Hotkey system init: Success"
echo  - "Hotkey register: Success"
echo  - Press Ctrl+Shift+S to test
echo.
echo ========================================
echo.

flutter run -d windows

echo.
pause

