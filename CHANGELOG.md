# Changelog

All notable changes to ClickMate will be documented in this file.

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
