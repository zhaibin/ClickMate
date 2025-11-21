import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'l10n/app_localizations.dart';

/// Language preference service - manages user language selection
class LanguagePreference {
  static final LanguagePreference _instance = LanguagePreference._();
  static LanguagePreference get instance => _instance;
  
  LanguagePreference._();
  
  Locale _currentLocale = const Locale('en', ''); // Default: English
  File? _prefsFile;
  
  /// Get current locale
  Locale get currentLocale => _currentLocale;
  
  /// Initialize and load saved language preference
  Future<void> initialize() async {
    try {
      final dir = await _getPrefsDirectory();
      _prefsFile = File('${dir.path}/language.txt');
      
      if (await _prefsFile!.exists()) {
        // Load saved language preference
        final savedLang = await _prefsFile!.readAsString();
        _currentLocale = _parseLocale(savedLang.trim());
        print('Language preference loaded from file: $_currentLocale');
      } else {
        // No saved preference, detect system language
        _currentLocale = _detectSystemLanguage();
        print('No saved language preference, detected system language: $_currentLocale');
      }
    } catch (e) {
      print('Failed to load language preference: $e');
      _currentLocale = _detectSystemLanguage();
    }
  }
  
  /// Detect system language and return supported locale
  Locale _detectSystemLanguage() {
    try {
      // Get system locale from platform
      final systemLocale = Platform.localeName; // e.g., "en_US", "zh_CN", "ja_JP"
      print('System locale detected: $systemLocale');
      
      // Parse system locale
      final parts = systemLocale.split('_');
      final languageCode = parts[0].toLowerCase();
      final countryCode = parts.length > 1 ? parts[1].toUpperCase() : '';
      
      // Check if the language is supported
      final supportedLanguages = ['en', 'zh', 'fr', 'es', 'pt', 'de', 'ru', 'it', 'ja', 'ko'];
      
      if (supportedLanguages.contains(languageCode)) {
        // Special handling for Chinese (check Traditional vs Simplified)
        if (languageCode == 'zh') {
          // TW, HK, MO use Traditional Chinese, others use Simplified
          if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
            return const Locale('zh', 'TW');
          } else {
            return const Locale('zh', 'CN');
          }
        }
        // Return supported language
        return Locale(languageCode, '');
      }
      
      // Language not supported, fallback to English
      print('System language "$languageCode" not supported, using English');
      return const Locale('en', '');
    } catch (e) {
      print('Failed to detect system language: $e, using English');
      return const Locale('en', '');
    }
  }
  
  /// Change language
  Future<void> changeLanguage(Locale locale) async {
    _currentLocale = locale;
    await _savePreference();
    print('Language changed to: $locale');
  }
  
  /// Save language preference to file
  Future<void> _savePreference() async {
    try {
      if (_prefsFile == null) {
        final dir = await _getPrefsDirectory();
        _prefsFile = File('${dir.path}/language.txt');
      }
      
      final localeString = _currentLocale.countryCode != null && _currentLocale.countryCode!.isNotEmpty
          ? '${_currentLocale.languageCode}_${_currentLocale.countryCode}'
          : _currentLocale.languageCode;
      
      await _prefsFile!.writeAsString(localeString);
    } catch (e) {
      print('Failed to save language preference: $e');
    }
  }
  
  /// Get preferences directory
  Future<Directory> _getPrefsDirectory() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final prefsDir = Directory('${appDir.path}/MouseControl');
      if (!await prefsDir.exists()) {
        await prefsDir.create(recursive: true);
      }
      return prefsDir;
    } catch (e) {
      // Fallback to current directory
      final prefsDir = Directory('.');
      return prefsDir;
    }
  }
  
  /// Parse locale string (e.g., "zh_CN", "en", "zh_TW")
  Locale _parseLocale(String localeString) {
    if (localeString.isEmpty) {
      return const Locale('en', '');
    }
    
    final parts = localeString.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else {
      return Locale(parts[0], '');
    }
  }
  
  /// Get language name for display
  String getLanguageName(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode == 'en') {
      return l10n.langEnglish;
    } else if (locale.languageCode == 'zh') {
      return locale.countryCode == 'TW' 
          ? l10n.langTraditionalChinese 
          : l10n.langSimplifiedChinese;
    } else if (locale.languageCode == 'fr') {
      return l10n.langFrench;
    } else if (locale.languageCode == 'es') {
      return l10n.langSpanish;
    } else if (locale.languageCode == 'pt') {
      return l10n.langPortuguese;
    } else if (locale.languageCode == 'de') {
      return l10n.langGerman;
    } else if (locale.languageCode == 'ru') {
      return l10n.langRussian;
    } else if (locale.languageCode == 'it') {
      return l10n.langItalian;
    } else if (locale.languageCode == 'ja') {
      return l10n.langJapanese;
    } else if (locale.languageCode == 'ko') {
      return l10n.langKorean;
    }
    return locale.languageCode;
  }
}


