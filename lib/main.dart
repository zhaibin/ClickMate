import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'mouse_controller_bindings.dart';
import 'mouse_controller_service.dart';
import 'logger_service.dart';
import 'version.dart';
import 'l10n/app_localizations.dart';
import 'language_preference.dart';
import 'click_config.dart';
import 'config_management_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize log system
  await LoggerService.instance.initialize();
  
  // Initialize language preference
  await LanguagePreference.instance.initialize();
  
  // Initialize click config service (non-critical, won't block startup)
  try {
    await ClickConfigService.instance.initialize();
  } catch (e) {
    print('Warning: Failed to initialize config service: $e');
  }
  
  // Initialize window manager
  await windowManager.ensureInitialized();
  
  // Set window properties
  WindowOptions windowOptions = const WindowOptions(
    size: Size(520, 680),
    minimumSize: Size(520, 680),
    maximumSize: Size(520, 680),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'ClickMate',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setResizable(false);
  });
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = LanguagePreference.instance.currentLocale;

  void _changeLanguage(Locale locale) {
    setState(() {
      _locale = locale;
    });
    LanguagePreference.instance.changeLanguage(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClickMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MouseControlPage(onLanguageChanged: _changeLanguage),
    );
  }
}

class MouseControlPage extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  
  const MouseControlPage({super.key, required this.onLanguageChanged});

  @override
  State<MouseControlPage> createState() => _MouseControlPageState();
}

class _MouseControlPageState extends State<MouseControlPage> {
  late MouseControllerService _service;
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _intervalController = TextEditingController(text: '1000');
  final TextEditingController _intervalRandomController = TextEditingController(text: '0');
  final TextEditingController _offsetController = TextEditingController(text: '0');

  MouseButton _selectedButton = MouseButton.left;
  bool _isRunning = false;
  String _currentPosition = '';
  Timer? _uiUpdateTimer;
  bool _autoCapture = true; // Auto-capture mode enabled by default

  @override
  void initState() {
    super.initState();
    try {
      final bindings = MouseControllerBindings();
      _service = MouseControllerService(bindings);
      
      // Load last used configuration
      _loadLastUsedConfig();
      
      // Set position capture callback
      _service.onPositionCaptured = (x, y) {
        if (mounted) {
          setState(() {
            _xController.text = x.toString();
            _yController.text = y.toString();
          });
          // Show notification
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('${l10n.msgPositionCaptured}: ($x, $y)'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
      
      _startUiUpdate();
      
      // Delayed hotkey status check
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _checkHotkeyStatus();
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final l10n = AppLocalizations.of(context);
        _showError('${l10n.errorInitFailed}: $e\n\nPlease check console output for details');
      });
    }
  }
  
  void _checkHotkeyStatus() {
    // Additional status check can be added here
    print('Interface loaded, hotkey system status displayed in console');
    print('Tip: If hotkeys don\'t work, check initialization logs above');
  }

  void _startUiUpdate() {
    _uiUpdateTimer?.cancel();
    _uiUpdateTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (mounted) {
        try {
          final pos = _service.getCurrentMousePosition();
          setState(() {
            _currentPosition = '(${pos.x}, ${pos.y})';
            _isRunning = _service.isRunning;
            
            // Update coordinates if auto-capture is enabled and not running
            if (_autoCapture && !_isRunning) {
              _xController.text = pos.x.toString();
              _yController.text = pos.y.toString();
            }
          });
          
          // Real-time parameter sync to service
          _syncParametersToService();
        } catch (e) {
          // Ignore errors
        }
      }
    });
  }
  
  void _syncParametersToService() {
    try {
      final x = int.tryParse(_xController.text);
      final y = int.tryParse(_yController.text);
      final interval = int.tryParse(_intervalController.text);
      final intervalRandom = int.tryParse(_intervalRandomController.text);
      final offset = int.tryParse(_offsetController.text);

      if (x != null && y != null) {
        _service.setTargetPosition(x, y);
      }
      if (interval != null && interval >= 10) {
        _service.setClickInterval(interval);
      }
      if (intervalRandom != null && intervalRandom >= 0) {
        _service.setRandomInterval(intervalRandom);
      }
      if (offset != null && offset >= 0) {
        _service.setRandomOffset(offset);
      }
      _service.setMouseButton(_selectedButton);
    } catch (e) {
      // Ignore errors
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.errorTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btnOk),
          ),
        ],
      ),
    );
  }

  void _loadLastUsedConfig() {
    try {
      final config = ClickConfigService.instance.getLastUsedConfig();
      if (config != null) {
        _loadConfig(config);
        print('Loaded last used config: ${config.name}');
      }
    } catch (e) {
      print('Failed to load last used config: $e');
    }
  }

  void _loadConfig(ClickConfig config) {
    setState(() {
      _xController.text = config.x.toString();
      _yController.text = config.y.toString();
      _intervalController.text = config.interval.toString();
      _intervalRandomController.text = config.randomInterval.toString();
      _offsetController.text = config.offset.toString();
      _selectedButton = MouseButton.values[config.mouseButton];
    });
    print('Config loaded: ${config.name} - Position:(${config.x},${config.y}), Interval:${config.interval}ms');
  }

  Future<void> _saveCurrentConfig() async {
    final l10n = AppLocalizations.of(context);
    
    // Validate current settings
    final x = int.tryParse(_xController.text);
    final y = int.tryParse(_yController.text);
    final interval = int.tryParse(_intervalController.text);
    final intervalRandom = int.tryParse(_intervalRandomController.text);
    final offset = int.tryParse(_offsetController.text);

    if (x == null || y == null) {
      _showError(l10n.errorInvalidCoordinates);
      return;
    }
    if (interval == null || interval < 10) {
      _showError(l10n.errorInvalidInterval);
      return;
    }
    if (intervalRandom == null || intervalRandom < 0) {
      _showError(l10n.errorInvalidRandomRange);
      return;
    }
    if (offset == null || offset < 0) {
      _showError(l10n.errorInvalidOffset);
      return;
    }

    // Ask for config name
    final controller = TextEditingController(
      text: ClickConfigService.instance.generateDefaultName(),
    );

    final configName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.save, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(l10n.configSave, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.configName,
            border: const OutlineInputBorder(),
          ),
          inputFormatters: [
            LengthLimitingTextInputFormatter(50),
          ],
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btnCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.btnSave),
          ),
        ],
      ),
    );

    if (configName != null && configName.isNotEmpty) {
      try {
        final config = ClickConfigService.instance.createConfig(
          name: configName,
          x: x,
          y: y,
          interval: interval,
          randomInterval: intervalRandom,
          offset: offset,
          mouseButton: _selectedButton.value,
        );

        await ClickConfigService.instance.addConfig(config);
        await ClickConfigService.instance.setLastUsedConfig(config.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('${l10n.configSaveSuccess}: $configName'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        print('Error saving config: $e');
        _showError('${l10n.errorOperationFailed}: $e');
      }
    }
  }

  void _showConfigManagement() {
    showDialog(
      context: context,
      builder: (context) => ConfigManagementDialog(
        onConfigLoaded: (config) {
          _loadConfig(config);
        },
      ),
    );
  }

  void _showHotkeySettings() {
    showDialog(
      context: context,
      builder: (context) => HotkeySettingsDialog(
        currentToggleHotkeyCode: _service.currentToggleHotkeyCode,
        currentCaptureHotkeyCode: _service.currentCaptureHotkeyCode,
        onToggleHotkeyChanged: (vkCode) {
          bool success = _service.setToggleHotkey(vkCode);
          if (!success) {
            final l10n = AppLocalizations.of(context);
            _showError('${l10n.errorHotkeyFailed}\n${l10n.errorHotkeyFailedReasons}');
          } else {
            setState(() {}); // Refresh display
          }
        },
        onCaptureHotkeyChanged: (vkCode) {
          bool success = _service.setCaptureHotkey(vkCode);
          if (!success) {
            final l10n = AppLocalizations.of(context);
            _showError('${l10n.errorHotkeyFailed}\n${l10n.errorHotkeyFailedReasons}');
          } else {
            setState(() {}); // Refresh display
          }
        },
      ),
    );
  }

  void _showHelp() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.help_outline, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.helpTitle, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Start
                _buildHelpSection(
                  Icons.rocket_launch,
                  l10n.helpQuickStart,
                  l10n.helpQuickStartContent,
                  Colors.green,
                ),
                const SizedBox(height: 16),
                
                // Auto Mode
                _buildHelpSection(
                  Icons.gps_fixed,
                  l10n.helpAutoMode,
                  l10n.helpAutoModeContent,
                  Colors.blue,
                ),
                const SizedBox(height: 16),
                
                // Manual Mode
                _buildHelpSection(
                  Icons.edit_location,
                  l10n.helpManualMode,
                  l10n.helpManualModeContent,
                  Colors.orange,
                ),
                const SizedBox(height: 16),
                
                // Hotkeys
                _buildHelpSection(
                  Icons.keyboard,
                  l10n.helpHotkeys,
                  l10n.helpHotkeysContent,
                  Colors.purple,
                ),
                const SizedBox(height: 20),
                
                // FAQ Title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.quiz, size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        l10n.faqTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // FAQ Items
                _buildFaqItem(l10n.faqHotkeyNotWork, l10n.faqHotkeyNotWorkAnswer),
                const SizedBox(height: 12),
                _buildFaqItem(l10n.faqDllMissing, l10n.faqDllMissingAnswer),
                const SizedBox(height: 12),
                _buildFaqItem(l10n.faqAdminRequired, l10n.faqAdminRequiredAnswer),
                const SizedBox(height: 12),
                _buildFaqItem(l10n.faqSwitchMode, l10n.faqSwitchModeAnswer),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btnOk),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(IconData icon, String title, String content, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color.shade700),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSettings() {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
            Text(l10n.labelLanguage, style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: ListView(
            shrinkWrap: true,
            children: AppLocalizations.supportedLocales.map((locale) {
              final isSelected = LanguagePreference.instance.currentLocale == locale;
              return ListTile(
                leading: Radio<Locale>(
                  value: locale,
                  groupValue: LanguagePreference.instance.currentLocale,
                  onChanged: (Locale? value) {
                    if (value != null) {
                      widget.onLanguageChanged(value);
                      Navigator.pop(context);
                    }
                  },
                ),
                title: Text(
                  LanguagePreference.instance.getLanguageName(locale, l10n),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  widget.onLanguageChanged(locale);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.btnCancel),
          ),
        ],
      ),
    );
  }


  void _toggleAutoClick() {
    print('========================================');
    print('UI button click - Start/Stop');
    print('========================================');
    
    try {
      final l10n = AppLocalizations.of(context);
      final x = int.tryParse(_xController.text);
      final y = int.tryParse(_yController.text);
      final interval = int.tryParse(_intervalController.text);
      final intervalRandom = int.tryParse(_intervalRandomController.text);
      final offset = int.tryParse(_offsetController.text);

      print('Parameter validation:');
      print('  X coordinate: ${_xController.text} → ${x ?? "invalid"}');
      print('  Y coordinate: ${_yController.text} → ${y ?? "invalid"}');
      print('  Interval: ${_intervalController.text} → ${interval ?? "invalid"}ms');
      print('  Random: ${_intervalRandomController.text} → ${intervalRandom ?? "invalid"}ms');
      print('  Offset: ${_offsetController.text} → ${offset ?? "invalid"}px');

      if (x == null || y == null) {
        print('× Validation failed: Invalid coordinates');
        _showError('${l10n.errorInvalidCoordinates}\n\n${l10n.hintCaptureCoordinates}\n${l10n.hintInputCoordinates}');
        return;
      }

      if (interval == null || interval < 10) {
        print('× Validation failed: Invalid interval');
        _showError(l10n.errorInvalidInterval);
        return;
      }

      if (intervalRandom == null || intervalRandom < 0) {
        print('× Validation failed: Invalid random range');
        _showError(l10n.errorInvalidRandomRange);
        return;
      }

      if (offset == null || offset < 0) {
        print('× Validation failed: Invalid offset');
        _showError(l10n.errorInvalidOffset);
        return;
      }

      print('✓ Parameter validation passed');
      print('Setting parameters to service...');

      _service.setTargetPosition(x, y);
      _service.setClickInterval(interval);
      _service.setRandomInterval(intervalRandom);
      _service.setRandomOffset(offset);
      _service.setMouseButton(_selectedButton);

      print('Triggering toggle operation...');
      _service.toggleAutoClick();
      
      print('========================================');
    } catch (e) {
      print('× Exception: $e');
      final l10n = AppLocalizations.of(context);
      _showError('${l10n.errorOperationFailed}: $e');
    }
  }

  @override
  void dispose() {
    _uiUpdateTimer?.cancel();
    _service.dispose();
    _xController.dispose();
    _yController.dispose();
    _intervalController.dispose();
    _intervalRandomController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  Widget _buildCompactField(String label, TextEditingController controller, {double width = 80}) {
    return SizedBox(
      width: width,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          isDense: true,
          labelStyle: const TextStyle(fontSize: 12),
        ),
        style: const TextStyle(fontSize: 13),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onTap: () {
          // Switch to manual mode when clicking input field
          if (_autoCapture) {
            setState(() {
              _autoCapture = false;
            });
            print('Switched to manual input mode');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('${l10n.appTitle} v$appVersion', style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, size: 20),
            onPressed: _saveCurrentConfig,
            tooltip: l10n.configSave,
          ),
          IconButton(
            icon: const Icon(Icons.folder_special, size: 20),
            onPressed: _showConfigManagement,
            tooltip: l10n.configManage,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: _showHelp,
            tooltip: l10n.helpTitle,
          ),
          IconButton(
            icon: const Icon(Icons.language, size: 20),
            onPressed: _showLanguageSettings,
            tooltip: l10n.labelLanguage,
          ),
          IconButton(
            icon: const Icon(Icons.keyboard, size: 20),
            onPressed: _showHotkeySettings,
            tooltip: l10n.hotkeySettings,
          ),
        ],
      ),
      body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Current position and status card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                children: [
                    // First row: Position and count
                  Row(
                    children: [
                        const Icon(Icons.mouse, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('${l10n.labelCurrentPosition}: $_currentPosition', 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isRunning ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(12),
                        ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isRunning ? Icons.play_circle : Icons.pause_circle,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                          '${_service.clickCount}${l10n.statusClickCount}',
                                style: const TextStyle(
                                  color: Colors.white, 
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Second row: Current hotkeys
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Start/Stop hotkey
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow, size: 12, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '${l10n.hotkeyToggle}: ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              _buildHotkeyDisplay('Ctrl', Colors.green),
                              const Text(' + ', style: TextStyle(fontSize: 9)),
                              _buildHotkeyDisplay('Shift', Colors.green),
                              const Text(' + ', style: TextStyle(fontSize: 9)),
                              _buildHotkeyDisplay(_getKeyName(_service.currentToggleHotkeyCode), Colors.green),
                            ],
                          ),
                        ),
                        // Capture position hotkey
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.my_location, size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                '${l10n.hotkeyCapture}: ',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              _buildHotkeyDisplay('Ctrl', Colors.blue),
                              const Text(' + ', style: TextStyle(fontSize: 9)),
                              _buildHotkeyDisplay('Shift', Colors.blue),
                              const Text(' + ', style: TextStyle(fontSize: 9)),
                              _buildHotkeyDisplay(_getKeyName(_service.currentCaptureHotkeyCode), Colors.blue),
                            ],
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Target position settings
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                        Text(l10n.labelTargetPosition, 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _autoCapture ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _autoCapture ? Colors.green.shade300 : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _autoCapture ? Icons.gps_fixed : Icons.gps_off,
                                size: 12,
                                color: _autoCapture ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _autoCapture ? l10n.modeAuto : l10n.modeManual,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _autoCapture ? Colors.green.shade700 : Colors.grey.shade600,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _autoCapture = !_autoCapture;
                            });
                            print('Toggle mode: ${_autoCapture ? "Auto-track" : "Manual input"}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.swap_horiz,
                              size: 16,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                        ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildCompactField(l10n.labelXCoordinate, _xController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField(l10n.labelYCoordinate, _yController, width: double.infinity)),
                      ],
                      ),
                    ],
                ),
              ),
                  ),
                  const SizedBox(height: 8),

            // Click settings
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.labelClickSettings, 
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  Row(
                    children: [
                        Expanded(child: _buildCompactField(l10n.labelIntervalMs, _intervalController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField(l10n.labelRandomMs, _intervalRandomController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField(l10n.labelOffsetPx, _offsetController, width: double.infinity)),
                    ],
                  ),
                  const SizedBox(height: 8),
                    Text(l10n.labelMouseButton, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<MouseButton>(
                    segments: [
                          ButtonSegment(
                            value: MouseButton.left, 
                            label: Text(l10n.labelLeftButton, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.mouse, size: 16),
                          ),
                          ButtonSegment(
                            value: MouseButton.right, 
                            label: Text(l10n.labelRightButton, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.mouse, size: 16),
                          ),
                          ButtonSegment(
                            value: MouseButton.middle, 
                            label: Text(l10n.labelMiddleButton, style: const TextStyle(fontSize: 12)),
                            icon: const Icon(Icons.mouse, size: 16),
                          ),
                    ],
                    selected: {_selectedButton},
                    onSelectionChanged: (Set<MouseButton> newSelection) {
                      setState(() {
                        _selectedButton = newSelection.first;
                      });
                    },
                      ),
                    ),
                  ],
                ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Control button
                  SizedBox(
              height: 44,
                    child: ElevatedButton.icon(
                      onPressed: _toggleAutoClick,
                icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow, size: 20),
                      label: Text(
                  _isRunning ? l10n.btnStop : l10n.btnStart,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRunning ? Colors.red : Colors.green,
                        foregroundColor: Colors.white,
                  elevation: 4,
                      ),
                    ),
                  ),
            const SizedBox(height: 8),

            // Click history
          Expanded(
              child: Card(
                elevation: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.history, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 6),
                          Text(
                            l10n.historyRecentClicks,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                          ),
                        ],
                    ),
                  ),
                  Expanded(
                      child: _service.clickHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.inbox, size: 40, color: Colors.grey.shade300),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.msgNoClickHistory,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                      itemCount: _service.clickHistory.length,
                      itemBuilder: (context, index) {
                        final record = _service.clickHistory[index];
                                final isEven = index % 2 == 0;
                        return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                                    color: isEven ? Colors.white : Colors.grey.shade50,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 0.5,
                                      ),
                                    ),
                          ),
                                  child: Row(
                            children: [
                                      // Index
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Time
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                children: [
                                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                  Text(
                                    record.timeString,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                  ),
                                  ),
                                ],
                              ),
                                      ),
                                      // Position
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            Icon(Icons.location_on, size: 12, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                              Text(
                                '(${record.position.x}, ${record.position.y})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Button
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getButtonColor(record.button),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          record.buttonString,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  String _getKeyName(int vkCode) {
    const Map<int, String> keyMap = {
      0x41: 'A', 0x42: 'B', 0x43: 'C', 0x44: 'D', 0x45: 'E',
      0x46: 'F', 0x47: 'G', 0x48: 'H', 0x49: 'I', 0x4A: 'J',
      0x4B: 'K', 0x4C: 'L', 0x4D: 'M', 0x4E: 'N', 0x4F: 'O',
      0x50: 'P', 0x51: 'Q', 0x52: 'R', 0x53: 'S', 0x54: 'T',
      0x55: 'U', 0x56: 'V', 0x57: 'W', 0x58: 'X', 0x59: 'Y',
      0x5A: 'Z',
      0x30: '0', 0x31: '1', 0x32: '2', 0x33: '3', 0x34: '4',
      0x35: '5', 0x36: '6', 0x37: '7', 0x38: '8', 0x39: '9',
    };
    return keyMap[vkCode] ?? '?';
  }

  Color _getButtonColor(MouseButton button) {
    switch (button) {
      case MouseButton.left:
        return Colors.blue;
      case MouseButton.right:
        return Colors.orange;
      case MouseButton.middle:
        return Colors.purple;
    }
  }

  Widget _buildHotkeyDisplay(String key, [MaterialColor? color]) {
    final displayColor = color ?? Colors.purple;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: displayColor.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        key,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: displayColor.shade700,
        ),
      ),
    );
  }
}

// Hotkey settings dialog
class HotkeySettingsDialog extends StatefulWidget {
  final int currentToggleHotkeyCode;
  final int currentCaptureHotkeyCode;
  final Function(int) onToggleHotkeyChanged;
  final Function(int) onCaptureHotkeyChanged;

  const HotkeySettingsDialog({
    super.key,
    required this.currentToggleHotkeyCode,
    required this.currentCaptureHotkeyCode,
    required this.onToggleHotkeyChanged,
    required this.onCaptureHotkeyChanged,
  });

  @override
  State<HotkeySettingsDialog> createState() => _HotkeySettingsDialogState();
}

class _HotkeySettingsDialogState extends State<HotkeySettingsDialog> {
  late int _selectedToggleKey;
  late int _selectedCaptureKey;
  int _activeTab = 0; // 0=Start/Stop, 1=Capture

  // Common key virtual key code mapping
  static const Map<String, int> keyMap = {
    'A': 0x41, 'B': 0x42, 'C': 0x43, 'D': 0x44, 'E': 0x45,
    'F': 0x46, 'G': 0x47, 'H': 0x48, 'I': 0x49, 'J': 0x4A,
    'K': 0x4B, 'L': 0x4C, 'M': 0x4D, 'N': 0x4E, 'O': 0x4F,
    'P': 0x50, 'Q': 0x51, 'R': 0x52, 'S': 0x53, 'T': 0x54,
    'U': 0x55, 'V': 0x56, 'W': 0x57, 'X': 0x58, 'Y': 0x59,
    'Z': 0x5A,
    '0': 0x30, '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34,
    '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
  };

  @override
  void initState() {
    super.initState();
    _selectedToggleKey = widget.currentToggleHotkeyCode;
    _selectedCaptureKey = widget.currentCaptureHotkeyCode;
  }

  String _getKeyName(int vkCode) {
    for (var entry in keyMap.entries) {
      if (entry.value == vkCode) {
        return entry.key;
      }
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentKey = _activeTab == 0 ? _selectedToggleKey : _selectedCaptureKey;
    final keyName = _getKeyName(currentKey);
    final tabTitle = _activeTab == 0 ? l10n.hotkeyStartStop : l10n.hotkeyCapturePosition;
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(l10n.hotkeySettingsTitle, style: const TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tab buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _activeTab = 0),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(l10n.hotkeyStartStop, style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 0 ? Colors.green : Colors.grey.shade300,
                      foregroundColor: _activeTab == 0 ? Colors.white : Colors.black87,
                      elevation: _activeTab == 0 ? 2 : 0,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _activeTab = 1),
                    icon: const Icon(Icons.my_location, size: 16),
                    label: Text(l10n.hotkeyCapturePosition, style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _activeTab == 1 ? Colors.blue : Colors.grey.shade300,
                      foregroundColor: _activeTab == 1 ? Colors.white : Colors.black87,
                      elevation: _activeTab == 1 ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.hotkeySetFor} [$tabTitle] (Ctrl+Shift+Key)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.hotkeySelectKey,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: keyMap.entries.map((entry) {
                  final isSelected = currentKey == entry.value;
                return InkWell(
                  onTap: () {
                    setState(() {
                        if (_activeTab == 0) {
                          _selectedToggleKey = entry.value;
                        } else {
                          _selectedCaptureKey = entry.value;
                        }
                    });
                  },
                    borderRadius: BorderRadius.circular(4),
                  child: Container(
                      width: 34,
                      height: 34,
                    decoration: BoxDecoration(
                        color: isSelected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: isSelected ? Colors.blue.shade700 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected ? [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ] : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                          fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Column(
                children: [
                  Text(
                    '[$tabTitle] ${l10n.hotkeyPreview}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildKeyChip('Ctrl'),
                      const Text(' + ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      _buildKeyChip('Shift'),
                      const Text(' + ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      _buildKeyChip(keyName),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.btnCancel, style: const TextStyle(fontSize: 13)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // Call different callbacks based on current tab
            if (_activeTab == 0) {
              widget.onToggleHotkeyChanged(_selectedToggleKey);
            } else {
              widget.onCaptureHotkeyChanged(_selectedCaptureKey);
            }
            
            Navigator.pop(context);
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('[$tabTitle] ${l10n.msgHotkeySaved}: Ctrl+Shift+$keyName'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.check, size: 16),
          label: Text(l10n.btnSave, style: const TextStyle(fontSize: 13)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _activeTab == 0 ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildKeyChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.shade700, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blue.shade700,
        ),
      ),
    );
  }
}
