import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'version.dart';

/// Upgrade check result
class UpgradeInfo {
  final String latestVersion;
  final String currentVersion;
  final String downloadUrl;
  final String releaseNotes;
  final int fileSize;
  final String fileName;
  final bool hasUpdate;

  UpgradeInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.fileName,
    required this.hasUpdate,
  });
}

/// Download progress callback
typedef DownloadProgressCallback = void Function(int received, int total);

/// Upgrade service - handles version checking, downloading, and installation
class UpgradeService {
  static final UpgradeService instance = UpgradeService._internal();
  factory UpgradeService() => instance;
  UpgradeService._internal();

  // GitHub releases API URL
  static const String _githubReleasesUrl =
      'https://api.github.com/repos/zhaibin/ClickMate/releases/latest';
  
  // Alternative: Custom update server URL
  // static const String _updateServerUrl = 'https://clickmate.xants.net/api/version';

  // Download state
  bool _isDownloading = false;
  bool _isChecking = false;
  double _downloadProgress = 0.0;
  String? _downloadedFilePath;
  UpgradeInfo? _cachedUpgradeInfo;

  bool get isDownloading => _isDownloading;
  bool get isChecking => _isChecking;
  double get downloadProgress => _downloadProgress;
  String? get downloadedFilePath => _downloadedFilePath;
  UpgradeInfo? get cachedUpgradeInfo => _cachedUpgradeInfo;

  /// Check for updates from GitHub releases
  Future<UpgradeInfo?> checkForUpdates() async {
    if (_isChecking) return null;
    _isChecking = true;

    try {
      print('Checking for updates...');
      
      final response = await http.get(
        Uri.parse(_githubReleasesUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ClickMate/$appVersion',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return _parseGitHubRelease(data);
      } else if (response.statusCode == 403) {
        print('GitHub API rate limit exceeded');
        return null;
      } else {
        print('Failed to check updates: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    } finally {
      _isChecking = false;
    }
  }

  /// Parse GitHub release response
  UpgradeInfo? _parseGitHubRelease(Map<String, dynamic> data) {
    try {
      final tagName = data['tag_name'] as String? ?? '';
      final latestVersion = tagName.replaceFirst('v', '');
      final releaseNotes = data['body'] as String? ?? '';
      final assets = data['assets'] as List<dynamic>? ?? [];

      // Determine platform-specific asset
      // macOS: .dmg, Windows: .exe (installer like ClickMate_v2.0.0_Setup.exe)
      
      String? downloadUrl;
      int fileSize = 0;
      String fileName = '';

      if (Platform.isMacOS) {
        // macOS: find .dmg file
        for (final asset in assets) {
          final assetName = asset['name'] as String? ?? '';
          if (assetName.endsWith('.dmg')) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileSize = asset['size'] as int? ?? 0;
            fileName = assetName;
            break;
          }
        }
      } else {
        // Windows: prioritize Setup.exe installer
        // Example: ClickMate_v2.0.0_Setup.exe
        
        // First try: find *_Setup.exe or *_Installer.exe
        for (final asset in assets) {
          final assetName = asset['name'] as String? ?? '';
          final lowerName = assetName.toLowerCase();
          if (assetName.endsWith('.exe') && 
              (lowerName.contains('setup') || lowerName.contains('installer'))) {
            downloadUrl = asset['browser_download_url'] as String?;
            fileSize = asset['size'] as int? ?? 0;
            fileName = assetName;
            break;
          }
        }

        // Second try: find any .exe file
        if (downloadUrl == null) {
          for (final asset in assets) {
            final assetName = asset['name'] as String? ?? '';
            if (assetName.endsWith('.exe')) {
              downloadUrl = asset['browser_download_url'] as String?;
              fileSize = asset['size'] as int? ?? 0;
              fileName = assetName;
              break;
            }
          }
        }

        // Third try: fallback to .zip portable version
        if (downloadUrl == null) {
          for (final asset in assets) {
            final assetName = asset['name'] as String? ?? '';
            if (assetName.endsWith('.zip')) {
              downloadUrl = asset['browser_download_url'] as String?;
              fileSize = asset['size'] as int? ?? 0;
              fileName = assetName;
              break;
            }
          }
        }
      }

      if (downloadUrl == null) {
        print('No suitable asset found for ${Platform.isMacOS ? "macOS" : "Windows"}');
        return null;
      }

      final hasUpdate = _compareVersions(latestVersion, appVersion) > 0;

      final upgradeInfo = UpgradeInfo(
        latestVersion: latestVersion,
        currentVersion: appVersion,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        fileSize: fileSize,
        fileName: fileName,
        hasUpdate: hasUpdate,
      );

      _cachedUpgradeInfo = upgradeInfo;

      print('Latest version: $latestVersion, Current: $appVersion, Has update: $hasUpdate');
      return upgradeInfo;
    } catch (e) {
      print('Error parsing release data: $e');
      return null;
    }
  }

  /// Compare two version strings (e.g., "2.0.0" vs "2.1.0")
  /// Returns: positive if v1 > v2, negative if v1 < v2, 0 if equal
  int _compareVersions(String v1, String v2) {
    final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad with zeros if needed
    while (parts1.length < 3) parts1.add(0);
    while (parts2.length < 3) parts2.add(0);

    for (int i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  }

  /// Download the update file with progress reporting
  Future<String?> downloadUpdate(
    UpgradeInfo info, {
    DownloadProgressCallback? onProgress,
  }) async {
    if (_isDownloading) return null;
    _isDownloading = true;
    _downloadProgress = 0.0;

    try {
      print('Starting download: ${info.downloadUrl}');

      final request = http.Request('GET', Uri.parse(info.downloadUrl));
      request.headers['User-Agent'] = 'ClickMate/$appVersion';

      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        print('Download failed: HTTP ${response.statusCode}');
        return null;
      }

      // Get download directory
      final tempDir = await getTemporaryDirectory();
      final downloadPath = '${tempDir.path}/${info.fileName}';
      final file = File(downloadPath);

      // Download with progress
      final contentLength = response.contentLength ?? info.fileSize;
      int received = 0;
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        _downloadProgress = contentLength > 0 ? received / contentLength : 0;
        onProgress?.call(received, contentLength);
      }

      await sink.close();

      print('Download complete: $downloadPath');
      _downloadedFilePath = downloadPath;
      return downloadPath;
    } catch (e) {
      print('Download error: $e');
      return null;
    } finally {
      _isDownloading = false;
    }
  }

  /// Start the upgrade process (close app and run upgrade script)
  Future<bool> startUpgrade() async {
    if (_downloadedFilePath == null) {
      print('No downloaded file to install');
      return false;
    }

    try {
      final downloadedFile = File(_downloadedFilePath!);
      if (!await downloadedFile.exists()) {
        print('Downloaded file not found: $_downloadedFilePath');
        return false;
      }

      // Get application directory
      final appDir = _getAppDirectory();
      print('App directory: $appDir');

      if (Platform.isWindows) {
        return await _startWindowsUpgrade(appDir);
      } else if (Platform.isMacOS) {
        return await _startMacOSUpgrade(appDir);
      }

      return false;
    } catch (e) {
      print('Error starting upgrade: $e');
      return false;
    }
  }

  /// Get the application installation directory
  String _getAppDirectory() {
    if (Platform.isWindows) {
      // Get the directory where the exe is located
      final exePath = Platform.resolvedExecutable;
      return File(exePath).parent.path;
    } else if (Platform.isMacOS) {
      // Get the .app bundle directory
      final exePath = Platform.resolvedExecutable;
      // Navigate up from Contents/MacOS/app to get .app directory
      return File(exePath).parent.parent.parent.path;
    }
    return '';
  }

  /// Start Windows upgrade process
  Future<bool> _startWindowsUpgrade(String appDir) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final scriptPath = '${tempDir.path}/clickmate_upgrade.bat';
      final downloadedPath = _downloadedFilePath!;
      final isInstaller = downloadedPath.toLowerCase().endsWith('.exe');

      String script;
      
      if (isInstaller) {
        // For .exe installer (Inno Setup): run the installer directly
        // Get the install directory from registry or use default
        script = '''
@echo off
chcp 65001 > nul
setlocal EnableDelayedExpansion

echo ========================================
echo ClickMate Upgrade Script
echo ========================================
echo.

:: Wait for the application to close
echo Waiting for application to close...
set RETRY=0
:waitloop
tasklist /FI "IMAGENAME eq clickmate.exe" 2>NUL | find /I /N "clickmate">NUL
if "%ERRORLEVEL%"=="0" (
    set /a RETRY+=1
    if !RETRY! gtr 30 (
        echo Timeout waiting for application to close.
        echo Please close ClickMate manually and press any key...
        pause
    )
    timeout /t 1 /nobreak > nul
    goto waitloop
)
echo Application closed.
echo.

:: Run the installer with Inno Setup silent parameters
echo Running installer...
echo Please wait, installing new version...
"$downloadedPath" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /CLOSEAPPLICATIONS /SP-
set INSTALL_RESULT=%ERRORLEVEL%
if %INSTALL_RESULT% neq 0 (
    echo.
    echo ERROR: Installation failed with code %INSTALL_RESULT%
    echo Please try running the installer manually: $downloadedPath
    pause
    exit /b 1
)
echo Installation complete.
echo.

:: Clean up downloaded installer
echo Cleaning up...
timeout /t 2 /nobreak > nul
del "$downloadedPath" > nul 2>&1
echo.

:: Find and start the installed application
echo Starting ClickMate...
set "INSTALL_PATH="
for /f "tokens=2*" %%a in ('reg query "HKCU\\Software\\ClickMate" /v "InstallPath" 2^>nul') do set "INSTALL_PATH=%%b"
if not defined INSTALL_PATH (
    for /f "tokens=2*" %%a in ('reg query "HKLM\\Software\\ClickMate" /v "InstallPath" 2^>nul') do set "INSTALL_PATH=%%b"
)
if not defined INSTALL_PATH (
    set "INSTALL_PATH=%LOCALAPPDATA%\\Programs\\ClickMate"
)
if exist "!INSTALL_PATH!\\clickmate.exe" (
    start "" "!INSTALL_PATH!\\clickmate.exe"
) else if exist "%LOCALAPPDATA%\\Programs\\ClickMate\\clickmate.exe" (
    start "" "%LOCALAPPDATA%\\Programs\\ClickMate\\clickmate.exe"
) else if exist "%PROGRAMFILES%\\ClickMate\\clickmate.exe" (
    start "" "%PROGRAMFILES%\\ClickMate\\clickmate.exe"
) else (
    echo Warning: Could not find ClickMate.exe to restart.
    echo Please start the application manually.
)

echo ========================================
echo Upgrade completed successfully!
echo ========================================
timeout /t 2 /nobreak > nul

:: Delete this script
del "%~f0" > nul 2>&1
exit
''';
      } else {
        // For .zip portable: extract and replace
        final exePath = Platform.resolvedExecutable;
        script = '''
@echo off
chcp 65001 > nul
setlocal

echo ========================================
echo ClickMate Upgrade Script
echo ========================================
echo.

:: Wait for the application to close
echo Waiting for application to close...
:waitloop
tasklist /FI "IMAGENAME eq clickmate.exe" 2>NUL | find /I /N "clickmate.exe">NUL
if "%ERRORLEVEL%"=="0" (
    timeout /t 1 /nobreak > nul
    goto waitloop
)
echo Application closed.
echo.

:: Backup current version (optional)
echo Creating backup...
set BACKUP_DIR=%TEMP%\\clickmate_backup_%DATE:~0,4%%DATE:~5,2%%DATE:~8,2%
if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
xcopy "$appDir\\*" "%BACKUP_DIR%\\" /E /I /H /Y > nul 2>&1
echo Backup created: %BACKUP_DIR%
echo.

:: Extract new version
echo Extracting new version...
cd /d "$appDir"
powershell -Command "Expand-Archive -Path '$downloadedPath' -DestinationPath '$appDir' -Force"
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to extract update!
    echo Restoring backup...
    xcopy "%BACKUP_DIR%\\*" "$appDir\\" /E /I /H /Y > nul 2>&1
    pause
    exit /b 1
)
echo Extraction complete.
echo.

:: Clean up
echo Cleaning up...
del "$downloadedPath" > nul 2>&1
del "$scriptPath" > nul 2>&1
echo.

:: Restart application
echo Starting ClickMate...
start "" "$exePath"

echo ========================================
echo Upgrade completed successfully!
echo ========================================
timeout /t 3 > nul
exit
''';
      }

      await File(scriptPath).writeAsString(script);
      print('Created upgrade script: $scriptPath (installer: $isInstaller)');

      // Run the upgrade script
      await Process.start(
        'cmd',
        ['/c', 'start', '', scriptPath],
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('Error creating Windows upgrade script: $e');
      return false;
    }
  }

  /// Start macOS upgrade process
  Future<bool> _startMacOSUpgrade(String appDir) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final scriptPath = '${tempDir.path}/clickmate_upgrade.sh';
      final dmgPath = _downloadedFilePath!;
      final appName = 'ClickMate.app';
      final applicationsDir = '/Applications';

      // Create upgrade shell script
      final script = '''
#!/bin/bash

echo "========================================"
echo "ClickMate Upgrade Script"
echo "========================================"
echo ""

# Wait for the application to close
echo "Waiting for application to close..."
while pgrep -x "ClickMate" > /dev/null; do
    sleep 1
done
echo "Application closed."
echo ""

# Mount DMG
echo "Mounting disk image..."
MOUNT_POINT=\$(hdiutil attach "$dmgPath" -nobrowse -noautoopen | grep "/Volumes" | cut -f3)
if [ -z "\$MOUNT_POINT" ]; then
    echo "ERROR: Failed to mount DMG!"
    exit 1
fi
echo "Mounted at: \$MOUNT_POINT"
echo ""

# Backup current version
echo "Creating backup..."
BACKUP_DIR="/tmp/clickmate_backup_\$(date +%Y%m%d_%H%M%S)"
if [ -d "$applicationsDir/$appName" ]; then
    cp -R "$applicationsDir/$appName" "\$BACKUP_DIR"
    echo "Backup created: \$BACKUP_DIR"
fi
echo ""

# Copy new version
echo "Installing new version..."
rm -rf "$applicationsDir/$appName"
cp -R "\$MOUNT_POINT/$appName" "$applicationsDir/"
if [ \$? -ne 0 ]; then
    echo "ERROR: Failed to install update!"
    echo "Restoring backup..."
    if [ -d "\$BACKUP_DIR" ]; then
        cp -R "\$BACKUP_DIR" "$applicationsDir/$appName"
    fi
    hdiutil detach "\$MOUNT_POINT" -quiet
    exit 1
fi
echo "Installation complete."
echo ""

# Unmount DMG
echo "Cleaning up..."
hdiutil detach "\$MOUNT_POINT" -quiet
rm -f "$dmgPath"
rm -f "$scriptPath"
echo ""

# Restart application
echo "Starting ClickMate..."
open "$applicationsDir/$appName"

echo "========================================"
echo "Upgrade completed successfully!"
echo "========================================"
sleep 3
''';

      await File(scriptPath).writeAsString(script);
      await Process.run('chmod', ['+x', scriptPath]);
      print('Created upgrade script: $scriptPath');

      // Run the upgrade script in a new terminal
      await Process.start(
        'osascript',
        [
          '-e',
          'tell application "Terminal" to do script "$scriptPath"',
        ],
        mode: ProcessStartMode.detached,
      );

      return true;
    } catch (e) {
      print('Error creating macOS upgrade script: $e');
      return false;
    }
  }

  /// Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Reset download state
  void resetDownloadState() {
    _isDownloading = false;
    _downloadProgress = 0.0;
    _downloadedFilePath = null;
  }
}

