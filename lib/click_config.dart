import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  static final ClickConfigService instance = ClickConfigService._internal();
  
  factory ClickConfigService() {
    return instance;
  }
  
  ClickConfigService._internal();

  SharedPreferences? _prefs;
  List<ClickConfig> _configs = [];
  String? _lastUsedConfigId;

  /// Initialize service
  Future<void> initialize() async {
    try {
      print('Initializing ClickConfigService...');
      _prefs = await SharedPreferences.getInstance();
      await loadConfigs();
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

  /// Save all configurations
  Future<void> saveConfigs() async {
    try {
      final List<Map<String, dynamic>> jsonList = 
          _configs.map((config) => config.toJson()).toList();
      final String configsJson = json.encode(jsonList);
      await _prefs?.setString(_storageKey, configsJson);
      print('Saved ${_configs.length} configurations to storage');
    } catch (e) {
      print('Error saving configurations: $e');
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

