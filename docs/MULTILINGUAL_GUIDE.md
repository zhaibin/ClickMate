# Multilingual Support Guide / 多语言支持指南

## Overview / 概述

Mouse Auto Controller v1.4.1+ supports 11 languages with automatic system language detection, easy switching and automatic preference saving.

鼠标自动控制器 v1.4.1+ 支持11种语言，具有系统语言自动检测、轻松切换和自动保存偏好功能。

## Supported Languages / 支持的语言

1. **English** - Default fallback / 默认回退语言
2. **简体中文** (Simplified Chinese)
3. **繁體中文** (Traditional Chinese)
4. **Français** (French / 法语)
5. **Español** (Spanish / 西班牙语)
6. **Português** (Portuguese / 葡萄牙语)
7. **Deutsch** (German / 德语)
8. **Русский** (Russian / 俄语)
9. **Italiano** (Italian / 意大利语)
10. **日本語** (Japanese / 日语)
11. **한국어** (Korean / 韩语)

## How to Change Language / 如何切换语言

### Automatic Detection / 自动检测

**First Launch**: The application automatically detects your system language
**首次启动**：应用程序自动检测系统语言

- Windows Chinese (China/Singapore) → Simplified Chinese
- Windows Chinese (Taiwan/Hong Kong/Macao) → Traditional Chinese  
- Windows Japanese → Japanese
- Windows Korean → Korean
- Other supported languages → Corresponding language
- Unsupported languages → English (fallback)

### Method 1: Using UI / 方法1：使用界面

1. Click the **🌐 Language icon** in the title bar
   点击标题栏的**🌐语言图标**

2. Select your preferred language from the list
   从列表中选择你想要的语言

3. Language will change immediately
   语言立即生效

4. Your choice is saved automatically and will be used next time
   选择自动保存并在下次启动时使用

### Method 2: Manual Configuration / 方法2：手动配置

Language preference is stored in:
语言偏好保存在：

```
%USERPROFILE%\Documents\MouseControl\language.txt
```

Supported values / 支持的值：
- `en` - English
- `zh_CN` - Simplified Chinese / 简体中文
- `zh_TW` - Traditional Chinese / 繁體中文
- `fr` - French / 法语
- `es` - Spanish / 西班牙语
- `pt` - Portuguese / 葡萄牙语
- `de` - German / 德语
- `ru` - Russian / 俄语
- `it` - Italian / 意大利语
- `ja` - Japanese / 日语
- `ko` - Korean / 韩语

## Technical Details / 技术细节

### Architecture / 架构

The multilingual system uses Flutter's official internationalization framework:
多语言系统使用Flutter官方国际化框架：

```
lib/
├── l10n/
│   └── app_localizations.dart    # All translations
├── language_preference.dart       # Preference management
└── main.dart                      # Integration
```

### Key Components / 关键组件

1. **AppLocalizations** - Translation strings for all languages
   翻译字符串管理

2. **LanguagePreference** - Persistent storage of language choice
   语言选择持久化存储

3. **LocalizationsDelegate** - Flutter localization integration
   Flutter本地化集成

### Adding New Languages / 添加新语言

To add a new language / 添加新语言：

1. Add locale to `AppLocalizations.supportedLocales`
   添加语言到支持列表

2. Create translation map in `app_localizations.dart`
   在文件中创建翻译映射

3. Update `_getLocalizedStrings()` method
   更新获取翻译的方法

4. Update language name in `getLanguageName()`
   更新语言名称

## Troubleshooting / 故障排查

### Language Not Changing / 语言无法切换

1. Check if `language.txt` file exists
   检查语言配置文件是否存在

2. Verify the locale code is correct
   验证语言代码是否正确

3. Try deleting `language.txt` and restart
   尝试删除配置文件并重启

### Missing Translations / 翻译缺失

If you find any missing or incorrect translations, please:
如果发现翻译缺失或错误：

1. Check `lib/l10n/app_localizations.dart`
   检查翻译文件

2. Look for the translation key
   查找翻译键

3. Update the corresponding language map
   更新对应的语言映射

## Contributing Translations / 贡献翻译

We welcome translation improvements! / 欢迎改进翻译！

To contribute / 贡献方式：

1. Fork the repository
   Fork代码仓库

2. Edit `lib/l10n/app_localizations.dart`
   编辑翻译文件

3. Test your changes
   测试你的修改

4. Submit a pull request
   提交Pull Request

## Default Language Policy / 默认语言策略

- **Code**: All code comments and variable names in English
  **代码**：所有代码注释和变量名使用英文

- **Logs**: All log messages in English
  **日志**：所有日志消息使用英文

- **UI First Launch**: Auto-detect system language
  **界面首次启动**：自动检测系统语言

- **UI Subsequent**: Use last selected language
  **界面后续启动**：使用上次选择的语言

This ensures:
这确保了：
- Better code maintainability / 更好的代码可维护性
- Easier collaboration / 更容易协作
- Universal log understanding / 日志通用性

---

**Last Updated**: 2024-11-21  
**Version**: 1.4.1  
**Total Languages**: 11

