@echo off
chcp 65001 >nul
cd /d "%~dp0\.."

:: ========================================
:: ClickMate - Code Signing Script
:: ========================================
:: Prerequisites:
:: 1. Install Windows SDK (for signtool.exe)
:: 2. Have a valid code signing certificate (.pfx file)
:: 3. Set environment variables:
::    - SIGN_CERT_PATH: Path to your .pfx certificate file
::    - SIGN_CERT_PASS: Certificate password
::    Or use hardware token (EV certificate)
:: ========================================

echo ========================================
echo   ClickMate - Code Signing
echo ========================================
echo.

:: Read version
if exist "VERSION" (
    set /p VERSION=<VERSION
) else (
    echo [ERROR] VERSION file not found
    exit /b 1
)

set PORTABLE_DIR=releases\v%VERSION%\ClickMate_v%VERSION%_Portable
set TIMESTAMP_URL=http://timestamp.digicert.com

:: Check if portable directory exists
if not exist "%PORTABLE_DIR%" (
    echo [ERROR] Portable directory not found: %PORTABLE_DIR%
    echo Please run build_release.bat first
    exit /b 1
)

:: Check for signtool
where signtool >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] signtool.exe not found
    echo Please install Windows SDK or add signtool to PATH
    echo Download: https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
    exit /b 1
)

:: ========================================
:: Option 1: Sign with PFX file (Standard certificate)
:: ========================================
if defined SIGN_CERT_PATH (
    echo [INFO] Signing with PFX certificate...
    echo Certificate: %SIGN_CERT_PATH%
    echo.
    
    echo [1/3] Signing clickmate.exe...
    signtool sign /f "%SIGN_CERT_PATH%" /p "%SIGN_CERT_PASS%" /t %TIMESTAMP_URL% /fd SHA256 "%PORTABLE_DIR%\clickmate.exe"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to sign clickmate.exe
        exit /b 1
    )
    
    echo [2/3] Signing mouse_controller.dll...
    signtool sign /f "%SIGN_CERT_PATH%" /p "%SIGN_CERT_PASS%" /t %TIMESTAMP_URL% /fd SHA256 "%PORTABLE_DIR%\mouse_controller.dll"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to sign mouse_controller.dll
        exit /b 1
    )
    
    echo [3/3] Verifying signatures...
    signtool verify /pa "%PORTABLE_DIR%\clickmate.exe"
    signtool verify /pa "%PORTABLE_DIR%\mouse_controller.dll"
    
    goto :sign_complete
)

:: ========================================
:: Option 2: Sign with EV certificate (hardware token)
:: ========================================
if defined SIGN_CERT_NAME (
    echo [INFO] Signing with EV certificate (hardware token)...
    echo Certificate Name: %SIGN_CERT_NAME%
    echo.
    
    echo [1/3] Signing clickmate.exe...
    signtool sign /n "%SIGN_CERT_NAME%" /t %TIMESTAMP_URL% /fd SHA256 "%PORTABLE_DIR%\clickmate.exe"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to sign clickmate.exe
        exit /b 1
    )
    
    echo [2/3] Signing mouse_controller.dll...
    signtool sign /n "%SIGN_CERT_NAME%" /t %TIMESTAMP_URL% /fd SHA256 "%PORTABLE_DIR%\mouse_controller.dll"
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to sign mouse_controller.dll
        exit /b 1
    )
    
    echo [3/3] Verifying signatures...
    signtool verify /pa "%PORTABLE_DIR%\clickmate.exe"
    signtool verify /pa "%PORTABLE_DIR%\mouse_controller.dll"
    
    goto :sign_complete
)

:: No certificate configured
echo [ERROR] No certificate configured!
echo.
echo Please set one of the following environment variables:
echo.
echo Option 1 - PFX file (Standard certificate):
echo   set SIGN_CERT_PATH=C:\path\to\certificate.pfx
echo   set SIGN_CERT_PASS=your_password
echo.
echo Option 2 - EV certificate (Hardware token):
echo   set SIGN_CERT_NAME="Your Company Name"
echo.
exit /b 1

:sign_complete
echo.
echo ========================================
echo   Signing Complete!
echo ========================================
echo.

:: Recreate ZIP with signed files
echo Recreating ZIP with signed files...
set OUTPUT_DIR=releases\v%VERSION%
del "%OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip" 2>nul
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip' -Force"

echo.
echo [OK] Signed package ready: %OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip
echo.

