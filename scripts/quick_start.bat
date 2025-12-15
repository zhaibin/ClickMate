@echo off
chcp 65001 >nul
cd /d "%~dp0\.."

echo ========================================
echo ClickMate - Quick Start
echo ========================================
echo.

REM Check for Debug executable
set DEBUG_EXE=build\windows\x64\runner\Debug\clickmate.exe

if exist "%DEBUG_EXE%" (
    echo [OK] Found Debug executable
    echo.
    
    REM Check DLL
    if exist "native\src\mouse_controller.dll" (
        echo [1/2] Copying DLL...
        copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
        echo [OK] DLL ready
        echo.
        
        echo [2/2] Launching application...
        echo ========================================
        echo.
        echo Tips:
        echo - Watch for "Hotkey system init: Success"
        echo - Watch for "Hotkey register: Success"
        echo - Press Ctrl+Shift+1 to test start/stop
        echo - Press Ctrl+Shift+2 to capture position
        echo.
        echo For hotkeys to work, you may need admin rights.
        echo Close and run as administrator if needed.
        echo.
        echo ========================================
        echo.
        
        "%DEBUG_EXE%"
        
        echo.
        echo Application closed.
        pause
    ) else (
        echo [ERROR] DLL not found: native\src\mouse_controller.dll
        echo Please ensure DLL is compiled.
        pause
        exit /b 1
    )
) else (
    echo [INFO] Debug executable not found
    echo Building Debug version...
    echo.
    
    REM Check DLL first
    if not exist "native\src\mouse_controller.dll" (
        echo [ERROR] DLL not found: native\src\mouse_controller.dll
        echo Location: native\src\mouse_controller.dll
        echo.
        echo Please compile DLL first!
        pause
        exit /b 1
    )
    
    echo [OK] DLL file found
    echo.
    
    REM Copy DLL
    echo [1/3] Copying DLL to root...
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] DLL copied
    ) else (
        echo [ERROR] Failed to copy DLL
        pause
        exit /b 1
    )
    echo.
    
    REM Get dependencies
    echo [2/3] Getting Flutter dependencies...
    call flutter pub get
    if %errorlevel% neq 0 (
        echo [ERROR] Failed to get dependencies
        pause
        exit /b 1
    )
    echo [OK] Dependencies ready
    echo.
    
    REM Build Debug version
    echo [3/3] Building Debug version...
    echo This may take a minute...
    echo.
    call flutter build windows --debug
    if %errorlevel% neq 0 (
        echo.
        echo [ERROR] Build failed!
        echo.
        echo Common issues:
        echo 1. Ensure Visual Studio 2022 is installed
        echo 2. Ensure Flutter SDK is properly configured
        echo 3. Try running 'flutter doctor' to diagnose
        echo.
        pause
        exit /b 1
    )
    
    echo.
    echo [OK] Build successful!
    echo.
    
    REM Now launch the newly built executable
    if exist "%DEBUG_EXE%" (
        echo ========================================
        echo Launching application...
        echo ========================================
        echo.
        echo Tips:
        echo - Watch for "Hotkey system init: Success"
        echo - Watch for "Hotkey register: Success"
        echo - Press Ctrl+Shift+1 to test start/stop
        echo - Press Ctrl+Shift+2 to capture position
        echo.
        echo For hotkeys to work, you may need admin rights.
        echo Close and run as administrator if needed.
        echo.
        echo ========================================
        echo.
        
        "%DEBUG_EXE%"
        
        echo.
        echo Application closed.
        pause
    ) else (
        echo [ERROR] Debug executable not found after build
        echo Expected: %DEBUG_EXE%
        pause
        exit /b 1
    )
)





