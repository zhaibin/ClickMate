@echo off
chcp 65001 >nul
cd /d "%~dp0\.."

:: ========================================
:: Read version from VERSION file
:: ========================================
if exist "VERSION" (
    set /p VERSION=<VERSION
) else (
    echo [ERROR] VERSION file not found
    echo Please create a VERSION file in the project root
    exit /b 1
)
:: ========================================

echo ========================================
echo   Mouse Auto Clicker - Build Release
echo   Version: %VERSION%
echo ========================================
echo.

:: 1. Check DLL
echo [1/5] Checking DLL file...
if not exist "native\src\mouse_controller.dll" (
    echo [ERROR] mouse_controller.dll not found
    exit /b 1
)
echo [OK] DLL file exists
echo.

:: 2. Flutter Build
echo [2/5] Building Release version...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    exit /b 1
)
echo [OK] Build completed
echo.

:: 3. Create Portable Directory
echo [3/5] Creating portable package...
set RELEASE_DIR=build\windows\x64\runner\Release
set OUTPUT_DIR=releases\v%VERSION%
set PORTABLE_DIR=%OUTPUT_DIR%\MouseControl_v%VERSION%_Portable

if not exist "releases" mkdir "releases"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"
mkdir "%PORTABLE_DIR%"

:: Copy main program and core DLLs
copy "%RELEASE_DIR%\mouse_control.exe" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\flutter_windows.dll" "%PORTABLE_DIR%\" >nul

:: Copy plugin DLLs
copy "%RELEASE_DIR%\window_manager_plugin.dll" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\screen_retriever_windows_plugin.dll" "%PORTABLE_DIR%\" >nul

:: Copy native DLL from source directory
copy "native\src\mouse_controller.dll" "%PORTABLE_DIR%\" >nul

:: Copy resource files
xcopy "%RELEASE_DIR%\data" "%PORTABLE_DIR%\data\" /E /I /Y >nul

echo [OK] Files copied
echo.

:: 4. Create helper files
echo [4/5] Creating helper files...
call scripts\create_helper_files.bat "%PORTABLE_DIR%" "%VERSION%"
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Failed to create helper files
    exit /b 1
)
echo [OK] Helper files created
echo.

:: 5. Create ZIP
echo [5/5] Creating ZIP package...
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\MouseControl_v%VERSION%_Portable.zip' -Force"
echo [OK] ZIP created
echo.

echo ========================================
echo   Build Complete!
echo ========================================
echo.
echo Output directory: %OUTPUT_DIR%
echo   - MouseControl_v%VERSION%_Portable\
echo   - MouseControl_v%VERSION%_Portable.zip
echo.
echo Opening output folder...
start explorer "%CD%\%OUTPUT_DIR%"
echo.
echo Build completed successfully!
