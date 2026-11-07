import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Hotkey modifier combination (Windows-style flags for native layer).
enum HotkeyModifiers {
  /// Default: Ctrl+Shift (Cmd+Shift on macOS)
  controlShift,
  /// Single key without modifiers (e.g. F9)
  none,
  control,
  alt,
  shift;

  /// Windows RegisterHotKey modifier flags (macOS maps these natively).
  int get flags {
    const alt = 0x0001;
    const control = 0x0002;
    const shift = 0x0004;
    switch (this) {
      case HotkeyModifiers.none:
        return 0;
      case HotkeyModifiers.alt:
        return alt;
      case HotkeyModifiers.control:
        return control;
      case HotkeyModifiers.shift:
        return shift;
      case HotkeyModifiers.controlShift:
        return control | shift;
    }
  }

  String get label {
    switch (this) {
      case HotkeyModifiers.none:
        return 'None';
      case HotkeyModifiers.alt:
        return 'Alt';
      case HotkeyModifiers.control:
        return 'Ctrl';
      case HotkeyModifiers.shift:
        return 'Shift';
      case HotkeyModifiers.controlShift:
        return 'Ctrl+Shift';
    }
  }

  static HotkeyModifiers fromName(String? name) {
    return HotkeyModifiers.values.firstWhere(
      (m) => m.name == name,
      orElse: () => HotkeyModifiers.controlShift,
    );
  }
}

/// Rules for primary hotkeys. Without modifiers, only F1–F12 are allowed so
/// letter/digit keys are not stolen system-wide.
class HotkeyKeyPolicy {
  static const int vkF1 = 0x70;
  static const int vkF12 = 0x7B;
  static const int defaultNoneToggle = 0x78; // F9
  static const int defaultNoneCapture = 0x79; // F10

  static bool isFunctionKey(int vkCode) =>
      vkCode >= vkF1 && vkCode <= vkF12;

  static bool isAllowed(int vkCode, HotkeyModifiers modifiers) {
    if (modifiers == HotkeyModifiers.none) {
      return isFunctionKey(vkCode);
    }
    return true;
  }

  static int coercePrimaryKey(
    int vkCode,
    HotkeyModifiers modifiers, {
    required int fallback,
  }) {
    return isAllowed(vkCode, modifiers) ? vkCode : fallback;
  }

  static ({int toggle, int capture}) coercePair({
    required int toggle,
    required int capture,
    required HotkeyModifiers modifiers,
  }) {
    if (modifiers != HotkeyModifiers.none) {
      return (toggle: toggle, capture: capture);
    }

    final coercedToggle = coercePrimaryKey(
      toggle,
      modifiers,
      fallback: defaultNoneToggle,
    );
    var coercedCapture = coercePrimaryKey(
      capture,
      modifiers,
      fallback: defaultNoneCapture,
    );
    if (coercedCapture == coercedToggle) {
      coercedCapture =
          coercedToggle == defaultNoneCapture ? 0x7A : defaultNoneCapture;
    }
    return (toggle: coercedToggle, capture: coercedCapture);
  }
}

/// Last-used UI session settings (persisted across restarts).
class SessionSettings {
  final int? x;
  final int? y;
  final int interval;
  final int randomInterval;
  final int offset;
  final int mouseButton;
  final int deviationThreshold;
  final bool autoCapture;
  final bool enableAutoPauseResume;
  final int toggleHotkeyCode;
  final int captureHotkeyCode;
  final HotkeyModifiers hotkeyModifiers;

  const SessionSettings({
    this.x,
    this.y,
    this.interval = 1000,
    this.randomInterval = 0,
    this.offset = 0,
    this.mouseButton = 0,
    this.deviationThreshold = 100,
    this.autoCapture = true,
    this.enableAutoPauseResume = true,
    this.toggleHotkeyCode = 0x31,
    this.captureHotkeyCode = 0x32,
    this.hotkeyModifiers = HotkeyModifiers.controlShift,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'interval': interval,
      'randomInterval': randomInterval,
      'offset': offset,
      'mouseButton': mouseButton,
      'deviationThreshold': deviationThreshold,
      'autoCapture': autoCapture,
      'enableAutoPauseResume': enableAutoPauseResume,
      'toggleHotkeyCode': toggleHotkeyCode,
      'captureHotkeyCode': captureHotkeyCode,
      'hotkeyModifiers': hotkeyModifiers.name,
    };
  }

  factory SessionSettings.fromJson(Map<String, dynamic> json) {
    final modifiers =
        HotkeyModifiers.fromName(json['hotkeyModifiers'] as String?);
    final pair = HotkeyKeyPolicy.coercePair(
      toggle: (json['toggleHotkeyCode'] as int?) ?? 0x31,
      capture: (json['captureHotkeyCode'] as int?) ?? 0x32,
      modifiers: modifiers,
    );
    return SessionSettings(
      x: json['x'] as int?,
      y: json['y'] as int?,
      interval: (json['interval'] as int?) ?? 1000,
      randomInterval: (json['randomInterval'] as int?) ?? 0,
      offset: (json['offset'] as int?) ?? 0,
      mouseButton: (json['mouseButton'] as int?) ?? 0,
      deviationThreshold: (json['deviationThreshold'] as int?) ?? 100,
      autoCapture: (json['autoCapture'] as bool?) ?? true,
      enableAutoPauseResume: (json['enableAutoPauseResume'] as bool?) ?? true,
      toggleHotkeyCode: pair.toggle,
      captureHotkeyCode: pair.capture,
      hotkeyModifiers: modifiers,
    );
  }
}

/// Click configuration data model
class ClickConfig {
  String id;
  String name;
  int x;
  int y;
  int interval;
  int randomInterval;
  int offset;
  int mouseButton; // 0=left, 1=right, 2=middle
  DateTime createdAt;
  DateTime updatedAt;

  ClickConfig({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.interval,
    required this.randomInterval,
    required this.offset,
    required this.mouseButton,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'interval': interval,
      'randomInterval': randomInterval,
      'offset': offset,
      'mouseButton': mouseButton,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ClickConfig.fromJson(Map<String, dynamic> json) {
    return ClickConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      interval: json['interval'] as int,
      randomInterval: json['randomInterval'] as int,
      offset: json['offset'] as int,
      mouseButton: json['mouseButton'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a copy with updated fields
  ClickConfig copyWith({
    String? id,
    String? name,
    int? x,
    int? y,
    int? interval,
    int? randomInterval,
    int? offset,
    int? mouseButton,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClickConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      x: x ?? this.x,
      y: y ?? this.y,
      interval: interval ?? this.interval,
      randomInterval: randomInterval ?? this.randomInterval,
      offset: offset ?? this.offset,
      mouseButton: mouseButton ?? this.mouseButton,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClickConfig(id: $id, name: $name, pos: ($x,$y), interval: $interval)';
  }
}

/// Click configuration management service
class ClickConfigService {
  static const String _storageKey = 'click_configs';
  static const String _lastUsedConfigKey = 'last_used_config_id';
  static const String _sessionSettingsKey = 'session_settings';
  
  static final ClickConfigService instance = ClickConfigService._internal();
  
  factory ClickConfigService() {
    return instance;
  }
  
  ClickConfigService._internal();

  SharedPreferences? _prefs;
  List<ClickConfig> _configs = [];
  String? _lastUsedConfigId;
  SessionSettings? _sessionSettings;

  /// Initialize service
  Future<void> initialize() async {
    try {
      print('Initializing ClickConfigService...');
      _prefs = await SharedPreferences.getInstance();
      await loadConfigs();
      _loadSessionSettingsFromPrefs();
      print('ClickConfigService initialized. Loaded ${_configs.length} configs');
    } catch (e) {
      print('Warning: ClickConfigService initialization failed: $e');
      print('The app will continue without config management features');
      _configs = [];
    }
  }

  /// Load all configurations
  Future<void> loadConfigs() async {
    try {
      final String? configsJson = _prefs?.getString(_storageKey);
      if (configsJson != null && configsJson.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(configsJson);
        _configs = jsonList.map((json) => ClickConfig.fromJson(json)).toList();
        print('Loaded ${_configs.length} configurations from storage');
      } else {
        _configs = [];
        print('No saved configurations found');
      }
      
      _lastUsedConfigId = _prefs?.getString(_lastUsedConfigKey);
      if (_lastUsedConfigId != null) {
        print('Last used config ID: $_lastUsedConfigId');
      }
    } catch (e) {
      print('Error loading configurations: $e');
      _configs = [];
    }
  }

  /// Save all configurations. Returns false if persistence failed.
  Future<bool> saveConfigs() async {
    try {
      if (_prefs == null) {
        print('Error saving configurations: SharedPreferences not initialized');
        return false;
      }
      final List<Map<String, dynamic>> jsonList = 
          _configs.map((config) => config.toJson()).toList();
      final String configsJson = json.encode(jsonList);
      final ok = await _prefs!.setString(_storageKey, configsJson);
      if (ok) {
        print('Saved ${_configs.length} configurations to storage');
      } else {
        print('Error saving configurations: SharedPreferences.setString returned false');
      }
      return ok;
    } catch (e) {
      print('Error saving configurations: $e');
      return false;
    }
  }

  void _loadSessionSettingsFromPrefs() {
    try {
      final String? jsonStr = _prefs?.getString(_sessionSettingsKey);
      if (jsonStr == null || jsonStr.isEmpty) {
        _sessionSettings = null;
        return;
      }
      final Map<String, dynamic> map = json.decode(jsonStr) as Map<String, dynamic>;
      _sessionSettings = SessionSettings.fromJson(map);
      print('Loaded session settings from storage');
    } catch (e) {
      print('Error loading session settings: $e');
      _sessionSettings = null;
    }
  }

  /// Return cached session settings (call after [initialize]).
  SessionSettings? loadSessionSettings() => _sessionSettings;

  /// Persist current UI session so settings survive restart.
  Future<bool> saveSessionSettings(SessionSettings settings) async {
    try {
      if (_prefs == null) {
        print('Error saving session settings: SharedPreferences not initialized');
        return false;
      }
      final ok = await _prefs!.setString(
        _sessionSettingsKey,
        json.encode(settings.toJson()),
      );
      if (ok) {
        _sessionSettings = settings;
        print('Saved session settings to storage');
      } else {
        print('Error saving session settings: setString returned false');
      }
      return ok;
    } catch (e) {
      print('Error saving session settings: $e');
      return false;
    }
  }

  /// Get all configurations
  List<ClickConfig> getAllConfigs() {
    return List.unmodifiable(_configs);
  }

  /// Get configuration by ID
  ClickConfig? getConfigById(String id) {
    try {
      return _configs.firstWhere((config) => config.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get last used configuration
  ClickConfig? getLastUsedConfig() {
    if (_lastUsedConfigId != null) {
      return getConfigById(_lastUsedConfigId!);
    }
    return null;
  }

  /// Get last used configuration ID
  String? getLastUsedConfigId() {
    return _lastUsedConfigId;
  }

  /// Check if a configuration with same settings exists
  ClickConfig? findMatchingConfig({
    required int x,
    required int y,
    required int interval,
    required int randomInterval,
    required int offset,
    required int mouseButton,
  }) {
    for (final config in _configs) {
      if (config.x == x &&
          config.y == y &&
          config.interval == interval &&
          config.randomInterval == randomInterval &&
          config.offset == offset &&
          config.mouseButton == mouseButton) {
        return config;
      }
    }
    return null;
  }

  /// Auto-save configuration if it doesn't exist
  Future<ClickConfig> autoSaveConfig({
    required int x,
    required int y,
    required int interval,
    required int randomInterval,
    required int offset,
    required int mouseButton,
  }) async {
    // Check if matching config exists
    final existing = findMatchingConfig(
      x: x,
      y: y,
      interval: interval,
      randomInterval: randomInterval,
      offset: offset,
      mouseButton: mouseButton,
    );

    if (existing != null) {
      // Config already exists, just update last used
      await setLastUsedConfig(existing.id);
      return existing;
    }

    // Create new config with auto-generated name
    final config = createConfig(
      name: generateDefaultName(),
      x: x,
      y: y,
      interval: interval,
      randomInterval: randomInterval,
      offset: offset,
      mouseButton: mouseButton,
    );

    await addConfig(config);
    await setLastUsedConfig(config.id);
    print('Auto-saved new config: ${config.name}');
    return config;
  }

  /// Add new configuration
  Future<ClickConfig> addConfig(ClickConfig config) async {
    _configs.add(config);
    await saveConfigs();
    print('Added new config: ${config.name}');
    return config;
  }

  /// Update existing configuration
  Future<void> updateConfig(ClickConfig config) async {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index != -1) {
      _configs[index] = config.copyWith(updatedAt: DateTime.now());
      await saveConfigs();
      print('Updated config: ${config.name}');
    }
  }

  /// Delete configuration
  Future<void> deleteConfig(String id) async {
    final config = getConfigById(id);
    _configs.removeWhere((c) => c.id == id);
    await saveConfigs();
    
    // Clear last used if it was deleted
    if (_lastUsedConfigId == id) {
      _lastUsedConfigId = null;
      await _prefs?.remove(_lastUsedConfigKey);
    }
    
    if (config != null) {
      print('Deleted config: ${config.name}');
    }
  }

  /// Rename configuration
  Future<void> renameConfig(String id, String newName) async {
    final config = getConfigById(id);
    if (config != null) {
      final updatedConfig = config.copyWith(
        name: newName,
        updatedAt: DateTime.now(),
      );
      await updateConfig(updatedConfig);
      print('Renamed config $id to: $newName');
    }
  }

  /// Set last used configuration
  Future<void> setLastUsedConfig(String id) async {
    _lastUsedConfigId = id;
    await _prefs?.setString(_lastUsedConfigKey, id);
    print('Set last used config: $id');
  }

  /// Create new configuration from current settings
  ClickConfig createConfig({
    required String name,
    required int x,
    required int y,
    required int interval,
    required int randomInterval,
    required int offset,
    required int mouseButton,
  }) {
    final now = DateTime.now();
    return ClickConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      x: x,
      y: y,
      interval: interval,
      randomInterval: randomInterval,
      offset: offset,
      mouseButton: mouseButton,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Generate default config name
  String generateDefaultName() {
    int count = 1;
    while (true) {
      final name = 'Config $count';
      if (!_configs.any((c) => c.name == name)) {
        return name;
      }
      count++;
    }
  }
}

