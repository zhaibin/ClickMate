# Changelog

All notable changes to ClickMate will be documented in this file.

## [2.2.0] - 2025-12-15

### ✨ New Features

**Smart Auto-Pause/Resume System**
- Auto-pause when mouse moves away from target area (configurable threshold)
- Smart auto-resume: automatically returns mouse to target after 5 seconds of stillness
- Works from any position - no need to manually move mouse back to target area
- Prevents accidental clicks during multitasking or window switching
- Visual status indicator: Orange (paused) / Green (active)

**Enhanced Position Monitoring**
- Configurable deviation threshold (minimum 10px)
- Real-time distance monitoring with 200ms polling interval
- Intelligent idle detection (tracks mouse movements > 5px)
- Race condition prevention: stops monitoring during mouse repositioning
- Debug logging for troubleshooting

### 🎨 UI Improvements

- New "Auto-Pause/Resume" checkbox in settings
- Deviation threshold input field with validation
- Status indicator shows pause/resume state
- Multi-language support for new features (11 languages)

### 🌍 Internationalization

Updated translations for auto-pause/resume feature:
- English: "Auto-pause when moved away, resume after 5s stillness anywhere"
- 简体中文: "偏离时自动暂停，任意位置静止5秒后恢复"
- 繁體中文: "偏離時自動暫停，任意位置靜止5秒後恢復"
- Français, Español, Português, Deutsch, Русский, Italiano, 日本語, 한국어

### 🔧 Technical Changes

- Enhanced `MouseControllerService` with position monitoring
- Added `_startPositionMonitoring()` and `_stopPositionMonitoring()` methods
- Implemented `_calculateDistance()` for Euclidean distance calculation
- Added `_resumeFromDeviation()` with timer management
- Timer-based resume system with cancellation on movement
- 500ms delay before restarting monitoring after resume

### 🐛 Bug Fixes

- Fixed race condition between mouse move and position detection
- Proper timer cleanup on resume/stop
- Accurate idle time tracking with movement threshold
- Fixed window height overflow causing Click History to be cut off (640px → 720px)
- Fixed blurry icons on Windows high-DPI displays (ICO now includes 16-256px layers)
- Fixed upgrade script not finding app in Program Files (x86) directory

## [2.1.0] - 2025-12-01

### ✨ New Features

**Auto-Upgrade System**
- Automatic version check on startup (3 seconds after launch)
- Manual "Check for Updates" option in menu
- Download progress indicator with percentage
- One-click upgrade with automatic restart
- Cross-platform support (Windows installer & macOS DMG)

**Windows Upgrade**
- Download and run `.exe` installer automatically
- Inno Setup compatible with silent installation
- Auto-detect installed application path
- Automatic restart after upgrade

**macOS Upgrade**
- Download and mount `.dmg` automatically
- Replace application in `/Applications`
- Automatic restart after upgrade

### 🐛 Bug Fixes

**macOS Distribution Critical Fix**
- Fixed: DMG-distributed app failed to load `libmouse_controller.dylib`
- Solution: Dylib is now automatically copied to `ClickMate.app/Contents/Frameworks/`
- Updated `build_dmg.sh` script to handle native library packaging
- Set correct install_name using `@executable_path/../Frameworks/` path
- Updated `mouse_controller_bindings.dart` to prioritize Frameworks directory

**macOS "Damaged App" Issue**
- Added comprehensive installation guide for macOS users
- Created `docs/macOS_INSTALL_GUIDE.md` with step-by-step solutions
- Added installation instructions file (`macOS_安装说明.txt`) to releases
- Updated README.md with link to troubleshooting guide
- Documented `xattr -cr` command to remove quarantine attribute

### 🔧 Technical Changes

- New `UpgradeService` class for version management
- GitHub Releases API integration for version checking
- Platform-specific upgrade scripts (batch for Windows, shell for macOS)
- HTTP package added for network requests
- Multi-language support for upgrade UI (11 languages)
- Enhanced `build_dmg.sh` with native library packaging (6 steps)
- Updated BUILD_GUIDE.md with dylib packaging instructions

### 📦 Distribution

- Windows: `ClickMate_v2.1.0_Setup.exe`
- macOS: `ClickMate_v2.1.0_macOS.dmg`

---

## [2.0.0] - 2025-11-30

### 🎉 Major Release - Cross-Platform Support

This release introduces full macOS support, making ClickMate a true cross-platform application.

### ✨ New Features

**macOS Support**
- Full macOS platform support (10.14+)
- Native Objective-C++ implementation using CoreGraphics and Carbon APIs
- macOS-specific hotkey system with Command key support
- Native mouse control (click, move, position capture)
- Accessibility permission handling
- macOS-style Traffic Lights window buttons (close/minimize)
- DMG installer packaging with custom background
- Code signing support for macOS distribution

**Windows Enhancements**
- Self-signed code signing for Windows releases
- Auto-detect signtool from Windows SDK
- Installer-based distribution (Inno Setup)
- Improved window corner consistency

**Custom Titlebar**
- Frameless window design (removed default Windows titlebar)
- Custom window control buttons
  - Windows: Right-aligned minimize/close buttons with hover effects
  - macOS: Left-aligned Traffic Lights style buttons
- Draggable titlebar area
- Platform-adaptive button styling

**UI/UX Improvements**
- Unified design language across platforms
- Consistent window corners (rounded on both platforms)
- Simplified language selection (removed "Follow System" option)
- Direct language picker in title bar
- Refined visual appearance

**Startup Optimization**
- Fixed window startup flicker on Windows
- Window now appears at correct size and position immediately
- Synchronized native window size with Flutter window options
- Centered window on screen at startup

### 🔧 Technical Changes

- Added `macos/` directory with complete platform configuration
- New `native/src/mouse_controller_macos.mm` - macOS native implementation
- New `native/src/libmouse_controller.dylib` - macOS dynamic library
- Updated `windows/runner/main.cpp` for proper window initialization
- Added `_WindowsControlButton` widget for Windows titlebar
- Modified `WindowOptions` with `TitleBarStyle.hidden`
- Platform-conditional UI rendering for window controls
- Cross-platform architecture with platform-specific native code
- New signing scripts for both platforms
- DMG packaging script for macOS

### 📦 Distribution

**Windows**
- Installer: `ClickMate_v2.0.0_Setup.exe` (signed)
- Portable: `ClickMate_v2.0.0_Portable.zip`
- Built with Inno Setup
- Self-signed certificate for reduced SmartScreen warnings

**macOS**
- DMG: `ClickMate_v2.0.0.dmg`
- Drag-and-drop installation
- Code signed for Gatekeeper compatibility

### 🐛 Bug Fixes

- Fixed window appearing at wrong size then resizing on Windows
- Fixed window appearing at (10, 10) then moving to center
- Fixed app icon being too close to left edge on Windows
- Fixed initState context access crash during startup

---

## [1.1.0] - 2025-11-24

### ✨ New Features

**Configuration Management System**
- Save and load click configurations with automatic naming
- Multiple configuration profiles support
- Auto-save on click start (button or hotkey)
- Auto-save when parameters differ from existing configs
- Rename and delete configurations
- Configuration details display (position, interval, offset, button)
- Created/Updated timestamps for each config
- Visual highlighting of currently active configuration
- Auto-load last used configuration on startup
- Auto-switch to manual mode when loading config

**Smart Mouse Movement**
- New "Move" button to manually move mouse to target position
- Auto-move mouse when loading a configuration
- Visual notification showing target coordinates
- Compact button design next to "Start Clicking"

**Click Settings Enhancements**
- "Reset Defaults" button to quickly restore default values
- One-click reset: Interval=1000ms, Random=0ms, Offset=0px, Button=Left
- Compact button with icon in Click Settings header

**UI Improvements**
- Consolidated menu in title bar (replaced multiple buttons)
- Save/Manage/Settings options in popup menu
- Configuration dialog with list view
- Active config badge with blue highlight
- Inline edit and delete actions
- Color-coded mouse button indicators
- Compact window size (480x680)
- Persistent configuration storage using SharedPreferences

**Multi-language Support**
- Added translations for all new features across 11 languages
- New keys: config_*, btn_reset_defaults, btn_move_mouse, menu_*
- Languages: English, 简中, 繁中, Français, Español, Português, Deutsch, Русский, Italiano, 日本語, 한국어

### 🔧 Technical Changes
- Added `shared_preferences` dependency for configuration persistence
- New `ClickConfig` data model with JSON serialization
- New `ClickConfigService` for configuration CRUD operations
- New `ConfigManagementDialog` widget with interactive UI
- Callback mechanism for pre-start configuration saving
- Exposed `MouseControllerBindings` for direct mouse control
- CMakeLists.txt fix to ensure mouse_controller.dll is copied correctly
- Enhanced error handling in configuration service initialization
- Auto-load last used configuration on app startup
- Smart mode switching logic (auto→manual when loading config)

### 🐛 Bug Fixes
- Fixed DLL loading issue by updating CMakeLists.txt
- Added robust error handling for SharedPreferences initialization
- Fixed configuration service crash on initialization failure
- Ensured consistent behavior between button and hotkey start

---

## [1.0.0] - 2024-11-24

### 🎉 Initial Release

ClickMate - A professional mouse auto-clicker for Windows with global hotkey support.

#### ✨ Core Features

**Auto Clicking**
- Left / Right / Middle mouse button support
- Custom click interval (minimum 100ms)
- Random time offset for natural clicking
- Random position offset for human-like behavior

**Position Modes**
- Auto-tracking mode (follows mouse in real-time)
- Manual input mode (fixed coordinates)
- One-click mode switching
- Capture current mouse position with hotkey

**Global Hotkeys**
- `Ctrl+Shift+1` - Start/Stop auto-clicking
- `Ctrl+Shift+2` - Capture current position
- Works system-wide (requires administrator privileges)

**Click History**
- Display last 10 clicks
- Timestamp with millisecond precision
- Position and button type tracking
- Color-coded button indicators (Blue/Orange/Purple)

**Multi-language Support**
- 11 languages: English, 简体中文, 繁體中文, Français, Español, Português, Deutsch, Русский, Italiano, 日本語, 한국어
- Auto-detect system language on first launch
- Easy language switching via title bar
- Language preference saved automatically

#### 🎨 Interface

- Clean and modern design
- Fixed window size (520x680)
- Real-time position and click count display
- Color-coded status indicators
- Intuitive controls and settings

#### 🔧 Technical Stack

- Flutter 3.10+
- C++ with Windows API
- FFI (Foreign Function Interface)
- window_manager 0.5.1
- logger 2.0.2

#### 📦 Distribution

- Portable version (no installation required)
- No registry modifications
- Self-contained executable with all dependencies
- Windows 10/11 compatible

#### ⚠️ Important Notes

- Administrator privileges required for global hotkeys
- Includes native DLL (`mouse_controller.dll`)
- All source code in English
- UI supports 11 languages

---

## System Requirements

### Windows
- Windows 10 version 1809 or higher
- Windows 11 (all versions)
- Visual C++ Redistributable 2022
- Administrator privileges (for hotkey functionality)

### macOS
- macOS 10.14 (Mojave) or higher
- Accessibility permission required
- Apple Silicon (M1/M2) and Intel supported

---

## Installation

### Windows
1. Extract the portable package
2. Right-click `START.bat` and select "Run as administrator"
3. Application launches automatically

### macOS
1. Build from source: `flutter build macos`
2. Open `ClickMate.app` from build folder
3. Grant Accessibility permission when prompted

---

## Usage

1. **Auto Mode (Default)**: Position follows mouse in real-time
2. **Manual Mode**: Click X/Y input fields or toggle button
3. **Start Clicking**: Press `Ctrl+Shift+1` (Win) or `⌘+Shift+1` (Mac)
4. **Capture Position**: Press `Ctrl+Shift+2` (Win) or `⌘+Shift+2` (Mac)

---

**License**: For personal and educational use only  
**Repository**: https://github.com/zhaibin/ClickMate
