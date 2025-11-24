@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo ========================================
echo ClickMate - Diagnostic Tool
echo ========================================
echo.

echo [Check 1] DLL Files
echo ----------------------------------------
if exist "native\src\mouse_controller.dll" (
    echo [OK] Source DLL exists: native\src\mouse_controller.dll
    for %%A in ("native\src\mouse_controller.dll") do echo   Size: %%~zA bytes
) else (
    echo [X] Source DLL not found!
    echo   Please compile DLL first: compile_dll.ps1
)

if exist "mouse_controller.dll" (
    echo [OK] Root DLL exists: mouse_controller.dll
    for %%A in ("mouse_controller.dll") do echo   Size: %%~zA bytes
) else (
    echo [X] Root DLL not found!
    echo   Copying...
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    if exist "mouse_controller.dll" (
        echo [OK] Copy successful
    ) else (
        echo [X] Copy failed
    )
)
echo.

echo [Check 2] Flutter Environment
echo ----------------------------------------
flutter --version | findstr "Flutter"
echo.

echo [Check 3] Windows Version
echo ----------------------------------------
ver
echo.

echo [Check 4] Administrator Privileges
echo ----------------------------------------
net session >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Running with administrator privileges
) else (
    echo [X] Not running as administrator
    echo   Suggestion: Right-click this file and select "Run as administrator"
)
echo.

echo ========================================
echo Diagnostic Complete
echo ========================================
echo.
echo Recommendations:
echo 1. If DLL files are missing, compile them first
echo 2. Recommend running the app as administrator
echo 3. Use test_hotkey.bat to start and view logs
echo.

pause

