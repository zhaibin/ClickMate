@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
echo ========================================
echo Hotkey Debug - Start Test
echo ========================================
echo.

echo [1/2] Copy DLL file...
copy /Y "native\src\mouse_controller.dll" "." >nul 2>&1
echo Done
echo.

echo [2/2] Start application (watch console logs)...
echo ========================================
echo.

flutter run -d windows

pause

