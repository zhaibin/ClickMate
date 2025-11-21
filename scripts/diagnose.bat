@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo ========================================
echo Diagnostic Tool
echo ========================================
echo.

echo [Check 1] DLL Files
echo ----------------------------------------
if exist "native\src\mouse_controller.dll" (
    echo [OK] Source DLL exists: native\src\mouse_controller.dll
    for %%A in ("native\src\mouse_controller.dll") do echo   Size: %%~zA bytes
) else (
    echo [ERROR] Source DLL not found!
    echo   Please compile DLL first: compile_dll.ps1
)

if exist "mouse_controller.dll" (
    echo [OK] Root DLL exists: mouse_controller.dll
    for %%A in ("mouse_controller.dll") do echo   Size: %%~zA bytes
) else (
    echo [WARNING] Root DLL not found!
    echo   Copying...
    copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
    if exist "mouse_controller.dll" (
        echo [OK] Copy successful
    ) else (
        echo [ERROR] Copy failed
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

echo [Check 4] Admin Privileges
echo ----------------------------------------
net session >nul 2>&1
if %errorlevel% == 0 (
    echo [OK] Running as administrator
) else (
    echo [WARNING] Not running as administrator
    echo   Suggestion: Right-click this file and select "Run as administrator"
)
echo.

echo ========================================
echo Diagnosis Complete
echo ========================================
echo.
echo Suggested actions:
echo 1. If DLL file is missing, compile it first
echo 2. Recommended to run application as administrator
echo 3. Use test_hotkey.bat to start and view logs
echo.

pause

