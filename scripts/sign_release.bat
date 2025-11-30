@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
setlocal enabledelayedexpansion

:: ========================================
:: ClickMate - Code Signing Script
:: ========================================
:: Signs the installer EXE in ClickMate-Installer\Output
:: ========================================

echo ========================================
echo   ClickMate - Code Signing
echo ========================================
echo.

:: Read version
if not exist "VERSION" (
    echo [ERROR] VERSION file not found
    exit /b 1
)
set /p VERSION=<VERSION

:: Installer output directory
set "INSTALLER_DIR=E:\Projects\xants\ClickMate-Installer\Output"
set "INSTALLER_EXE=%INSTALLER_DIR%\ClickMate_v%VERSION%_Setup.exe"

:: Certificate settings
set "CERT_DIR=%USERPROFILE%\.clickmate_certs"
set "SELF_SIGN_CERT=%CERT_DIR%\clickmate_selfsign.pfx"
set "SELF_SIGN_PASS=ClickMate2024"

echo Version: %VERSION%
echo Installer: %INSTALLER_EXE%
echo.

:: Check if installer exists
if not exist "%INSTALLER_EXE%" (
    echo [ERROR] Installer not found: %INSTALLER_EXE%
    echo.
    echo Please build the installer first:
    echo   cd E:\Projects\xants\ClickMate-Installer
    echo   build.bat
    exit /b 1
)

:: Find signtool
call :find_signtool
if "!SIGNTOOL!"=="" (
    echo [ERROR] signtool.exe not found!
    echo.
    echo Please install Windows SDK:
    echo   https://developer.microsoft.com/en-us/windows/downloads/windows-sdk/
    exit /b 1
)
echo [OK] Found signtool: !SIGNTOOL!
echo.

:: Check signing method
if defined SIGN_CERT_PATH (
    echo [INFO] Using commercial PFX certificate...
    set "CERT_FILE=%SIGN_CERT_PATH%"
    set "CERT_PASS=%SIGN_CERT_PASS%"
    goto :do_sign
)

if defined SIGN_CERT_NAME (
    echo [INFO] Using EV certificate...
    goto :sign_ev
)

:: Default: Self-signed certificate
echo [INFO] Using self-signed certificate
echo.

:: Create certificate directory
if not exist "%CERT_DIR%" mkdir "%CERT_DIR%"

:: Create self-signed certificate if not exists
if not exist "%SELF_SIGN_CERT%" (
    echo [INFO] Creating self-signed certificate...
    echo.
    powershell -NoProfile -File "%~dp0create_selfsign_cert.ps1" "%SELF_SIGN_CERT%" "%SELF_SIGN_PASS%"
    if errorlevel 1 (
        echo [ERROR] Failed to create certificate
        exit /b 1
    )
    echo.
) else (
    echo [OK] Using existing certificate: %SELF_SIGN_CERT%
    echo.
)

set "CERT_FILE=%SELF_SIGN_CERT%"
set "CERT_PASS=%SELF_SIGN_PASS%"
goto :do_sign

:: ========================================
:: Sign with EV certificate
:: ========================================
:sign_ev
echo [1/2] Signing installer...
"!SIGNTOOL!" sign /n "%SIGN_CERT_NAME%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%INSTALLER_EXE%"
if errorlevel 1 (
    echo [ERROR] Failed to sign installer
    exit /b 1
)
echo [2/2] Verifying...
"!SIGNTOOL!" verify /pa "%INSTALLER_EXE%"
goto :sign_complete

:: ========================================
:: Sign files with PFX
:: ========================================
:do_sign
echo [1/2] Signing installer: %INSTALLER_EXE%
"!SIGNTOOL!" sign /f "%CERT_FILE%" /p "%CERT_PASS%" /fd SHA256 "%INSTALLER_EXE%"
if errorlevel 1 (
    echo [ERROR] Failed to sign installer
    exit /b 1
)
echo [OK] Installer signed successfully

echo [2/2] Verifying signature...
"!SIGNTOOL!" verify /pa "%INSTALLER_EXE%" >nul 2>&1
if errorlevel 1 (
    echo [WARN] Untrusted root - normal for self-signed certs
) else (
    echo [OK] Signature verified
)
goto :sign_complete

:: ========================================
:: Find signtool.exe
:: ========================================
:find_signtool
set "SIGNTOOL="
where signtool >nul 2>&1
if %errorlevel% equ 0 (
    set "SIGNTOOL=signtool"
    exit /b 0
)
for %%V in (10.0.26100.0 10.0.22621.0 10.0.22000.0 10.0.19041.0 10.0.18362.0 10.0.17763.0) do (
    if exist "%ProgramFiles(x86)%\Windows Kits\10\bin\%%V\x64\signtool.exe" (
        set "SIGNTOOL=%ProgramFiles(x86)%\Windows Kits\10\bin\%%V\x64\signtool.exe"
        exit /b 0
    )
)
exit /b 1

:: ========================================
:: Signing Complete
:: ========================================
:sign_complete
echo.
echo ========================================
echo   Signing Complete!
echo ========================================
echo.
echo Signed installer: %INSTALLER_EXE%
echo.
echo ========================================
echo   Certificate Info
echo ========================================
echo Path: %CERT_FILE%
echo.
if not defined SIGN_CERT_PATH (
    if not defined SIGN_CERT_NAME (
        echo NOTE: Self-signed cert shows SmartScreen warnings.
        echo       To trust on target PC [run as admin]:
        echo       certutil -addstore TrustedPublisher "%SELF_SIGN_CERT%"
    )
)
echo.
echo ========================================
