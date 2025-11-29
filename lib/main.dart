import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';
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
  
  // Set window properties - hide window initially to prevent flicker
  WindowOptions windowOptions = const WindowOptions(
    size: Size(400, 640),
    minimumSize: Size(400, 640),
    maximumSize: Size(400, 640),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    title: 'ClickMate',
  );
  
  // Wait until window is ready before showing
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // Set all properties before showing
    await windowManager.setResizable(false);
    await windowManager.setSize(const Size(400, 640));
    await windowManager.center();
    // Now show and focus
    await windowManager.show();
    await windowManager.focus();
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
    // Unified design theme
    const primaryColor = Color(0xFF1E3A5F);
    const accentColor = Color(0xFF3B82F6);
    
    return MaterialApp(
      title: 'ClickMate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          primary: primaryColor,
          secondary: accentColor,
          surface: const Color(0xFFF8FAFC),
          surfaceContainerHighest: Colors.white,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          color: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        dialogTheme: DialogThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
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
  MouseControllerService? _service;
  bool _serviceInitialized = false;
  String? _initError;
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
      _serviceInitialized = true;
      
      // Load last used configuration
      _loadLastUsedConfig();
      
      // Set position capture callback
      _service!.onPositionCaptured = (x, y) {
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
      
      // Set before start callback for auto-saving config
      _service!.onBeforeStart = () async {
        await _autoSaveCurrentConfig();
      };
      
      _startUiUpdate();
      
      // Delayed hotkey status check
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _checkHotkeyStatus();
        }
      });
    } catch (e) {
      _initError = e.toString();
      print('Failed to initialize MouseControllerService: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          _showError('${l10n.errorInitFailed}: $e\n\nPlease check console output for details');
        }
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
          final pos = _service!.getCurrentMousePosition();
          setState(() {
            _currentPosition = '(${pos.x}, ${pos.y})';
            _isRunning = _service!.isRunning;
            
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
        _service!.setTargetPosition(x, y);
      }
      if (interval != null && interval >= 10) {
        _service!.setClickInterval(interval);
      }
      if (intervalRandom != null && intervalRandom >= 0) {
        _service!.setRandomInterval(intervalRandom);
      }
      if (offset != null && offset >= 0) {
        _service!.setRandomOffset(offset);
      }
      _service!.setMouseButton(_selectedButton);
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
      // Switch to manual mode when loading config (config contains fixed coordinates)
      _autoCapture = false;
    });
    print('Config loaded: ${config.name} - Position:(${config.x},${config.y}), Interval:${config.interval}ms, Mode: Manual');
    
    // Auto-move mouse to config position
    _moveMouseToTarget();
  }

  void _moveMouseToTarget() {
    try {
      final x = int.tryParse(_xController.text);
      final y = int.tryParse(_yController.text);
      
      if (x != null && y != null) {
        _service!.setTargetPosition(x, y);
        // Use the service bindings to move mouse
        _service!.bindings.moveMouse(x, y);
        print('Mouse moved to: ($x, $y)');
        
        // Show notification
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.near_me, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('${l10n.btnMoveMouse}: ($x, $y)'),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Failed to move mouse: $e');
    }
  }

  void _resetToDefaults() {
    setState(() {
      _intervalController.text = '1000';
      _intervalRandomController.text = '0';
      _offsetController.text = '0';
      _selectedButton = MouseButton.left;
    });
    print('Reset click settings to defaults: Interval=1000ms, Random=0ms, Offset=0px, Button=Left');
    
    // Show notification
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(l10n.btnResetDefaults),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        currentConfigId: ClickConfigService.instance.getLastUsedConfigId(),
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
        currentToggleHotkeyCode: _service!.currentToggleHotkeyCode,
        currentCaptureHotkeyCode: _service!.currentCaptureHotkeyCode,
        onToggleHotkeyChanged: (vkCode) {
          bool success = _service!.setToggleHotkey(vkCode);
          if (!success) {
            final l10n = AppLocalizations.of(context);
            _showError('${l10n.errorHotkeyFailed}\n${l10n.errorHotkeyFailedReasons}');
          } else {
            setState(() {}); // Refresh display
          }
        },
        onCaptureHotkeyChanged: (vkCode) {
          bool success = _service!.setCaptureHotkey(vkCode);
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
    final isMac = Platform.isMacOS;
    const primaryColor = Color(0xFF1E3A5F);
    
    // Platform-specific hotkey content
    final hotkeyContent = isMac 
        ? '⌘+⇧+1: ${l10n.hotkeyToggle}\n⌘+⇧+2: ${l10n.hotkeyCapture}\n\n${l10n.msgPermissionRequired}'
        : 'Ctrl+Shift+1: ${l10n.hotkeyToggle}\nCtrl+Shift+2: ${l10n.hotkeyCapture}\n\n${l10n.msgAdminRequired}';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 360,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_outline, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.helpTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Platform badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isMac ? Icons.laptop_mac : Icons.laptop_windows,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isMac ? 'macOS' : 'Windows',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Start
                      _buildHelpSection(
                        Icons.rocket_launch,
                        l10n.helpQuickStart,
                        l10n.helpQuickStartContent,
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(height: 12),
                      
                      // Auto Mode
                      _buildHelpSection(
                        Icons.gps_fixed,
                        l10n.helpAutoMode,
                        l10n.helpAutoModeContent,
                        const Color(0xFF3B82F6),
                      ),
                      const SizedBox(height: 12),
                      
                      // Manual Mode
                      _buildHelpSection(
                        Icons.edit_location_alt,
                        l10n.helpManualMode,
                        l10n.helpManualModeContent,
                        const Color(0xFFF59E0B),
                      ),
                      const SizedBox(height: 12),
                      
                      // Hotkeys (platform-specific)
                      _buildHelpSection(
                        Icons.keyboard,
                        l10n.helpHotkeys,
                        hotkeyContent,
                        const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 16),
                      
                      // FAQ Title
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.quiz, size: 14, color: Colors.red.shade600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.faqTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // FAQ Items (platform-specific)
                      if (isMac) ...[
                        _buildFaqItem(
                          l10n.faqHotkeyNotWork,
                          l10n.faqHotkeyNotWorkAnswerMac,
                        ),
                        const SizedBox(height: 8),
                        _buildFaqItem(
                          l10n.faqDylibMissing,
                          l10n.faqDylibMissingAnswer,
                        ),
                        const SizedBox(height: 8),
                        _buildFaqItem(
                          l10n.faqPermissionRequired,
                          l10n.faqPermissionRequiredAnswer,
                        ),
                      ] else ...[
                        _buildFaqItem(l10n.faqHotkeyNotWork, l10n.faqHotkeyNotWorkAnswer),
                        const SizedBox(height: 8),
                        _buildFaqItem(l10n.faqDllMissing, l10n.faqDllMissingAnswer),
                        const SizedBox(height: 8),
                        _buildFaqItem(l10n.faqAdminRequired, l10n.faqAdminRequiredAnswer),
                      ],
                      const SizedBox(height: 8),
                      _buildFaqItem(l10n.faqSwitchMode, l10n.faqSwitchModeAnswer),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l10n.btnOk),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection(IconData icon, String title, String content, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 12, height: 1.5, color: Colors.grey.shade700),
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
        borderRadius: BorderRadius.circular(8),
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
    const primaryColor = Color(0xFF1E3A5F);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 280,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.translate, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      l10n.labelLanguage,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Language list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 350),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: AppLocalizations.supportedLocales.map((locale) {
                    final isSelected = LanguagePreference.instance.currentLocale == locale;
                    return InkWell(
                      onTap: () {
                        widget.onLanguageChanged(locale);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
                          border: Border(
                            left: BorderSide(
                              color: isSelected ? primaryColor : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                LanguagePreference.instance.getLanguageName(locale, l10n),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected ? primaryColor : Colors.grey.shade700,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle, size: 18, color: primaryColor),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(l10n.btnCancel, style: TextStyle(color: Colors.grey.shade600)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showAbout() {
    final l10n = AppLocalizations.of(context);
    const primaryColor = Color(0xFF1E3A5F);
    const accentColor = Color(0xFF3B82F6);
    
    // Open source libraries with their URLs
    final openSourceLibs = [
      {'name': 'Flutter', 'desc': 'UI Framework', 'url': 'https://flutter.dev'},
      {'name': 'window_manager', 'desc': 'Window Management', 'url': 'https://pub.dev/packages/window_manager'},
      {'name': 'ffi', 'desc': 'Native Code Bridge', 'url': 'https://pub.dev/packages/ffi'},
      {'name': 'shared_preferences', 'desc': 'Local Storage', 'url': 'https://pub.dev/packages/shared_preferences'},
      {'name': 'url_launcher', 'desc': 'URL Launcher', 'url': 'https://pub.dev/packages/url_launcher'},
    ];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with solid color background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: const BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // App Icon
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/icons/icon.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // App Name
                    const Text(
                      'ClickMate',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Version badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'v$appVersion  •  ${Platform.isMacOS ? "macOS" : "Windows"}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Website link
                    InkWell(
                      onTap: () => _launchUrl('https://clickmate.xants.net'),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primaryColor.withOpacity(0.15)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.language, size: 18, color: primaryColor),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'clickmate.xants.net',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(Icons.open_in_new, size: 14, color: primaryColor.withOpacity(0.5)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    
                    // Open Source section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(Icons.code, size: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.aboutOpenSource,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Scrollable open source list
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 130),
                            child: SingleChildScrollView(
                              child: Column(
                                children: openSourceLibs.map((lib) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: InkWell(
                                    onTap: () => _launchUrl(lib['url']!),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                              color: accentColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: lib['name']!,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey.shade800,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: '  ${lib['desc']!}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(Icons.open_in_new, size: 10, color: Colors.grey.shade400),
                                        ],
                                      ),
                                    ),
                                  ),
                                )).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
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
            child: Text(l10n.btnOk),
          ),
        ],
      ),
    );
  }

  Future<void> _autoSaveCurrentConfig() async {
    print('Auto-saving current configuration...');
    try {
      final x = int.tryParse(_xController.text);
      final y = int.tryParse(_yController.text);
      final interval = int.tryParse(_intervalController.text);
      final intervalRandom = int.tryParse(_intervalRandomController.text);
      final offset = int.tryParse(_offsetController.text);

      if (x != null && y != null && 
          interval != null && interval >= 10 &&
          intervalRandom != null && intervalRandom >= 0 &&
          offset != null && offset >= 0) {
        await ClickConfigService.instance.autoSaveConfig(
          x: x,
          y: y,
          interval: interval,
          randomInterval: intervalRandom,
          offset: offset,
          mouseButton: _selectedButton.value,
        );
      }
    } catch (e) {
      print('Warning: Auto-save config failed: $e');
    }
  }

  void _toggleAutoClick() async {
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
      
      _service!.setTargetPosition(x, y);
      _service!.setClickInterval(interval);
      _service!.setRandomInterval(intervalRandom);
      _service!.setRandomOffset(offset);
      _service!.setMouseButton(_selectedButton);

      print('Triggering toggle operation...');
      _service!.toggleAutoClick();
      
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
    _service?.dispose();
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
    
    // Show error page if service initialization failed
    if (!_serviceInitialized || _service == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.red.shade100,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  'assets/icons/icon.png',
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 10),
              Text(l10n.appTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  l10n.errorInitFailed,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _initError ?? 'Unknown error',
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'macOS: Please ensure libmouse_controller.dylib is compiled and accessible.\n'
                  'Run: clang++ -shared -fPIC -framework Cocoa -framework Carbon -framework CoreGraphics '
                  '-o libmouse_controller.dylib mouse_controller_macos.mm',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    const primaryColor = Color(0xFF1E3A5F);
    const accentColor = Color(0xFF3B82F6);
    
    // Wrap with ClipRRect for consistent corner radius on macOS
    return ClipRRect(
      borderRadius: Platform.isMacOS 
          ? const BorderRadius.all(Radius.circular(10))
          : BorderRadius.zero,
      child: Scaffold(
      appBar: AppBar(
        toolbarHeight: Platform.isMacOS ? 48 : 48,
        leadingWidth: Platform.isMacOS ? 70 : 0,
        leading: Platform.isMacOS ? Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _WindowButtonsGroup(
            onClose: () => windowManager.close(),
            onMinimize: () => windowManager.minimize(),
          ),
        ) : null,
        titleSpacing: 0,
        title: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (_) => windowManager.startDragging(),
          child: Container(
            height: 48,
            padding: EdgeInsets.only(left: Platform.isMacOS ? 0 : 12),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      'assets/icons/icon.png',
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(l10n.appTitle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3)),
              ],
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.more_horiz, size: 20),
            ),
            tooltip: l10n.menuTitle,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              switch (value) {
                case 'save':
                  _saveCurrentConfig();
                  break;
                case 'manage':
                  _showConfigManagement();
                  break;
                case 'hotkey':
                  _showHotkeySettings();
                  break;
                case 'language':
                  _showLanguageSettings();
                  break;
                case 'help':
                  _showHelp();
                  break;
                case 'about':
                  _showAbout();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'save',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.save_outlined, size: 16, color: accentColor),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.configSave, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'manage',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.folder_outlined, size: 16, color: Colors.amber.shade700),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.configManage, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 8),
              PopupMenuItem(
                value: 'hotkey',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.keyboard_outlined, size: 16, color: Colors.purple.shade600),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.hotkeySettings, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'language',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.translate, size: 16, color: Colors.teal.shade600),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.labelLanguage, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 8),
              PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.help_outline, size: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.helpTitle, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.info_outline, size: 16, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.aboutTitle, style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Windows window control buttons (right side)
          if (!Platform.isMacOS) ...[
            _WindowsControlButton(
              icon: Icons.remove,
              onTap: () => windowManager.minimize(),
              hoverColor: Colors.white.withOpacity(0.1),
            ),
            _WindowsControlButton(
              icon: Icons.close,
              onTap: () => windowManager.close(),
              hoverColor: const Color(0xFFE81123),
              isClose: true,
            ),
          ],
        ],
      ),
      body: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status header card - light style
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                children: [
                    // First row: Position and count
                  Row(
                    children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.mouse, size: 14, color: primaryColor),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.labelCurrentPosition, 
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                            const SizedBox(height: 1),
                            Text(_currentPosition, 
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryColor)),
                          ],
                        ),
                      const Spacer(),
                      Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isRunning ? const Color(0xFF10B981) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                        ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: _isRunning ? Colors.white : Colors.grey.shade500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                          '${_service!.clickCount}${l10n.statusClickCount}',
                                style: TextStyle(
                                  color: _isRunning ? Colors.white : Colors.grey.shade600, 
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Second row: Current hotkeys
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          // Start/Stop hotkey
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_arrow, size: 12, color: const Color(0xFF10B981)),
                                const SizedBox(width: 4),
                                _buildHotkeyBadgeLight(_modifierKey),
                                Text('+', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                _buildHotkeyBadgeLight('⇧'),
                                Text('+', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                _buildHotkeyBadgeLight(_getKeyName(_service!.currentToggleHotkeyCode)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 16, color: Colors.grey.shade300),
                          // Capture position hotkey
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.my_location, size: 12, color: accentColor),
                                const SizedBox(width: 4),
                                _buildHotkeyBadgeLight(_modifierKey),
                                Text('+', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                _buildHotkeyBadgeLight('⇧'),
                                Text('+', style: TextStyle(fontSize: 9, color: Colors.grey.shade400)),
                                _buildHotkeyBadgeLight(_getKeyName(_service!.currentCaptureHotkeyCode)),
                              ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Target position settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Row(
                    children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.location_on, size: 14, color: accentColor),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.labelTargetPosition, 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        // Mode toggle
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _autoCapture = !_autoCapture;
                            });
                            print('Toggle mode: ${_autoCapture ? "Auto-track" : "Manual input"}');
                          },
                          child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _autoCapture ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _autoCapture ? const Color(0xFF10B981) : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _autoCapture ? Icons.gps_fixed : Icons.edit_location_alt,
                                size: 12,
                                color: _autoCapture ? const Color(0xFF10B981) : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _autoCapture ? l10n.modeAuto : l10n.modeManual,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _autoCapture ? const Color(0xFF10B981) : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.swap_horiz,
                                size: 12,
                                color: _autoCapture ? const Color(0xFF10B981) : Colors.grey.shade500,
                              ),
                            ],
                          ),
                        ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                  const SizedBox(height: 6),

            // Click settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(Icons.settings, size: 14, color: Colors.purple.shade600),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.labelClickSettings, 
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _resetToDefaults,
                          icon: Icon(Icons.refresh, size: 14, color: Colors.grey.shade600),
                          label: Text(l10n.btnResetDefaults, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  Row(
                    children: [
                        Expanded(child: _buildCompactField(l10n.labelIntervalMs, _intervalController, width: double.infinity)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildCompactField(l10n.labelRandomMs, _intervalRandomController, width: double.infinity)),
                        const SizedBox(width: 6),
                        Expanded(child: _buildCompactField(l10n.labelOffsetPx, _offsetController, width: double.infinity)),
                    ],
                  ),
                  const SizedBox(height: 8),
                    Text(l10n.labelMouseButton, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<MouseButton>(
                    segments: [
                          ButtonSegment(
                            value: MouseButton.left, 
                            label: Text(l10n.labelLeftButton, style: const TextStyle(fontSize: 11)),
                            icon: const Icon(Icons.mouse, size: 14),
                          ),
                          ButtonSegment(
                            value: MouseButton.right, 
                            label: Text(l10n.labelRightButton, style: const TextStyle(fontSize: 11)),
                            icon: const Icon(Icons.mouse, size: 14),
                          ),
                          ButtonSegment(
                            value: MouseButton.middle, 
                            label: Text(l10n.labelMiddleButton, style: const TextStyle(fontSize: 11)),
                            icon: const Icon(Icons.mouse, size: 14),
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
                  const SizedBox(height: 8),

                  // Control buttons
                  Row(
                    children: [
                      // Move mouse button
                      SizedBox(
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: _moveMouseToTarget,
                          icon: const Icon(Icons.near_me, size: 14),
                          label: Text(
                            l10n.btnMoveMouse,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Start/Stop button
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton.icon(
                            onPressed: _toggleAutoClick,
                            icon: Icon(_isRunning ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 20),
                            label: Text(
                              _isRunning ? l10n.btnStop : l10n.btnStart,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRunning ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 8),

            // Click history
          Expanded(
              child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(Icons.history, size: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.historyRecentClicks,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                          ),
                        ],
                    ),
                  ),
                  Expanded(
                      child: _service!.clickHistory.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inbox_outlined, size: 32, color: Colors.grey.shade300),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.msgNoClickHistory,
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                      itemCount: _service!.clickHistory.length,
                      itemBuilder: (context, index) {
                        final record = _service!.clickHistory[index];
                                final isEven = index % 2 == 0;
                        return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                                    color: isEven ? Colors.white : Colors.grey.shade50,
                          ),
                                  child: Row(
                            children: [
                                      // Index
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Time
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                children: [
                                            Icon(Icons.schedule, size: 12, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                  Text(
                                    record.timeString,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade700,
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
                                            Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                              Text(
                                '(${record.position.x}, ${record.position.y})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Button
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getButtonColor(record.button).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          record.buttonString,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getButtonColor(record.button),
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
      ),
    );
  }

  Widget _buildHotkeyBadgeLight(String key) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        key,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
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

  // Get modifier key name based on platform (Cmd for macOS, Ctrl for Windows)
  String get _modifierKey => Platform.isMacOS ? '⌘' : 'Ctrl';

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
    const primaryColor = Color(0xFF1E3A5F);
    const accentColor = Color(0xFF3B82F6);
    const greenColor = Color(0xFF10B981);
    
    final activeColor = _activeTab == 0 ? greenColor : accentColor;
    
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with tabs integrated
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              decoration: const BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.keyboard, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.hotkeySettingsTitle,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 0),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: _activeTab == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded, size: 14,
                                    color: _activeTab == 0 ? greenColor : Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(l10n.hotkeyStartStop,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _activeTab == 0 ? greenColor : Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _activeTab = 1),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: _activeTab == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.my_location, size: 14,
                                    color: _activeTab == 1 ? accentColor : Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(l10n.hotkeyCapturePosition,
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                      color: _activeTab == 1 ? accentColor : Colors.white70)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Key grid
            Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 5,
                runSpacing: 5,
                children: keyMap.entries.map((entry) {
                  final isSelected = currentKey == entry.value;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_activeTab == 0) {
                          _selectedToggleKey = entry.value;
                        } else {
                          _selectedCaptureKey = entry.value;
                        }
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isSelected ? activeColor : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            // Preview & Actions
            Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  // Preview
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: activeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildKeyChip(Platform.isMacOS ? '⌘' : 'Ctrl', activeColor),
                        Text(' + ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        _buildKeyChip(Platform.isMacOS ? '⇧' : 'Shift', activeColor),
                        Text(' + ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
                        _buildKeyChip(keyName, activeColor),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.btnCancel, style: TextStyle(color: Colors.grey.shade600)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_activeTab == 0) {
                              widget.onToggleHotkeyChanged(_selectedToggleKey);
                            } else {
                              widget.onCaptureHotkeyChanged(_selectedCaptureKey);
                            }
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${Platform.isMacOS ? "⌘+⇧" : "Ctrl+Shift"}+$keyName'),
                                backgroundColor: activeColor,
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.btnSave),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}

// macOS style window control buttons group
class _WindowButtonsGroup extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const _WindowButtonsGroup({
    required this.onClose,
    required this.onMinimize,
  });

  @override
  State<_WindowButtonsGroup> createState() => _WindowButtonsGroupState();
}

class _WindowButtonsGroupState extends State<_WindowButtonsGroup> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Close button
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5F57),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE14942),
                  width: 0.5,
                ),
              ),
              child: _isHovered
                  ? CustomPaint(
                      size: const Size(12, 12),
                      painter: _CloseIconPainter(),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          // Minimize button
          GestureDetector(
            onTap: widget.onMinimize,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFFFEBC2E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFE0A123),
                  width: 0.5,
                ),
              ),
              child: _isHovered
                  ? CustomPaint(
                      size: const Size(12, 12),
                      painter: _MinimizeIconPainter(),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for close icon (X)
class _CloseIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4D0000)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    
    final center = size.width / 2;
    final offset = 3.0;
    
    canvas.drawLine(
      Offset(center - offset, center - offset),
      Offset(center + offset, center + offset),
      paint,
    );
    canvas.drawLine(
      Offset(center + offset, center - offset),
      Offset(center - offset, center + offset),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for minimize icon (-)
class _MinimizeIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF995700)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    final center = size.height / 2;
    final offset = 3.0;
    
    canvas.drawLine(
      Offset(size.width / 2 - offset, center),
      Offset(size.width / 2 + offset, center),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Windows style window control button
class _WindowsControlButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;
  final bool isClose;

  const _WindowsControlButton({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
    this.isClose = false,
  });

  @override
  State<_WindowsControlButton> createState() => _WindowsControlButtonState();
}

class _WindowsControlButtonState extends State<_WindowsControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 48,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _isHovered && widget.isClose ? Colors.white : Colors.white.withOpacity(0.9),
          ),
        ),
      ),
    );
  }
}

