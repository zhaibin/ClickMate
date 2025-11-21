import 'package:flutter/material.dart';

/// Supported languages
enum AppLanguage {
  english,
  simplifiedChinese,
  traditionalChinese,
  french,
  spanish,
  portuguese,
  german,
  russian,
  italian,
}

/// Application localization service
class AppLocalizations {
  final Locale locale;
  late final Map<String, String> _localizedStrings;

  AppLocalizations(this.locale) {
    _localizedStrings = _getLocalizedStrings(locale.languageCode);
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final List<Locale> supportedLocales = [
    const Locale('en', ''), // English
    const Locale('zh', 'CN'), // Simplified Chinese
    const Locale('zh', 'TW'), // Traditional Chinese
    const Locale('fr', ''), // French
    const Locale('es', ''), // Spanish
    const Locale('pt', ''), // Portuguese
    const Locale('de', ''), // German
    const Locale('ru', ''), // Russian
    const Locale('it', ''), // Italian
    const Locale('ja', ''), // Japanese
    const Locale('ko', ''), // Korean
  ];

  String get(String key) {
    return _localizedStrings[key] ?? key;
  }

  // App Title
  String get appTitle => get('app_title');
  String get appTitleWithVersion => get('app_title_with_version');

  // Status
  String get statusNotCaptured => get('status_not_captured');
  String get statusClickCount => get('status_click_count');
  String get statusRunning => get('status_running');
  String get statusStopped => get('status_stopped');

  // Buttons
  String get btnStart => get('btn_start');
  String get btnStop => get('btn_stop');
  String get btnCapture => get('btn_capture');
  String get btnSave => get('btn_save');
  String get btnCancel => get('btn_cancel');
  String get btnOk => get('btn_ok');
  String get btnToggleMode => get('btn_toggle_mode');

  // Modes
  String get modeAuto => get('mode_auto');
  String get modeManual => get('mode_manual');
  String get modeAutoDesc => get('mode_auto_desc');
  String get modeManualDesc => get('mode_manual_desc');

  // Labels
  String get labelTargetPosition => get('label_target_position');
  String get labelXCoordinate => get('label_x_coordinate');
  String get labelYCoordinate => get('label_y_coordinate');
  String get labelClickSettings => get('label_click_settings');
  String get labelInterval => get('label_interval');
  String get labelIntervalMs => get('label_interval_ms');
  String get labelRandomRange => get('label_random_range');
  String get labelRandomMs => get('label_random_ms');
  String get labelOffset => get('label_offset');
  String get labelOffsetPx => get('label_offset_px');
  String get labelMouseButton => get('label_mouse_button');
  String get labelLeftButton => get('label_left_button');
  String get labelRightButton => get('label_right_button');
  String get labelMiddleButton => get('label_middle_button');
  String get labelClickHistory => get('label_click_history');
  String get labelCurrentPosition => get('label_current_position');
  String get labelLanguage => get('label_language');

  // Hotkeys
  String get hotkeyToggle => get('hotkey_toggle');
  String get hotkeyCapture => get('hotkey_capture');
  String get hotkeySettings => get('hotkey_settings');
  String get hotkeySettingsTitle => get('hotkey_settings_title');
  String get hotkeySelectKey => get('hotkey_select_key');
  String get hotkeyPreview => get('hotkey_preview');
  String get hotkeySetFor => get('hotkey_set_for');
  String get hotkeyStartStop => get('hotkey_start_stop');
  String get hotkeyCapturePosition => get('hotkey_capture_position');

  // Messages
  String get msgPositionCaptured => get('msg_position_captured');
  String get msgHotkeySaved => get('msg_hotkey_saved');
  String get msgNoClickHistory => get('msg_no_click_history');
  String get msgSwitchToManual => get('msg_switch_to_manual');
  String get msgSwitchToAuto => get('msg_switch_to_auto');

  // Errors
  String get errorInitFailed => get('error_init_failed');
  String get errorInvalidCoordinates => get('error_invalid_coordinates');
  String get errorInvalidInterval => get('error_invalid_interval');
  String get errorInvalidRandomRange => get('error_invalid_random_range');
  String get errorInvalidOffset => get('error_invalid_offset');
  String get errorCaptureFailed => get('error_capture_failed');
  String get errorOperationFailed => get('error_operation_failed');
  String get errorHotkeyFailed => get('error_hotkey_failed');
  String get errorHotkeyFailedReasons => get('error_hotkey_failed_reasons');
  String get errorTitle => get('error_title');

  // Hints
  String get hintCaptureCoordinates => get('hint_capture_coordinates');
  String get hintInputCoordinates => get('hint_input_coordinates');
  String get hintIntervalMin => get('hint_interval_min');
  String get hintRandomMin => get('hint_random_min');
  String get hintOffsetMin => get('hint_offset_min');

  // Click History
  String get historyRecentClicks => get('history_recent_clicks');
  String get historyTime => get('history_time');
  String get historyPosition => get('history_position');
  String get historyButton => get('history_button');

  // Languages
  String get langEnglish => get('lang_english');
  String get langSimplifiedChinese => get('lang_simplified_chinese');
  String get langTraditionalChinese => get('lang_traditional_chinese');
  String get langFrench => get('lang_french');
  String get langSpanish => get('lang_spanish');
  String get langPortuguese => get('lang_portuguese');
  String get langGerman => get('lang_german');
  String get langRussian => get('lang_russian');
  String get langItalian => get('lang_italian');
  String get langJapanese => get('lang_japanese');
  String get langKorean => get('lang_korean');

  Map<String, String> _getLocalizedStrings(String languageCode) {
    switch (languageCode) {
      case 'en':
        return _english;
      case 'zh':
        return locale.countryCode == 'TW' ? _traditionalChinese : _simplifiedChinese;
      case 'fr':
        return _french;
      case 'es':
        return _spanish;
      case 'pt':
        return _portuguese;
      case 'de':
        return _german;
      case 'ru':
        return _russian;
      case 'it':
        return _italian;
      case 'ja':
        return _japanese;
      case 'ko':
        return _korean;
      default:
        return _english;
    }
  }

  // English (Default)
  static const Map<String, String> _english = {
    'app_title': 'Mouse Auto Controller',
    'app_title_with_version': 'Mouse Auto Controller',
    'status_not_captured': 'Not Captured',
    'status_click_count': 'times',
    'status_running': 'Running',
    'status_stopped': 'Stopped',
    'btn_start': 'Start Clicking',
    'btn_stop': 'Stop Clicking',
    'btn_capture': 'Capture',
    'btn_save': 'Save',
    'btn_cancel': 'Cancel',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Toggle Mode',
    'mode_auto': 'Auto',
    'mode_manual': 'Manual',
    'mode_auto_desc': 'Auto-track mode',
    'mode_manual_desc': 'Manual input mode',
    'label_target_position': 'Target Position',
    'label_x_coordinate': 'X Coordinate',
    'label_y_coordinate': 'Y Coordinate',
    'label_click_settings': 'Click Settings',
    'label_interval': 'Interval',
    'label_interval_ms': 'Interval(ms)',
    'label_random_range': 'Random Range',
    'label_random_ms': 'Random±(ms)',
    'label_offset': 'Offset',
    'label_offset_px': 'Offset(px)',
    'label_mouse_button': 'Mouse Button',
    'label_left_button': 'Left',
    'label_right_button': 'Right',
    'label_middle_button': 'Middle',
    'label_click_history': 'Click History',
    'label_current_position': 'Current Position',
    'label_language': 'Language',
    'hotkey_toggle': 'Start/Stop',
    'hotkey_capture': 'Capture',
    'hotkey_settings': 'Hotkey Settings',
    'hotkey_settings_title': 'Hotkey Settings',
    'hotkey_select_key': 'Select Key:',
    'hotkey_preview': 'Hotkey Preview',
    'hotkey_set_for': 'Set hotkey for',
    'hotkey_start_stop': 'Start/Stop',
    'hotkey_capture_position': 'Capture Position',
    'msg_position_captured': 'Position captured',
    'msg_hotkey_saved': 'Hotkey saved as',
    'msg_no_click_history': 'No click history',
    'msg_switch_to_manual': 'Switched to manual input mode',
    'msg_switch_to_auto': 'Switched to auto-track mode',
    'error_init_failed': 'Initialization failed',
    'error_invalid_coordinates': 'Please enter valid target coordinates',
    'error_invalid_interval': 'Click interval must be ≥10 milliseconds',
    'error_invalid_random_range': 'Interval random range must be ≥0',
    'error_invalid_offset': 'Position offset must be ≥0',
    'error_capture_failed': 'Capture position failed',
    'error_operation_failed': 'Operation failed',
    'error_hotkey_failed': 'Hotkey setting failed!',
    'error_hotkey_failed_reasons': 'Possible reasons:\n1. Hotkey already in use\n2. Administrator permission required\n3. DLL loading failed',
    'error_title': 'Error',
    'hint_capture_coordinates': 'Click "Capture" button to get current mouse position',
    'hint_input_coordinates': 'Or manually enter X and Y coordinates',
    'hint_interval_min': 'Click interval must be ≥10ms',
    'hint_random_min': 'Random range must be ≥0',
    'hint_offset_min': 'Offset must be ≥0',
    'history_recent_clicks': 'Click History (Last 10)',
    'history_time': 'Time',
    'history_position': 'Position',
    'history_button': 'Button',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Simplified Chinese
  static const Map<String, String> _simplifiedChinese = {
    'app_title': '鼠标自动控制器',
    'app_title_with_version': '鼠标自动控制器',
    'status_not_captured': '未获取',
    'status_click_count': '次',
    'status_running': '运行中',
    'status_stopped': '已停止',
    'btn_start': '开始点击',
    'btn_stop': '停止点击',
    'btn_capture': '捕获',
    'btn_save': '保存',
    'btn_cancel': '取消',
    'btn_ok': '确定',
    'btn_toggle_mode': '切换模式',
    'mode_auto': '自动',
    'mode_manual': '手动',
    'mode_auto_desc': '自动跟随模式',
    'mode_manual_desc': '手动输入模式',
    'label_target_position': '目标位置',
    'label_x_coordinate': 'X坐标',
    'label_y_coordinate': 'Y坐标',
    'label_click_settings': '点击设置',
    'label_interval': '间隔',
    'label_interval_ms': '间隔(ms)',
    'label_random_range': '随机范围',
    'label_random_ms': '随机±(ms)',
    'label_offset': '偏移',
    'label_offset_px': '偏移(px)',
    'label_mouse_button': '鼠标按钮',
    'label_left_button': '左键',
    'label_right_button': '右键',
    'label_middle_button': '中键',
    'label_click_history': '点击历史',
    'label_current_position': '当前位置',
    'label_language': '语言',
    'hotkey_toggle': '开始/停止',
    'hotkey_capture': '捕获',
    'hotkey_settings': '快捷键设置',
    'hotkey_settings_title': '快捷键设置',
    'hotkey_select_key': '选择按键:',
    'hotkey_preview': '快捷键预览',
    'hotkey_set_for': '设置快捷键',
    'hotkey_start_stop': '开始/停止',
    'hotkey_capture_position': '捕获位置',
    'msg_position_captured': '已捕获位置',
    'msg_hotkey_saved': '快捷键已设置为',
    'msg_no_click_history': '暂无点击记录',
    'msg_switch_to_manual': '切换到手动输入模式',
    'msg_switch_to_auto': '切换到自动跟随模式',
    'error_init_failed': '初始化失败',
    'error_invalid_coordinates': '请输入有效的目标坐标',
    'error_invalid_interval': '点击间隔必须≥10毫秒',
    'error_invalid_random_range': '间隔随机范围必须≥0',
    'error_invalid_offset': '位置偏移必须≥0',
    'error_capture_failed': '捕获位置失败',
    'error_operation_failed': '操作失败',
    'error_hotkey_failed': '快捷键设置失败！',
    'error_hotkey_failed_reasons': '可能原因：\n1. 该快捷键已被其他程序占用\n2. 需要管理员权限\n3. DLL加载失败',
    'error_title': '错误',
    'hint_capture_coordinates': '点击"捕获"按钮获取当前鼠标位置',
    'hint_input_coordinates': '或手动输入X和Y坐标',
    'hint_interval_min': '点击间隔必须≥10毫秒',
    'hint_random_min': '随机范围必须≥0',
    'hint_offset_min': '偏移必须≥0',
    'history_recent_clicks': '点击历史（最近10次）',
    'history_time': '时间',
    'history_position': '位置',
    'history_button': '按钮',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Traditional Chinese
  static const Map<String, String> _traditionalChinese = {
    'app_title': '滑鼠自動控制器',
    'app_title_with_version': '滑鼠自動控制器',
    'status_not_captured': '未獲取',
    'status_click_count': '次',
    'status_running': '運行中',
    'status_stopped': '已停止',
    'btn_start': '開始點擊',
    'btn_stop': '停止點擊',
    'btn_capture': '捕獲',
    'btn_save': '保存',
    'btn_cancel': '取消',
    'btn_ok': '確定',
    'btn_toggle_mode': '切換模式',
    'mode_auto': '自動',
    'mode_manual': '手動',
    'mode_auto_desc': '自動跟隨模式',
    'mode_manual_desc': '手動輸入模式',
    'label_target_position': '目標位置',
    'label_x_coordinate': 'X坐標',
    'label_y_coordinate': 'Y坐標',
    'label_click_settings': '點擊設置',
    'label_interval': '間隔',
    'label_interval_ms': '間隔(ms)',
    'label_random_range': '隨機範圍',
    'label_random_ms': '隨機±(ms)',
    'label_offset': '偏移',
    'label_offset_px': '偏移(px)',
    'label_mouse_button': '滑鼠按鈕',
    'label_left_button': '左鍵',
    'label_right_button': '右鍵',
    'label_middle_button': '中鍵',
    'label_click_history': '點擊歷史',
    'label_current_position': '當前位置',
    'label_language': '語言',
    'hotkey_toggle': '開始/停止',
    'hotkey_capture': '捕獲',
    'hotkey_settings': '快捷鍵設置',
    'hotkey_settings_title': '快捷鍵設置',
    'hotkey_select_key': '選擇按鍵:',
    'hotkey_preview': '快捷鍵預覽',
    'hotkey_set_for': '設置快捷鍵',
    'hotkey_start_stop': '開始/停止',
    'hotkey_capture_position': '捕獲位置',
    'msg_position_captured': '已捕獲位置',
    'msg_hotkey_saved': '快捷鍵已設置為',
    'msg_no_click_history': '暫無點擊記錄',
    'msg_switch_to_manual': '切換到手動輸入模式',
    'msg_switch_to_auto': '切換到自動跟隨模式',
    'error_init_failed': '初始化失敗',
    'error_invalid_coordinates': '請輸入有效的目標坐標',
    'error_invalid_interval': '點擊間隔必須≥10毫秒',
    'error_invalid_random_range': '間隔隨機範圍必須≥0',
    'error_invalid_offset': '位置偏移必須≥0',
    'error_capture_failed': '捕獲位置失敗',
    'error_operation_failed': '操作失敗',
    'error_hotkey_failed': '快捷鍵設置失敗！',
    'error_hotkey_failed_reasons': '可能原因：\n1. 該快捷鍵已被其他程序佔用\n2. 需要管理員權限\n3. DLL加載失敗',
    'error_title': '錯誤',
    'hint_capture_coordinates': '點擊"捕獲"按鈕獲取當前滑鼠位置',
    'hint_input_coordinates': '或手動輸入X和Y坐標',
    'hint_interval_min': '點擊間隔必須≥10毫秒',
    'hint_random_min': '隨機範圍必須≥0',
    'hint_offset_min': '偏移必須≥0',
    'history_recent_clicks': '點擊歷史（最近10次）',
    'history_time': '時間',
    'history_position': '位置',
    'history_button': '按鈕',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // French
  static const Map<String, String> _french = {
    'app_title': 'Contrôleur Auto de Souris',
    'app_title_with_version': 'Contrôleur Auto de Souris',
    'status_not_captured': 'Non Capturé',
    'status_click_count': 'fois',
    'status_running': 'En cours',
    'status_stopped': 'Arrêté',
    'btn_start': 'Démarrer',
    'btn_stop': 'Arrêter',
    'btn_capture': 'Capturer',
    'btn_save': 'Enregistrer',
    'btn_cancel': 'Annuler',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Changer Mode',
    'mode_auto': 'Auto',
    'mode_manual': 'Manuel',
    'mode_auto_desc': 'Mode de suivi automatique',
    'mode_manual_desc': 'Mode de saisie manuelle',
    'label_target_position': 'Position Cible',
    'label_x_coordinate': 'Coordonnée X',
    'label_y_coordinate': 'Coordonnée Y',
    'label_click_settings': 'Paramètres de Clic',
    'label_interval': 'Intervalle',
    'label_interval_ms': 'Intervalle(ms)',
    'label_random_range': 'Plage Aléatoire',
    'label_random_ms': 'Aléatoire±(ms)',
    'label_offset': 'Décalage',
    'label_offset_px': 'Décalage(px)',
    'label_mouse_button': 'Bouton de Souris',
    'label_left_button': 'Gauche',
    'label_right_button': 'Droit',
    'label_middle_button': 'Milieu',
    'label_click_history': 'Historique des Clics',
    'label_current_position': 'Position Actuelle',
    'label_language': 'Langue',
    'hotkey_toggle': 'Démarrer/Arrêter',
    'hotkey_capture': 'Capturer',
    'hotkey_settings': 'Paramètres Raccourcis',
    'hotkey_settings_title': 'Paramètres des Raccourcis',
    'hotkey_select_key': 'Sélectionner Touche:',
    'hotkey_preview': 'Aperçu du Raccourci',
    'hotkey_set_for': 'Définir le raccourci pour',
    'hotkey_start_stop': 'Démarrer/Arrêter',
    'hotkey_capture_position': 'Capturer Position',
    'msg_position_captured': 'Position capturée',
    'msg_hotkey_saved': 'Raccourci enregistré comme',
    'msg_no_click_history': 'Aucun historique de clic',
    'msg_switch_to_manual': 'Basculé en mode de saisie manuelle',
    'msg_switch_to_auto': 'Basculé en mode de suivi automatique',
    'error_init_failed': 'Échec de l\'initialisation',
    'error_invalid_coordinates': 'Veuillez entrer des coordonnées cibles valides',
    'error_invalid_interval': 'L\'intervalle de clic doit être ≥10 millisecondes',
    'error_invalid_random_range': 'La plage aléatoire d\'intervalle doit être ≥0',
    'error_invalid_offset': 'Le décalage de position doit être ≥0',
    'error_capture_failed': 'Échec de la capture de position',
    'error_operation_failed': 'Échec de l\'opération',
    'error_hotkey_failed': 'Échec de la configuration du raccourci!',
    'error_hotkey_failed_reasons': 'Raisons possibles:\n1. Raccourci déjà utilisé\n2. Permission administrateur requise\n3. Échec du chargement de la DLL',
    'error_title': 'Erreur',
    'hint_capture_coordinates': 'Cliquez sur "Capturer" pour obtenir la position actuelle de la souris',
    'hint_input_coordinates': 'Ou entrez manuellement les coordonnées X et Y',
    'hint_interval_min': 'L\'intervalle de clic doit être ≥10ms',
    'hint_random_min': 'La plage aléatoire doit être ≥0',
    'hint_offset_min': 'Le décalage doit être ≥0',
    'history_recent_clicks': 'Historique des Clics (10 Derniers)',
    'history_time': 'Heure',
    'history_position': 'Position',
    'history_button': 'Bouton',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Spanish
  static const Map<String, String> _spanish = {
    'app_title': 'Controlador Auto de Ratón',
    'app_title_with_version': 'Controlador Auto de Ratón',
    'status_not_captured': 'No Capturado',
    'status_click_count': 'veces',
    'status_running': 'Ejecutando',
    'status_stopped': 'Detenido',
    'btn_start': 'Iniciar Clic',
    'btn_stop': 'Detener Clic',
    'btn_capture': 'Capturar',
    'btn_save': 'Guardar',
    'btn_cancel': 'Cancelar',
    'btn_ok': 'Aceptar',
    'btn_toggle_mode': 'Cambiar Modo',
    'mode_auto': 'Auto',
    'mode_manual': 'Manual',
    'mode_auto_desc': 'Modo de seguimiento automático',
    'mode_manual_desc': 'Modo de entrada manual',
    'label_target_position': 'Posición Objetivo',
    'label_x_coordinate': 'Coordenada X',
    'label_y_coordinate': 'Coordenada Y',
    'label_click_settings': 'Configuración de Clic',
    'label_interval': 'Intervalo',
    'label_interval_ms': 'Intervalo(ms)',
    'label_random_range': 'Rango Aleatorio',
    'label_random_ms': 'Aleatorio±(ms)',
    'label_offset': 'Desplazamiento',
    'label_offset_px': 'Desplazamiento(px)',
    'label_mouse_button': 'Botón del Ratón',
    'label_left_button': 'Izquierdo',
    'label_right_button': 'Derecho',
    'label_middle_button': 'Medio',
    'label_click_history': 'Historial de Clics',
    'label_current_position': 'Posición Actual',
    'label_language': 'Idioma',
    'hotkey_toggle': 'Iniciar/Detener',
    'hotkey_capture': 'Capturar',
    'hotkey_settings': 'Configuración de Atajos',
    'hotkey_settings_title': 'Configuración de Atajos de Teclado',
    'hotkey_select_key': 'Seleccionar Tecla:',
    'hotkey_preview': 'Vista Previa del Atajo',
    'hotkey_set_for': 'Establecer atajo para',
    'hotkey_start_stop': 'Iniciar/Detener',
    'hotkey_capture_position': 'Capturar Posición',
    'msg_position_captured': 'Posición capturada',
    'msg_hotkey_saved': 'Atajo guardado como',
    'msg_no_click_history': 'Sin historial de clics',
    'msg_switch_to_manual': 'Cambiado a modo de entrada manual',
    'msg_switch_to_auto': 'Cambiado a modo de seguimiento automático',
    'error_init_failed': 'Fallo en la inicialización',
    'error_invalid_coordinates': 'Por favor ingrese coordenadas objetivo válidas',
    'error_invalid_interval': 'El intervalo de clic debe ser ≥10 milisegundos',
    'error_invalid_random_range': 'El rango aleatorio de intervalo debe ser ≥0',
    'error_invalid_offset': 'El desplazamiento de posición debe ser ≥0',
    'error_capture_failed': 'Fallo al capturar posición',
    'error_operation_failed': 'Operación fallida',
    'error_hotkey_failed': '¡Fallo al configurar el atajo de teclado!',
    'error_hotkey_failed_reasons': 'Razones posibles:\n1. Atajo ya en uso\n2. Permiso de administrador requerido\n3. Fallo al cargar DLL',
    'error_title': 'Error',
    'hint_capture_coordinates': 'Haga clic en "Capturar" para obtener la posición actual del ratón',
    'hint_input_coordinates': 'O ingrese manualmente las coordenadas X e Y',
    'hint_interval_min': 'El intervalo de clic debe ser ≥10ms',
    'hint_random_min': 'El rango aleatorio debe ser ≥0',
    'hint_offset_min': 'El desplazamiento debe ser ≥0',
    'history_recent_clicks': 'Historial de Clics (Últimos 10)',
    'history_time': 'Hora',
    'history_position': 'Posición',
    'history_button': 'Botón',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Portuguese
  static const Map<String, String> _portuguese = {
    'app_title': 'Controlador Auto de Mouse',
    'app_title_with_version': 'Controlador Auto de Mouse',
    'status_not_captured': 'Não Capturado',
    'status_click_count': 'vezes',
    'status_running': 'Executando',
    'status_stopped': 'Parado',
    'btn_start': 'Iniciar Clique',
    'btn_stop': 'Parar Clique',
    'btn_capture': 'Capturar',
    'btn_save': 'Salvar',
    'btn_cancel': 'Cancelar',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Alternar Modo',
    'mode_auto': 'Auto',
    'mode_manual': 'Manual',
    'mode_auto_desc': 'Modo de rastreamento automático',
    'mode_manual_desc': 'Modo de entrada manual',
    'label_target_position': 'Posição Alvo',
    'label_x_coordinate': 'Coordenada X',
    'label_y_coordinate': 'Coordenada Y',
    'label_click_settings': 'Configurações de Clique',
    'label_interval': 'Intervalo',
    'label_interval_ms': 'Intervalo(ms)',
    'label_random_range': 'Intervalo Aleatório',
    'label_random_ms': 'Aleatório±(ms)',
    'label_offset': 'Deslocamento',
    'label_offset_px': 'Deslocamento(px)',
    'label_mouse_button': 'Botão do Mouse',
    'label_left_button': 'Esquerdo',
    'label_right_button': 'Direito',
    'label_middle_button': 'Meio',
    'label_click_history': 'Histórico de Cliques',
    'label_current_position': 'Posição Atual',
    'label_language': 'Idioma',
    'hotkey_toggle': 'Iniciar/Parar',
    'hotkey_capture': 'Capturar',
    'hotkey_settings': 'Configurações de Atalho',
    'hotkey_settings_title': 'Configurações de Atalhos de Teclado',
    'hotkey_select_key': 'Selecionar Tecla:',
    'hotkey_preview': 'Pré-visualização do Atalho',
    'hotkey_set_for': 'Definir atalho para',
    'hotkey_start_stop': 'Iniciar/Parar',
    'hotkey_capture_position': 'Capturar Posição',
    'msg_position_captured': 'Posição capturada',
    'msg_hotkey_saved': 'Atalho salvo como',
    'msg_no_click_history': 'Sem histórico de cliques',
    'msg_switch_to_manual': 'Alternado para modo de entrada manual',
    'msg_switch_to_auto': 'Alternado para modo de rastreamento automático',
    'error_init_failed': 'Falha na inicialização',
    'error_invalid_coordinates': 'Por favor, insira coordenadas alvo válidas',
    'error_invalid_interval': 'O intervalo de clique deve ser ≥10 milissegundos',
    'error_invalid_random_range': 'O intervalo aleatório deve ser ≥0',
    'error_invalid_offset': 'O deslocamento de posição deve ser ≥0',
    'error_capture_failed': 'Falha ao capturar posição',
    'error_operation_failed': 'Operação falhou',
    'error_hotkey_failed': 'Falha ao configurar atalho de teclado!',
    'error_hotkey_failed_reasons': 'Razões possíveis:\n1. Atalho já em uso\n2. Permissão de administrador necessária\n3. Falha ao carregar DLL',
    'error_title': 'Erro',
    'hint_capture_coordinates': 'Clique em "Capturar" para obter a posição atual do mouse',
    'hint_input_coordinates': 'Ou insira manualmente as coordenadas X e Y',
    'hint_interval_min': 'O intervalo de clique deve ser ≥10ms',
    'hint_random_min': 'O intervalo aleatório deve ser ≥0',
    'hint_offset_min': 'O deslocamento deve ser ≥0',
    'history_recent_clicks': 'Histórico de Cliques (Últimos 10)',
    'history_time': 'Hora',
    'history_position': 'Posição',
    'history_button': 'Botão',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // German
  static const Map<String, String> _german = {
    'app_title': 'Maus Auto-Controller',
    'app_title_with_version': 'Maus Auto-Controller',
    'status_not_captured': 'Nicht Erfasst',
    'status_click_count': 'Mal',
    'status_running': 'Läuft',
    'status_stopped': 'Gestoppt',
    'btn_start': 'Klicken Starten',
    'btn_stop': 'Klicken Stoppen',
    'btn_capture': 'Erfassen',
    'btn_save': 'Speichern',
    'btn_cancel': 'Abbrechen',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Modus Wechseln',
    'mode_auto': 'Auto',
    'mode_manual': 'Manuell',
    'mode_auto_desc': 'Automatischer Tracking-Modus',
    'mode_manual_desc': 'Manuelle Eingabemodus',
    'label_target_position': 'Zielposition',
    'label_x_coordinate': 'X-Koordinate',
    'label_y_coordinate': 'Y-Koordinate',
    'label_click_settings': 'Klick-Einstellungen',
    'label_interval': 'Intervall',
    'label_interval_ms': 'Intervall(ms)',
    'label_random_range': 'Zufallsbereich',
    'label_random_ms': 'Zufällig±(ms)',
    'label_offset': 'Versatz',
    'label_offset_px': 'Versatz(px)',
    'label_mouse_button': 'Maustaste',
    'label_left_button': 'Links',
    'label_right_button': 'Rechts',
    'label_middle_button': 'Mitte',
    'label_click_history': 'Klick-Verlauf',
    'label_current_position': 'Aktuelle Position',
    'label_language': 'Sprache',
    'hotkey_toggle': 'Start/Stopp',
    'hotkey_capture': 'Erfassen',
    'hotkey_settings': 'Tastenkürzel-Einstellungen',
    'hotkey_settings_title': 'Tastenkürzel-Einstellungen',
    'hotkey_select_key': 'Taste Auswählen:',
    'hotkey_preview': 'Tastenkürzel-Vorschau',
    'hotkey_set_for': 'Tastenkürzel festlegen für',
    'hotkey_start_stop': 'Start/Stopp',
    'hotkey_capture_position': 'Position Erfassen',
    'msg_position_captured': 'Position erfasst',
    'msg_hotkey_saved': 'Tastenkürzel gespeichert als',
    'msg_no_click_history': 'Kein Klick-Verlauf',
    'msg_switch_to_manual': 'Zu manuellem Eingabemodus gewechselt',
    'msg_switch_to_auto': 'Zu automatischem Tracking-Modus gewechselt',
    'error_init_failed': 'Initialisierung fehlgeschlagen',
    'error_invalid_coordinates': 'Bitte geben Sie gültige Zielkoordinaten ein',
    'error_invalid_interval': 'Klick-Intervall muss ≥10 Millisekunden sein',
    'error_invalid_random_range': 'Zufälliger Intervallbereich muss ≥0 sein',
    'error_invalid_offset': 'Positionsversatz muss ≥0 sein',
    'error_capture_failed': 'Position erfassen fehlgeschlagen',
    'error_operation_failed': 'Vorgang fehlgeschlagen',
    'error_hotkey_failed': 'Tastenkürzel-Einstellung fehlgeschlagen!',
    'error_hotkey_failed_reasons': 'Mögliche Gründe:\n1. Tastenkürzel bereits verwendet\n2. Administratorrechte erforderlich\n3. DLL-Laden fehlgeschlagen',
    'error_title': 'Fehler',
    'hint_capture_coordinates': 'Klicken Sie auf "Erfassen", um die aktuelle Mausposition zu erhalten',
    'hint_input_coordinates': 'Oder geben Sie X- und Y-Koordinaten manuell ein',
    'hint_interval_min': 'Klick-Intervall muss ≥10ms sein',
    'hint_random_min': 'Zufallsbereich muss ≥0 sein',
    'hint_offset_min': 'Versatz muss ≥0 sein',
    'history_recent_clicks': 'Klick-Verlauf (Letzte 10)',
    'history_time': 'Zeit',
    'history_position': 'Position',
    'history_button': 'Taste',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Russian
  static const Map<String, String> _russian = {
    'app_title': 'Авто-Контроллер Мыши',
    'app_title_with_version': 'Авто-Контроллер Мыши',
    'status_not_captured': 'Не Захвачено',
    'status_click_count': 'раз',
    'status_running': 'Работает',
    'status_stopped': 'Остановлено',
    'btn_start': 'Начать Клики',
    'btn_stop': 'Остановить Клики',
    'btn_capture': 'Захватить',
    'btn_save': 'Сохранить',
    'btn_cancel': 'Отмена',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Переключить Режим',
    'mode_auto': 'Авто',
    'mode_manual': 'Ручной',
    'mode_auto_desc': 'Режим автоотслеживания',
    'mode_manual_desc': 'Режим ручного ввода',
    'label_target_position': 'Целевая Позиция',
    'label_x_coordinate': 'Координата X',
    'label_y_coordinate': 'Координата Y',
    'label_click_settings': 'Настройки Кликов',
    'label_interval': 'Интервал',
    'label_interval_ms': 'Интервал(мс)',
    'label_random_range': 'Случайный Диапазон',
    'label_random_ms': 'Случайно±(мс)',
    'label_offset': 'Смещение',
    'label_offset_px': 'Смещение(px)',
    'label_mouse_button': 'Кнопка Мыши',
    'label_left_button': 'Левая',
    'label_right_button': 'Правая',
    'label_middle_button': 'Средняя',
    'label_click_history': 'История Кликов',
    'label_current_position': 'Текущая Позиция',
    'label_language': 'Язык',
    'hotkey_toggle': 'Старт/Стоп',
    'hotkey_capture': 'Захват',
    'hotkey_settings': 'Настройки Горячих Клавиш',
    'hotkey_settings_title': 'Настройки Горячих Клавиш',
    'hotkey_select_key': 'Выбрать Клавишу:',
    'hotkey_preview': 'Предпросмотр Горячей Клавиши',
    'hotkey_set_for': 'Установить горячую клавишу для',
    'hotkey_start_stop': 'Старт/Стоп',
    'hotkey_capture_position': 'Захват Позиции',
    'msg_position_captured': 'Позиция захвачена',
    'msg_hotkey_saved': 'Горячая клавиша сохранена как',
    'msg_no_click_history': 'Нет истории кликов',
    'msg_switch_to_manual': 'Переключено в режим ручного ввода',
    'msg_switch_to_auto': 'Переключено в режим автоотслеживания',
    'error_init_failed': 'Ошибка инициализации',
    'error_invalid_coordinates': 'Пожалуйста, введите действительные целевые координаты',
    'error_invalid_interval': 'Интервал кликов должен быть ≥10 миллисекунд',
    'error_invalid_random_range': 'Случайный диапазон интервала должен быть ≥0',
    'error_invalid_offset': 'Смещение позиции должно быть ≥0',
    'error_capture_failed': 'Не удалось захватить позицию',
    'error_operation_failed': 'Операция не удалась',
    'error_hotkey_failed': 'Не удалось настроить горячую клавишу!',
    'error_hotkey_failed_reasons': 'Возможные причины:\n1. Горячая клавиша уже используется\n2. Требуются права администратора\n3. Не удалось загрузить DLL',
    'error_title': 'Ошибка',
    'hint_capture_coordinates': 'Нажмите "Захватить" для получения текущей позиции мыши',
    'hint_input_coordinates': 'Или введите координаты X и Y вручную',
    'hint_interval_min': 'Интервал кликов должен быть ≥10мс',
    'hint_random_min': 'Случайный диапазон должен быть ≥0',
    'hint_offset_min': 'Смещение должно быть ≥0',
    'history_recent_clicks': 'История Кликов (Последние 10)',
    'history_time': 'Время',
    'history_position': 'Позиция',
    'history_button': 'Кнопка',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Italian
  static const Map<String, String> _italian = {
    'app_title': 'Controller Auto Mouse',
    'app_title_with_version': 'Controller Auto Mouse',
    'status_not_captured': 'Non Catturato',
    'status_click_count': 'volte',
    'status_running': 'In Esecuzione',
    'status_stopped': 'Fermato',
    'btn_start': 'Avvia Clic',
    'btn_stop': 'Ferma Clic',
    'btn_capture': 'Cattura',
    'btn_save': 'Salva',
    'btn_cancel': 'Annulla',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'Cambia Modalità',
    'mode_auto': 'Auto',
    'mode_manual': 'Manuale',
    'mode_auto_desc': 'Modalità di tracciamento automatico',
    'mode_manual_desc': 'Modalità di inserimento manuale',
    'label_target_position': 'Posizione Obiettivo',
    'label_x_coordinate': 'Coordinata X',
    'label_y_coordinate': 'Coordinata Y',
    'label_click_settings': 'Impostazioni Clic',
    'label_interval': 'Intervallo',
    'label_interval_ms': 'Intervallo(ms)',
    'label_random_range': 'Intervallo Casuale',
    'label_random_ms': 'Casuale±(ms)',
    'label_offset': 'Spostamento',
    'label_offset_px': 'Spostamento(px)',
    'label_mouse_button': 'Pulsante del Mouse',
    'label_left_button': 'Sinistro',
    'label_right_button': 'Destro',
    'label_middle_button': 'Centrale',
    'label_click_history': 'Cronologia Clic',
    'label_current_position': 'Posizione Attuale',
    'label_language': 'Lingua',
    'hotkey_toggle': 'Avvia/Ferma',
    'hotkey_capture': 'Cattura',
    'hotkey_settings': 'Impostazioni Scorciatoie',
    'hotkey_settings_title': 'Impostazioni Scorciatoie da Tastiera',
    'hotkey_select_key': 'Seleziona Tasto:',
    'hotkey_preview': 'Anteprima Scorciatoia',
    'hotkey_set_for': 'Imposta scorciatoia per',
    'hotkey_start_stop': 'Avvia/Ferma',
    'hotkey_capture_position': 'Cattura Posizione',
    'msg_position_captured': 'Posizione catturata',
    'msg_hotkey_saved': 'Scorciatoia salvata come',
    'msg_no_click_history': 'Nessuna cronologia clic',
    'msg_switch_to_manual': 'Passato alla modalità di inserimento manuale',
    'msg_switch_to_auto': 'Passato alla modalità di tracciamento automatico',
    'error_init_failed': 'Inizializzazione fallita',
    'error_invalid_coordinates': 'Si prega di inserire coordinate obiettivo valide',
    'error_invalid_interval': 'L\'intervallo di clic deve essere ≥10 millisecondi',
    'error_invalid_random_range': 'L\'intervallo casuale deve essere ≥0',
    'error_invalid_offset': 'Lo spostamento della posizione deve essere ≥0',
    'error_capture_failed': 'Cattura posizione fallita',
    'error_operation_failed': 'Operazione fallita',
    'error_hotkey_failed': 'Impostazione scorciatoia fallita!',
    'error_hotkey_failed_reasons': 'Possibili ragioni:\n1. Scorciatoia già in uso\n2. Permessi amministratore richiesti\n3. Caricamento DLL fallito',
    'error_title': 'Errore',
    'hint_capture_coordinates': 'Fare clic su "Cattura" per ottenere la posizione attuale del mouse',
    'hint_input_coordinates': 'Oppure inserire manualmente le coordinate X e Y',
    'hint_interval_min': 'L\'intervallo di clic deve essere ≥10ms',
    'hint_random_min': 'L\'intervallo casuale deve essere ≥0',
    'hint_offset_min': 'Lo spostamento deve essere ≥0',
    'history_recent_clicks': 'Cronologia Clic (Ultimi 10)',
    'history_time': 'Ora',
    'history_position': 'Posizione',
    'history_button': 'Pulsante',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Japanese
  static const Map<String, String> _japanese = {
    'app_title': 'マウス自動コントローラー',
    'app_title_with_version': 'マウス自動コントローラー',
    'status_not_captured': '未キャプチャ',
    'status_click_count': '回',
    'status_running': '実行中',
    'status_stopped': '停止',
    'btn_start': 'クリック開始',
    'btn_stop': 'クリック停止',
    'btn_capture': 'キャプチャ',
    'btn_save': '保存',
    'btn_cancel': 'キャンセル',
    'btn_ok': 'OK',
    'btn_toggle_mode': 'モード切替',
    'mode_auto': '自動',
    'mode_manual': '手動',
    'mode_auto_desc': '自動追跡モード',
    'mode_manual_desc': '手動入力モード',
    'label_target_position': '目標位置',
    'label_x_coordinate': 'X座標',
    'label_y_coordinate': 'Y座標',
    'label_click_settings': 'クリック設定',
    'label_interval': '間隔',
    'label_interval_ms': '間隔(ms)',
    'label_random_range': 'ランダム範囲',
    'label_random_ms': 'ランダム±(ms)',
    'label_offset': 'オフセット',
    'label_offset_px': 'オフセット(px)',
    'label_mouse_button': 'マウスボタン',
    'label_left_button': '左',
    'label_right_button': '右',
    'label_middle_button': '中',
    'label_click_history': 'クリック履歴',
    'label_current_position': '現在位置',
    'label_language': '言語',
    'hotkey_toggle': '開始/停止',
    'hotkey_capture': 'キャプチャ',
    'hotkey_settings': 'ホットキー設定',
    'hotkey_settings_title': 'ホットキー設定',
    'hotkey_select_key': 'キーを選択:',
    'hotkey_preview': 'ホットキープレビュー',
    'hotkey_set_for': 'ホットキーを設定',
    'hotkey_start_stop': '開始/停止',
    'hotkey_capture_position': '位置キャプチャ',
    'msg_position_captured': '位置をキャプチャしました',
    'msg_hotkey_saved': 'ホットキーを設定しました',
    'msg_no_click_history': 'クリック履歴なし',
    'msg_switch_to_manual': '手動入力モードに切り替えました',
    'msg_switch_to_auto': '自動追跡モードに切り替えました',
    'error_init_failed': '初期化に失敗しました',
    'error_invalid_coordinates': '有効な目標座標を入力してください',
    'error_invalid_interval': 'クリック間隔は≥10ミリ秒である必要があります',
    'error_invalid_random_range': 'ランダム範囲は≥0である必要があります',
    'error_invalid_offset': '位置オフセットは≥0である必要があります',
    'error_capture_failed': '位置のキャプチャに失敗しました',
    'error_operation_failed': '操作に失敗しました',
    'error_hotkey_failed': 'ホットキーの設定に失敗しました！',
    'error_hotkey_failed_reasons': '考えられる理由：\n1. ホットキーが既に使用されています\n2. 管理者権限が必要です\n3. DLLの読み込みに失敗しました',
    'error_title': 'エラー',
    'hint_capture_coordinates': '「キャプチャ」ボタンをクリックして現在のマウス位置を取得',
    'hint_input_coordinates': 'またはXとY座標を手動で入力',
    'hint_interval_min': 'クリック間隔は≥10ms必要です',
    'hint_random_min': 'ランダム範囲は≥0必要です',
    'hint_offset_min': 'オフセットは≥0必要です',
    'history_recent_clicks': 'クリック履歴（最新10件）',
    'history_time': '時刻',
    'history_position': '位置',
    'history_button': 'ボタン',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };

  // Korean
  static const Map<String, String> _korean = {
    'app_title': '마우스 자동 컨트롤러',
    'app_title_with_version': '마우스 자동 컨트롤러',
    'status_not_captured': '캡처되지 않음',
    'status_click_count': '회',
    'status_running': '실행 중',
    'status_stopped': '정지됨',
    'btn_start': '클릭 시작',
    'btn_stop': '클릭 중지',
    'btn_capture': '캡처',
    'btn_save': '저장',
    'btn_cancel': '취소',
    'btn_ok': '확인',
    'btn_toggle_mode': '모드 전환',
    'mode_auto': '자동',
    'mode_manual': '수동',
    'mode_auto_desc': '자동 추적 모드',
    'mode_manual_desc': '수동 입력 모드',
    'label_target_position': '목표 위치',
    'label_x_coordinate': 'X 좌표',
    'label_y_coordinate': 'Y 좌표',
    'label_click_settings': '클릭 설정',
    'label_interval': '간격',
    'label_interval_ms': '간격(ms)',
    'label_random_range': '랜덤 범위',
    'label_random_ms': '랜덤±(ms)',
    'label_offset': '오프셋',
    'label_offset_px': '오프셋(px)',
    'label_mouse_button': '마우스 버튼',
    'label_left_button': '왼쪽',
    'label_right_button': '오른쪽',
    'label_middle_button': '가운데',
    'label_click_history': '클릭 기록',
    'label_current_position': '현재 위치',
    'label_language': '언어',
    'hotkey_toggle': '시작/중지',
    'hotkey_capture': '캡처',
    'hotkey_settings': '단축키 설정',
    'hotkey_settings_title': '단축키 설정',
    'hotkey_select_key': '키 선택:',
    'hotkey_preview': '단축키 미리보기',
    'hotkey_set_for': '단축키 설정',
    'hotkey_start_stop': '시작/중지',
    'hotkey_capture_position': '위치 캡처',
    'msg_position_captured': '위치가 캡처되었습니다',
    'msg_hotkey_saved': '단축키가 저장되었습니다',
    'msg_no_click_history': '클릭 기록 없음',
    'msg_switch_to_manual': '수동 입력 모드로 전환되었습니다',
    'msg_switch_to_auto': '자동 추적 모드로 전환되었습니다',
    'error_init_failed': '초기화 실패',
    'error_invalid_coordinates': '유효한 목표 좌표를 입력하세요',
    'error_invalid_interval': '클릭 간격은 ≥10밀리초여야 합니다',
    'error_invalid_random_range': '랜덤 범위는 ≥0이어야 합니다',
    'error_invalid_offset': '위치 오프셋은 ≥0이어야 합니다',
    'error_capture_failed': '위치 캡처 실패',
    'error_operation_failed': '작업 실패',
    'error_hotkey_failed': '단축키 설정 실패!',
    'error_hotkey_failed_reasons': '가능한 이유:\n1. 단축키가 이미 사용 중입니다\n2. 관리자 권한이 필요합니다\n3. DLL 로드에 실패했습니다',
    'error_title': '오류',
    'hint_capture_coordinates': '"캡처" 버튼을 클릭하여 현재 마우스 위치 가져오기',
    'hint_input_coordinates': '또는 X와 Y 좌표를 수동으로 입력',
    'hint_interval_min': '클릭 간격은 ≥10ms여야 합니다',
    'hint_random_min': '랜덤 범위는 ≥0이어야 합니다',
    'hint_offset_min': '오프셋은 ≥0이어야 합니다',
    'history_recent_clicks': '클릭 기록 (최근 10개)',
    'history_time': '시간',
    'history_position': '위치',
    'history_button': '버튼',
    'lang_english': 'English',
    'lang_simplified_chinese': '简体中文',
    'lang_traditional_chinese': '繁體中文',
    'lang_french': 'Français',
    'lang_spanish': 'Español',
    'lang_portuguese': 'Português',
    'lang_german': 'Deutsch',
    'lang_russian': 'Русский',
    'lang_italian': 'Italiano',
    'lang_japanese': '日本語',
    'lang_korean': '한국어',
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'zh', 'fr', 'es', 'pt', 'de', 'ru', 'it', 'ja', 'ko']
        .contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}


