# Multilingual Support Guide / 多语言支持指南

## Overview / 概述

ClickMate v2.0.0 supports 11 languages with automatic system language detection on both Windows and macOS.

ClickMate v2.0.0 支持11种语言，在 Windows 和 macOS 上均可自动检测系统语言。

---

## 🌍 Supported Languages / 支持的语言

| # | Language | 语言 | Code |
|---|----------|------|------|
| 1 | 🇺🇸 English | 英语 | `en` |
| 2 | 🇨🇳 简体中文 | Simplified Chinese | `zh_CN` |
| 3 | 🇹🇼 繁體中文 | Traditional Chinese | `zh_TW` |
| 4 | 🇫🇷 Français | 法语 | `fr` |
| 5 | 🇪🇸 Español | 西班牙语 | `es` |
| 6 | 🇵🇹 Português | 葡萄牙语 | `pt` |
| 7 | 🇩🇪 Deutsch | 德语 | `de` |
| 8 | 🇷🇺 Русский | 俄语 | `ru` |
| 9 | 🇮🇹 Italiano | 意大利语 | `it` |
| 10 | 🇯🇵 日本語 | 日语 | `ja` |
| 11 | 🇰🇷 한국어 | 韩语 | `ko` |

---

## 🔄 How to Change Language / 如何切换语言

### Automatic Detection / 自动检测

**First Launch**: The application automatically detects your system language.

**首次启动**：应用程序自动检测系统语言。

| System Language | ClickMate Language |
|-----------------|-------------------|
| Chinese (China/Singapore) | 简体中文 |
| Chinese (Taiwan/Hong Kong/Macao) | 繁體中文 |
| Japanese | 日本語 |
| Korean | 한국어 |
| French | Français |
| German | Deutsch |
| Spanish | Español |
| Portuguese | Português |
| Russian | Русский |
| Italian | Italiano |
| Other | English (fallback) |

### Manual Switching / 手动切换

**Method 1: Using UI / 方法1：界面操作**

1. Click the **menu button** (⋯) in the title bar
   
   点击标题栏的**菜单按钮** (⋯)

2. Select **Language** / 选择**语言设置**

3. Choose your preferred language from the list
   
   从列表中选择你想要的语言

4. Language changes immediately and is saved automatically
   
   语言立即生效并自动保存

**Method 2: Configuration File / 方法2：配置文件**

Language preference is stored in:

| Platform | Path |
|----------|------|
| Windows | `%USERPROFILE%\Documents\ClickMate\language.txt` |
| macOS | `~/Documents/ClickMate/language.txt` |

Supported values: `en`, `zh_CN`, `zh_TW`, `fr`, `es`, `pt`, `de`, `ru`, `it`, `ja`, `ko`

---

## 🏗️ Technical Architecture / 技术架构

### File Structure / 文件结构

```
lib/
├── l10n/
│   └── app_localizations.dart    # All translations (11 languages)
├── language_preference.dart       # Language persistence & detection
└── main.dart                      # Localization integration
```

### Key Components / 关键组件

1. **AppLocalizations**
   - Contains all translation strings
   - Supports 11 languages
   - Centralized in single file for easy maintenance

2. **LanguagePreference**
   - Handles language persistence
   - Auto-detects system language on first launch
   - Cross-platform storage support

3. **MaterialApp Integration**
   - Uses Flutter's official localization framework
   - Supports dynamic language switching

### Code Example / 代码示例

```dart
// Getting translated text
final l10n = AppLocalizations.of(context);
Text(l10n.appTitle);  // "ClickMate"
Text(l10n.btnStart);  // "Start" / "开始" / "開始" / etc.

// Changing language
LanguagePreference.instance.changeLanguage(Locale('zh', 'CN'));
```

---

## 🔧 Adding New Languages / 添加新语言

### Step 1: Update AppLocalizations

Edit `lib/l10n/app_localizations.dart`:

```dart
// 1. Add to supportedLocales
static const List<Locale> supportedLocales = [
  Locale('en'),
  Locale('zh', 'CN'),
  // ... existing locales
  Locale('xx'),  // Add new locale
];

// 2. Add translation map
static const Map<String, String> _xxStrings = {
  'appTitle': 'ClickMate',
  'btnStart': 'Start',
  // ... all translation keys
};

// 3. Update _getLocalizedStrings()
Map<String, String> _getLocalizedStrings() {
  switch (locale.languageCode) {
    case 'xx':
      return _xxStrings;
    // ...
  }
}
```

### Step 2: Update Language Name

```dart
// In language_preference.dart or UI code
String getLanguageName(String code) {
  switch (code) {
    case 'xx': return 'New Language';
    // ...
  }
}
```

### Step 3: Test

1. Change system language to the new locale
2. Launch ClickMate
3. Verify all UI elements are translated

---

## 📝 Translation Keys / 翻译键

### Core UI / 核心界面

| Key | Description |
|-----|-------------|
| `appTitle` | Application title |
| `btnStart` | Start button |
| `btnStop` | Stop button |
| `labelX` / `labelY` | Coordinate labels |
| `labelInterval` | Interval setting |

### Configuration / 配置

| Key | Description |
|-----|-------------|
| `configSave` | Save configuration |
| `configManage` | Manage configurations |
| `configName` | Configuration name |
| `configDelete` | Delete configuration |

### Messages / 消息

| Key | Description |
|-----|-------------|
| `msgPositionCaptured` | Position captured notification |
| `msgClickStarted` | Click started notification |
| `msgClickStopped` | Click stopped notification |

### Settings / 设置

| Key | Description |
|-----|-------------|
| `hotkeySettings` | Hotkey settings |
| `languageSettings` | Language settings |
| `aboutTitle` | About dialog |

---

## 🐛 Troubleshooting / 故障排查

### Language Not Changing / 语言无法切换

1. **Check configuration file exists**
   ```bash
   # Windows
   type %USERPROFILE%\Documents\ClickMate\language.txt
   
   # macOS
   cat ~/Documents/ClickMate/language.txt
   ```

2. **Delete and restart**
   ```bash
   # Windows
   del %USERPROFILE%\Documents\ClickMate\language.txt
   
   # macOS
   rm ~/Documents/ClickMate/language.txt
   ```
   Then restart the app.

### Missing Translations / 翻译缺失

If you find missing or incorrect translations:

1. Open `lib/l10n/app_localizations.dart`
2. Find the translation key
3. Add/update the translation in the appropriate language map
4. Test and submit a pull request

### Wrong Language Detected / 检测到错误语言

The app uses the system's primary language setting:

**Windows:**
- Settings → Time & Language → Language → Windows display language

**macOS:**
- System Preferences → Language & Region → Preferred languages

---

## 🤝 Contributing Translations / 贡献翻译

We welcome translation improvements!

### How to Contribute / 贡献方式

1. Fork the repository
2. Edit `lib/l10n/app_localizations.dart`
3. Test your changes
4. Submit a pull request

### Translation Guidelines / 翻译准则

- Keep translations concise (UI space is limited)
- Use formal/polite form where appropriate
- Match the tone of existing translations
- Test on both Windows and macOS if possible

---

## 📋 Default Language Policy / 默认语言策略

| Element | Language |
|---------|----------|
| Code comments | English |
| Variable names | English |
| Log messages | English |
| Error messages (internal) | English |
| UI text | Localized (11 languages) |
| Documentation | English + Chinese |

This ensures:
- ✅ Better code maintainability
- ✅ Easier international collaboration
- ✅ Universal log understanding
- ✅ Accessible UI for all users

---

**Last Updated**: 2024-11-29  
**Version**: 2.0.0  
**Total Languages**: 11
