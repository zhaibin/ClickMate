# Changelog

All notable changes to ClickMate will be documented in this file.

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

## [1.0.0] - 2025-11-24

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

- Windows 10 version 1809 or higher
- Windows 11 (all versions)
- Visual C++ Redistributable 2022
- Administrator privileges (for hotkey functionality)

## Installation

1. Extract the portable package
2. Right-click `START.bat` and select "Run as administrator"
3. Application launches automatically

## Usage

1. **Auto Mode (Default)**: Position follows mouse in real-time
2. **Manual Mode**: Click X/Y input fields or toggle button
3. **Start Clicking**: Press `Ctrl+Shift+1` or click Start button
4. **Capture Position**: Press `Ctrl+Shift+2`

---

**License**: For personal and educational use only  
**Repository**: https://github.com/zhaibin/ClickMate
