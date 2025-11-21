@echo off
chcp 65001 >nul
REM Switch to project root
cd /d "%~dp0\.."

echo ========================================
echo Mouse Control - Debug Mode
echo ========================================
echo.

REM Check DLL file
if not exist "native\src\mouse_controller.dll" (
    echo [ERROR] mouse_controller.dll not found
    echo Location: native\src\mouse_controller.dll
    echo.
    echo Please compile DLL first!
    pause
    exit /b 1
)

echo [OK] DLL file found
echo.

REM Copy DLL to root
echo [1/3] Copy DLL to root directory...
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Copy successful
) else (
    echo [ERROR] Copy failed
    pause
    exit /b 1
)
echo.

REM Get dependencies
echo [2/3] Get Flutter dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] Failed to get dependencies
    pause
    exit /b 1
)
echo [OK] Dependencies ready
echo.

REM Clean old build
echo [3/3] Clean old build...
if exist "build\windows\x64\runner\Debug\" (
    rmdir /s /q "build\windows\x64\runner\Debug\" >nul 2>&1
)
echo [OK] Clean complete
echo.

echo ========================================
echo Starting application (Debug mode)...
echo ========================================
echo.
echo Tips:
echo - Console will show debug information
echo - Check "Hotkey system init" and "Hotkey register" status
echo - If failed, try running as administrator
echo.
echo ========================================
echo.

REM Run application
call flutter run -d windows

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Application start failed!
    echo.
    echo Common issues:
    echo 1. Make sure Visual Studio 2022 is installed
    echo 2. Make sure DLL file exists and is accessible
    echo 3. Try running this script as administrator
    echo.
)

pause

