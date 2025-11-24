@echo off
chcp 65001 >nul

:: Receive parameters: target directory and version
set TARGET_DIR=%~1
set VERSION=%~2

if "%TARGET_DIR%"=="" (
    echo [ERROR] Usage: create_helper_files.bat ^<target_dir^> ^<version^>
    exit /b 1
)

:: ========================================
:: 1. Create Startup Script (START.bat)
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%~dp0"
echo.
echo :: ========================================
echo :: ClickMate - Startup Script v%VERSION%
echo :: ========================================
echo echo.
echo echo Starting ClickMate...
echo echo.
echo.
echo :: Check required files
echo if not exist "clickmate.exe" ^(
echo     echo [ERROR] clickmate.exe not found
echo     echo Please ensure you are running this script in the correct directory.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "flutter_windows.dll" ^(
echo     echo [ERROR] flutter_windows.dll not found
echo     echo Please download the complete package again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "window_manager_plugin.dll" ^(
echo     echo [ERROR] window_manager_plugin.dll not found
echo     echo Please download the complete package again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "screen_retriever_windows_plugin.dll" ^(
echo     echo [ERROR] screen_retriever_windows_plugin.dll not found
echo     echo Please download the complete package again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "mouse_controller.dll" ^(
echo     echo [ERROR] mouse_controller.dll not found
echo     echo Please download the complete package again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "data" ^(
echo     echo [ERROR] data folder not found
echo     echo Please download the complete package again.
echo     pause
echo     exit /b 1
echo ^)
echo.
echo :: Check administrator privileges
echo net session ^>nul 2^>^&1
echo if %%ERRORLEVEL%% NEQ 0 ^(
echo     echo ========================================
echo     echo   WARNING: Recommend running as admin
echo     echo ========================================
echo     echo.
echo     echo Hotkey functions require administrator privileges.
echo     echo.
echo     echo Run as administrator?
echo     echo.
echo     choice /C YN /M "Choose [Y]es [N]o"
echo     if %%ERRORLEVEL%% EQU 1 ^(
echo         powershell -Command "Start-Process '%%~f0' -Verb RunAs"
echo         exit
echo     ^) else ^(
echo         echo.
echo         echo Continuing with normal privileges...
echo         echo Note: Hotkey functions may not work.
echo         echo.
echo         timeout /t 2 ^>nul
echo     ^)
echo ^)
echo.
echo :: Start program
echo echo [OK] All checks passed, starting...
echo echo.
echo start "" "%%~dp0clickmate.exe"
echo.
echo :: Wait for program window to appear
echo timeout /t 2 /nobreak ^>nul
echo.
echo echo ========================================
echo echo   Program Started
echo echo ========================================
echo echo.
echo echo Tips:
echo echo - Default hotkey: Ctrl+Shift+1 ^(Start/Stop^)
echo echo - Capture position: Ctrl+Shift+2
echo echo - If hotkeys don't work, run as administrator
echo echo - Log location: %%USERPROFILE%%\Documents\ClickMate\logs
echo echo.
echo echo If program window doesn't appear, possible reasons:
echo echo 1. Missing Visual C++ Runtime ^(install VC++ Redistributable^)
echo echo 2. Antivirus blocking ^(add to trusted^)
echo echo 3. Windows version too old ^(requires Windows 10+^)
echo echo.
echo echo Check logs for detailed error information:
echo echo %%USERPROFILE%%\Documents\ClickMate\logs\app_*.log
echo echo.
echo pause
) > "%TARGET_DIR%\START.bat"

:: ========================================
:: 2. Create User Manual (README.txt)
:: ========================================
(
echo ========================================
echo   ClickMate v%VERSION% - User Manual
echo ========================================
echo.
echo I. Quick Start
echo ------------
echo 1. Double-click "START.bat" to launch
echo 2. Recommend running as administrator ^(for hotkey functions^)
echo 3. Test basic functions first
echo.
echo.
echo II. Main Features
echo ------------
echo [OK] Auto mouse clicking
echo [OK] Left/Right/Middle button options
echo [OK] Custom click interval
echo [OK] Random time offset
echo [OK] Random position offset
echo [OK] Global hotkey control
echo [OK] Click history
echo.
echo.
echo III. Operating Modes
echo ------------
echo [Auto-tracking Mode] ^(Default^)
echo - Follows mouse position in real-time
echo - Green "Auto" label
echo - Suitable for scenarios requiring position adjustments
echo.
echo [Manual Input Mode]
echo - Click X or Y input box to switch
echo - Or click refresh button to switch
echo - Gray "Manual" label
echo - Suitable for fixed position repeated clicking
echo.
echo.
echo IV. Hotkeys
echo ----------
echo Ctrl+Shift+1  Start/Stop auto-clicking
echo Ctrl+Shift+2  Capture current mouse position
echo.
echo WARNING:
echo - Hotkeys require administrator privileges
echo - If not working, right-click "START.bat" and "Run as administrator"
echo.
echo.
echo V. Parameter Description
echo ------------
echo [Click Interval]
echo - Time between two clicks ^(milliseconds^)
echo - Minimum: 100ms
echo - Recommended: 1000ms
echo.
echo [Random Offset +/-]
echo - Random variance on interval
echo - Example: Interval 1000ms, Offset +/-200ms
echo - Actual interval will be 800-1200ms
echo.
echo [Position Offset]
echo - Random offset range for click position ^(pixels^)
echo - Example: Offset 10, actual click within +/-10 pixels
echo - Used to simulate human clicking
echo.
echo.
echo VI. FAQ
echo ------------
echo [Q1] Hotkeys not working?
echo A: Need to run as administrator, right-click "START.bat" -^> "Run as administrator"
echo.
echo [Q2] Program won't start?
echo A: Ensure Visual C++ Redistributable is installed
echo    Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.
echo [Q3] Clicking inaccurate?
echo A: Check position offset settings, set to 0 for precise clicking
echo.
echo [Q4] How to view logs?
echo A: Double-click "VIEW_LOGS.bat", or manually open
echo    %%USERPROFILE%%\Documents\ClickMate\logs\
echo.
echo [Q5] How to uninstall?
echo A: Simply delete the entire folder, no residue
echo.
echo.
echo VII. Technical Support
echo ------------
echo Version: v%VERSION%
echo Requirements: Windows 10/11
echo Log location: %%USERPROFILE%%\Documents\ClickMate\logs\
echo.
echo Check log files for detailed information if issues occur.
echo.
echo ========================================
echo   Enjoy!
echo ========================================
) > "%TARGET_DIR%\README.txt"

:: ========================================
:: 3. Create FAQ (FAQ.txt)
:: ========================================
(
echo ========================================
echo   Frequently Asked Questions ^(FAQ^)
echo ========================================
echo.
echo [1] Program doesn't respond when double-clicked?
echo.
echo   Symptom: No window appears after double-clicking clickmate.exe
echo.
echo   Solutions:
echo   [OK] Right-click "START.bat" -^> "Run as administrator"
echo   [OK] Check for missing DLL files
echo   [OK] Check Task Manager if already running
echo   [OK] View logs: %%USERPROFILE%%\Documents\ClickMate\logs\
echo.
echo   If still won't start:
echo   - Install Visual C++ Redistributable
echo     Download: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo   - Check if antivirus is blocking
echo   - Try running on Windows 10/11
echo.
echo.
echo [2] Hotkeys not responding?
echo.
echo   Symptom: Pressing Ctrl+Shift+1/2 has no effect
echo.
echo   Solutions:
echo   [OK] Must run as administrator
echo   [OK] Right-click "START.bat" -^> "Run as administrator"
echo   [OK] Or right-click "clickmate.exe" -^> "Run as administrator"
echo.
echo   How to check:
echo   1. Open program
echo   2. View console output
echo   3. Look for "Hotkey registered successfully" message
echo   4. Check log file for hotkey status
echo.
echo.
echo [3] Cannot find window_manager_plugin.dll?
echo.
echo   Symptom: Missing DLL error on startup
echo.
echo   Solutions:
echo   [OK] Confirm these files are in same directory:
echo     - clickmate.exe
echo     - flutter_windows.dll
echo     - window_manager_plugin.dll
echo     - screen_retriever_windows_plugin.dll
echo     - mouse_controller.dll
echo     - data\ folder
echo.
echo   [OK] If files incomplete, download full package again
echo   [OK] Extract using "Extract to current folder"
echo.
echo.
echo [4] Click position inaccurate?
echo.
echo   Symptom: Click position deviates from target
echo.
echo   Solutions:
echo   [OK] Set "Position Offset" to 0
echo   [OK] Use "Manual Input Mode" for precise coordinates
echo   [OK] Disable "Random Offset +/-"
echo   [OK] Use Ctrl+Shift+2 to capture precise position
echo.
echo.
echo [5] How to view detailed logs?
echo.
echo   Method 1: Double-click "VIEW_LOGS.bat"
echo   Method 2: Open manually
echo     - Press Win+R
echo     - Type: %%USERPROFILE%%\Documents\ClickMate\logs
echo     - Open latest app_*.log file
echo.
echo   Logs contain:
echo   - Program startup info
echo   - Hotkey registration status
echo   - Click statistics
echo   - Detailed error info
echo.
echo.
echo [6] Program using too much CPU/Memory?
echo.
echo   Normal usage:
echo   - CPU: ^<1%%
echo   - Memory: 50-100MB
echo.
echo   If abnormal:
echo   1. Stop auto-clicking
echo   2. Restart program
echo   3. Check if click interval too small ^(recommend >=100ms^)
echo   4. Check logs for error loops
echo.
echo.
echo [7] Want to use on another computer?
echo.
echo   Solutions:
echo   [OK] This is portable version, just copy entire folder
echo   [OK] Target PC needs: Windows 10/11
echo   [OK] Target PC needs: Visual C++ Redistributable
echo   [OK] No installation needed, no registry residue
echo.
echo.
echo [8] How to completely uninstall?
echo.
echo   Uninstall steps:
echo   1. Close program
echo   2. Delete entire program folder
echo   3. ^(Optional^) Delete log folder:
echo      %%USERPROFILE%%\Documents\ClickMate\
echo.
echo   Note: Program doesn't write to registry, no other residue.
echo.
echo.
echo [9] Which Windows versions are supported?
echo.
echo   Supported versions:
echo   [OK] Windows 10 ^(1809 and higher^)
echo   [OK] Windows 11 ^(all versions^)
echo.
echo   Unsupported versions:
echo   [X] Windows 7
echo   [X] Windows 8/8.1
echo.
echo.
echo [10] Is the program safe? Any viruses?
echo.
echo   Security statement:
echo   [OK] This is an open-source project
echo   [OK] Only uses official Windows APIs
echo   [OK] No internet connection, no data upload
echo   [OK] Doesn't modify system files
echo   [OK] Doesn't write to registry
echo   [OK] Source code available for review
echo.
echo   Antivirus may false-positive:
echo   - Because it uses global hotkey API
echo   - Because it uses mouse control API
echo   - Please add to whitelist
echo.
echo.
echo ========================================
echo   Still have questions? Check log files
echo   %%USERPROFILE%%\Documents\ClickMate\logs\
echo ========================================
) > "%TARGET_DIR%\FAQ.txt"

:: ========================================
:: 4. Create View Logs Script (VIEW_LOGS.bat)
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo.
echo Opening log directory...
echo.
echo Log location: %%USERPROFILE%%\Documents\ClickMate\logs
echo.
echo Press any key to open log folder...
echo pause ^>nul
echo.
echo explorer "%%USERPROFILE%%\Documents\ClickMate\logs"
) > "%TARGET_DIR%\VIEW_LOGS.bat"

:: ========================================
:: 5. Create Debug Startup Script (DEBUG_START.bat)
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%~dp0"
echo.
echo ========================================
echo   Debug Mode - Show Detailed Logs
echo ========================================
echo.
echo This mode displays all debug information for diagnostics.
echo Window will not auto-close, you can view complete output.
echo.
echo ========================================
echo.
echo Starting...
echo.
echo.
echo "%%~dp0clickmate.exe"
echo.
echo.
echo ========================================
echo   Program Closed
echo ========================================
echo.
echo If program closes immediately, possible reasons:
echo 1. Missing required DLL files
echo 2. Visual C++ Runtime not installed
echo 3. Insufficient permissions
echo.
echo Please check error messages above.
echo.
echo pause
) > "%TARGET_DIR%\DEBUG_START.bat"

echo [OK] All helper files created in: %TARGET_DIR%
exit /b 0
