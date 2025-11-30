@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
setlocal enabledelayedexpansion

:: ========================================
:: ClickMate - Code Signing Script
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

set "PORTABLE_DIR=releases\v%VERSION%\ClickMate_v%VERSION%_Portable"
set "CERT_DIR=%USERPROFILE%\.clickmate_certs"
set "SELF_SIGN_CERT=%CERT_DIR%\clickmate_selfsign.pfx"
set "SELF_SIGN_PASS=ClickMate2024"

echo Version: %VERSION%
echo Target: %PORTABLE_DIR%
echo.

:: Check if portable directory exists
if not exist "%PORTABLE_DIR%" (
    echo [ERROR] Portable directory not found: %PORTABLE_DIR%
    echo Please run build_release.bat first
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
echo [1/3] Signing clickmate.exe...
"!SIGNTOOL!" sign /n "%SIGN_CERT_NAME%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%PORTABLE_DIR%\clickmate.exe"
echo [2/3] Signing mouse_controller.dll...
"!SIGNTOOL!" sign /n "%SIGN_CERT_NAME%" /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "%PORTABLE_DIR%\mouse_controller.dll"
echo [3/3] Verifying...
"!SIGNTOOL!" verify /pa "%PORTABLE_DIR%\clickmate.exe"
goto :sign_complete

:: ========================================
:: Sign files with PFX
:: ========================================
:do_sign
echo [1/4] Signing clickmate.exe...
"!SIGNTOOL!" sign /f "%CERT_FILE%" /p "%CERT_PASS%" /fd SHA256 "%PORTABLE_DIR%\clickmate.exe"
if errorlevel 1 (
    echo [ERROR] Failed to sign clickmate.exe
    exit /b 1
)
echo [OK] clickmate.exe signed

echo [2/4] Signing mouse_controller.dll...
"!SIGNTOOL!" sign /f "%CERT_FILE%" /p "%CERT_PASS%" /fd SHA256 "%PORTABLE_DIR%\mouse_controller.dll"
echo [OK] mouse_controller.dll signed

echo [3/4] Signing other DLLs...
for %%F in ("%PORTABLE_DIR%\*.dll") do (
    "!SIGNTOOL!" sign /f "%CERT_FILE%" /p "%CERT_PASS%" /fd SHA256 "%%F" >nul 2>&1
)
echo [OK] All DLLs processed

echo [4/4] Verifying signature...
"!SIGNTOOL!" verify /pa "%PORTABLE_DIR%\clickmate.exe" >nul 2>&1
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

:: Create ZIP
echo Creating signed ZIP package...
set "OUTPUT_DIR=releases\v%VERSION%"
del "%OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip" 2>nul
powershell -NoProfile -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip' -Force"

echo.
echo [OK] Signed package: %OUTPUT_DIR%\ClickMate_v%VERSION%_Portable.zip
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
