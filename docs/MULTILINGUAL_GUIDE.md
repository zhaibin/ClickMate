# 多语言指南

ClickMate 2.2.2 的界面有 11 种语言。代码、注释、日志和内部错误信息使用英语。界面字符串全部来自 `lib/l10n/app_localizations.dart`。

## 支持的语言

| 语言 | 文件中的值 | Locale |
|------|------------|--------|
| English | `en` | `Locale('en')` |
| 简体中文 | `zh_CN` | `Locale('zh', 'CN')` |
| 繁體中文 | `zh_TW` | `Locale('zh', 'TW')` |
| Français | `fr` | `Locale('fr')` |
| Español | `es` | `Locale('es')` |
| Português | `pt` | `Locale('pt')` |
| Deutsch | `de` | `Locale('de')` |
| Русский | `ru` | `Locale('ru')` |
| Italiano | `it` | `Locale('it')` |
| 日本語 | `ja` | `Locale('ja')` |
| 한국어 | `ko` | `Locale('ko')` |

葡萄牙语不区分巴西和葡萄牙。中文以外的语言只看语言代码，不看国家代码。

## 如何切换

标题栏菜单 → 语言。切换后立即重建界面，并写入语言文件。

| 平台 | 路径 |
|------|------|
| Windows | `%USERPROFILE%\Documents\ClickMate\language.txt` |
| macOS | `~/Documents/ClickMate/language.txt` |

文件内容是上表中的值，例如 `zh_CN` 或 `en`。没有该文件时，首次启动会检测系统语言并写回。

检测规则在 `LanguagePreference._detectSystemLanguage`：

- 语言代码不在支持列表中 → 英语
- `zh` 且地区为 `TW`、`HK`、`MO` → 繁体
- 其他 `zh` → 简体

这只影响第一次。之后以 `language.txt` 为准。

命名配置和会话设置不在这个文件里。它们走 SharedPreferences：Windows 为 `%APPDATA%\xants\ClickMate\shared_preferences.json`，macOS 为 bundle id `com.xants.clickmate` 的 UserDefaults。

## 代码里怎么取文案

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.btnStart);

await LanguagePreference.instance.changeLanguage(const Locale('zh', 'CN'));
```

地图里的键是 snake_case，例如 `btn_start`。Dart getter 是 camelCase，例如 `btnStart`，内部调用 `get('btn_start')`。不要把 getter 名字写进翻译 map。

`_getLocalizedStrings` 只接收 `locale.languageCode`。简体和繁体都是 `zh`，再靠 `locale.countryCode == 'TW'` 选择 `_traditionalChinese`，否则用 `_simplifiedChinese`。

键按前缀分组，完整列表以 `_english` 为准：

| 前缀 | 内容 |
|------|------|
| `app_` `status_` `btn_` `mode_` | 标题、状态、按钮、模式 |
| `label_` `hotkey_` | 表单标签和快捷键设置 |
| `msg_` `error_` `hint_` | 提示、错误、校验说明 |
| `history_` `lang_` `menu_` | 历史、语言名、菜单 |
| `config_` | 配置管理 |
| `help_` `faq_` | 帮助和常见问题 |
| `about_` `upgrade_` | 关于和更新 |

新增任何一个键时，11 个 map 都要有同一键。缺键时界面会直接显示键名。

## 增加一种语言

1. 在 `supportedLocales` 加入 `Locale`。
2. 复制 `_english`，改名为新的 map，翻译全部值，键名保持不变。
3. 在 `_getLocalizedStrings` 中按 `languageCode` 返回该 map。若与现有语言共用语言代码，要像中文一样再判断 `countryCode`。
4. 为语言名称增加 `lang_*` 键，并在 `LanguagePreference.getLanguageName` 里返回对应文案。
5. 把新的语言代码加入 `_isSupportedLocaleString` 能接受的 locale。它比对的是 `AppLocalizations.supportedLocales`，所以第 1 步做对即可。
6. 切换系统语言做一次冷启动，并在菜单里手动选一次，确认 `language.txt` 写入的值能被读回。

界面空间很小，译文保持短句，和现有语气一致。

## 排错

语言切了又变回去：看 `language.txt` 是否是支持的值。空文件或无法识别的内容会重新检测系统语言并覆盖。

某句话仍是英语或变成了键名：打开 `app_localizations.dart`，在对应语言 map 里补上与 `_english` 相同的键。

系统语言判断不符合预期：应用读的是 `Platform.localeName`，不是输入法语言。Windows 看「显示语言」，macOS 看「语言与地区」里的首选语言。

## 维护约定

| 内容 | 语言 |
|------|------|
| 变量、注释、日志、内部错误 | 英语 |
| 界面 | 11 种语言 |
| 用户文档 | 中文，命令和键名保持英语 |

不要在 Widget 里写死中文或英文字符串。日志用 `print` 或 `LoggerService`，内容使用英语。
