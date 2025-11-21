import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'mouse_controller_bindings.dart';
import 'logger_service.dart';

class MousePosition {
  final int x;
  final int y;

  MousePosition(this.x, this.y);

  @override
  String toString() => 'MousePosition(x: $x, y: $y)';
}

class ClickRecord {
  final DateTime time;
  final MousePosition position;
  final MouseButton button;

  ClickRecord(this.time, this.position, this.button);

  String get timeString {
    return '${time.hour.toString().padLeft(2, '0')}:'
           '${time.minute.toString().padLeft(2, '0')}:'
           '${time.second.toString().padLeft(2, '0')}.'
           '${time.millisecond.toString().padLeft(3, '0')}';
  }

  String get buttonString {
    switch (button) {
      case MouseButton.left:
        return 'L';
      case MouseButton.right:
        return 'R';
      case MouseButton.middle:
        return 'M';
    }
  }
}

class MouseControllerService {
  final MouseControllerBindings _bindings;
  Timer? _clickTimer;
  Timer? _hotkeyCheckTimer;
  bool _isRunning = false;

  // Configuration parameters
  int clickIntervalMs = 1000;
  int randomOffsetRange = 0;
  int randomIntervalRange = 0; // Random range for time interval
  MouseButton selectedButton = MouseButton.left;
  MousePosition? targetPosition;

  // Click statistics
  int clickCount = 0;
  final List<ClickRecord> clickHistory = [];
  static const int maxHistorySize = 10;

  // Hotkey IDs and virtual key codes
  static const int hotkeyIdToggle = 1;    // Start/Stop hotkey ID
  static const int hotkeyIdCapture = 2;   // Capture position hotkey ID
  int currentToggleHotkeyCode = 0x31;     // Default: 1 key (Ctrl+Shift+1)
  int currentCaptureHotkeyCode = 0x32;    // Default: 2 key (Ctrl+Shift+2)
  
  // Capture callback function
  Function(int, int)? onPositionCaptured;

  MouseControllerService(this._bindings) {
    print('========================================');
    print('Mouse Control Service initializing...');
    print('========================================');
    
    // Initialize hotkey system
    try {
      bool initSuccess = _bindings.initHotkeySystem();
      print('✓ Hotkey system initialization: ${initSuccess ? "Success" : "Failed"}');
      
      if (initSuccess) {
        // Register hotkey 1: Start/Stop (Ctrl+Shift+1)
        bool regToggle = _bindings.registerHotkey(hotkeyIdToggle, currentToggleHotkeyCode);
        print('${regToggle ? "✓" : "×"} Hotkey 1 [Start/Stop] Ctrl+Shift+1 (VK:0x${currentToggleHotkeyCode.toRadixString(16).toUpperCase()}): ${regToggle ? "Success" : "Failed"}');
        
        // Register hotkey 2: Capture position (Ctrl+Shift+2)
        bool regCapture = _bindings.registerHotkey(hotkeyIdCapture, currentCaptureHotkeyCode);
        print('${regCapture ? "✓" : "×"} Hotkey 2 [Capture] Ctrl+Shift+2 (VK:0x${currentCaptureHotkeyCode.toRadixString(16).toUpperCase()}): ${regCapture ? "Success" : "Failed"}');
        
        if (regToggle || regCapture) {
    // Start hotkey check timer
    _startHotkeyCheck();
          print('✓ Hotkey listening started');
        } else {
          print('× All hotkey registration failed! Possible reasons:');
          print('  1. Hotkey already used by other program');
          print('  2. Need administrator permission');
          print('  Solution: Try different hotkeys or run as administrator');
          LoggerService.instance.warning('All hotkey registration failed - may need administrator permission or hotkey conflict');
        }
      } else {
        print('× Hotkey system initialization failed!');
        print('  Reason: DLL load failed or Windows API call failed');
        print('  Solution: Ensure mouse_controller.dll is in application directory');
        LoggerService.instance.error('Hotkey system initialization failed - DLL load failed');
      }
    } catch (e) {
      print('× Hotkey system initialization exception: $e');
      print('  Please ensure mouse_controller.dll file exists');
      LoggerService.instance.error('Hotkey system initialization exception', e);
    }
    
    print('========================================');
  }

  bool setToggleHotkey(int vkCode) {
    print('========================================');
    print('Changing hotkey [Start/Stop]...');
    
    // Unregister old hotkey
    try {
      _bindings.unregisterHotkey(hotkeyIdToggle);
      print('✓ Old hotkey unregistered');
    } catch (e) {
      print('× Failed to unregister old hotkey: $e');
    }
    
    // Register new hotkey
    currentToggleHotkeyCode = vkCode;
    bool success = false;
    
    try {
      success = _bindings.registerHotkey(hotkeyIdToggle, vkCode);
      print('${success ? "✓" : "×"} New hotkey register Ctrl+Shift+${_getKeyName(vkCode)} (VK:0x${vkCode.toRadixString(16).toUpperCase()}): ${success ? "Success" : "Failed"}');
      
      if (!success) {
        print('× Registration failed possible reasons:');
        print('  1. Hotkey already in use');
        print('  2. Need administrator permission');
        print('  Suggestion: Try other hotkeys');
      }
    } catch (e) {
      print('× Hotkey registration exception: $e');
    }
    
    print('========================================');
    return success;
  }
  
  bool setCaptureHotkey(int vkCode) {
    print('========================================');
    print('Changing hotkey [Capture Position]...');
    
    // Unregister old hotkey
    try {
      _bindings.unregisterHotkey(hotkeyIdCapture);
      print('✓ Old hotkey unregistered');
    } catch (e) {
      print('× Failed to unregister old hotkey: $e');
    }
    
    // Register new hotkey
    currentCaptureHotkeyCode = vkCode;
    bool success = false;
    
    try {
      success = _bindings.registerHotkey(hotkeyIdCapture, vkCode);
      print('${success ? "✓" : "×"} New hotkey register Ctrl+Shift+${_getKeyName(vkCode)} (VK:0x${vkCode.toRadixString(16).toUpperCase()}): ${success ? "Success" : "Failed"}');
      
      if (!success) {
        print('× Registration failed possible reasons:');
        print('  1. Hotkey already in use');
        print('  2. Need administrator permission');
        print('  Suggestion: Try other hotkeys');
      }
    } catch (e) {
      print('× Hotkey registration exception: $e');
    }
    
    print('========================================');
    return success;
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

  bool get isRunning => _isRunning;

  void _startHotkeyCheck() {
    _hotkeyCheckTimer?.cancel();
    print('Starting hotkey listener timer (check every 100ms)...');
    
    _hotkeyCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      try {
        // Check Start/Stop hotkey
        if (_bindings.checkHotkeyPressed(hotkeyIdToggle)) {
          print('⚡ Detected hotkey [Start/Stop] pressed!');
        toggleAutoClick();
        }
        
        // Check Capture position hotkey
        if (_bindings.checkHotkeyPressed(hotkeyIdCapture)) {
          print('⚡ Detected hotkey [Capture Position] pressed!');
          _capturePosition();
        }
      } catch (e) {
        print('× Hotkey check exception: $e');
        LoggerService.instance.error('Hotkey check exception', e);
      }
    });
  }
  
  void _capturePosition() {
    try {
      final pos = getCurrentMousePosition();
      print('📍 Captured position: (${pos.x}, ${pos.y})');
      
      // Call callback function if exists
      if (onPositionCaptured != null) {
        onPositionCaptured!(pos.x, pos.y);
      }
      
      // Automatically set as target position
      setTargetPosition(pos.x, pos.y);
      print('✓ Set as target position');
    } catch (e) {
      print('× Capture position failed: $e');
    }
  }

  void toggleAutoClick() {
    print('>>> Toggle click status (Current: ${_isRunning ? "Running" : "Stopped"})');
    if (_isRunning) {
      print('>>> Stopping click...');
      stopAutoClick();
    } else {
      print('>>> Trying to start click...');
      startAutoClick();
    }
  }

  void startAutoClick() {
    print('--- Start click check ---');
    
    if (_isRunning) {
      print('× Already running, ignored');
      return;
    }
    
    if (targetPosition == null) {
      print('× Cannot start: Target position not set!');
      print('  Please set X and Y coordinates first (Click "Capture" button or manual input)');
      LoggerService.instance.warning('Cannot start - target position not set');
      return;
    }
    
    print('✓ Target position: (${targetPosition!.x}, ${targetPosition!.y})');
    print('✓ Click interval: ${clickIntervalMs}ms');
    print('✓ Random interval: ±${randomIntervalRange}ms');
    print('✓ Position offset: ±${randomOffsetRange}px');
    print('✓ Mouse button: ${selectedButton.name}');
    print('>>> Start auto-clicking!');

    _isRunning = true;
    clickCount = 0; // Reset count
    _performClick();
  }

  void stopAutoClick() {
    print('>>> Stopped clicking');
    print('    Total clicks: $clickCount times');
    _isRunning = false;
    _clickTimer?.cancel();
    _clickTimer = null;
  }

  void _performClick() {
    if (!_isRunning || targetPosition == null) return;

    // Calculate position with random offset
    final random = Random();
    final offsetX = randomOffsetRange > 0
        ? random.nextInt(randomOffsetRange * 2 + 1) - randomOffsetRange
        : 0;
    final offsetY = randomOffsetRange > 0
        ? random.nextInt(randomOffsetRange * 2 + 1) - randomOffsetRange
        : 0;

    final targetX = targetPosition!.x + offsetX;
    final targetY = targetPosition!.y + offsetY;

    // Calculate interval with random offset
    final intervalOffset = randomIntervalRange > 0
        ? random.nextInt(randomIntervalRange * 2 + 1) - randomIntervalRange
        : 0;
    final actualInterval = (clickIntervalMs + intervalOffset).clamp(10, 1000000);

    // Output statistics every 10 clicks (console only, not logged to file)
    final shouldLog = clickCount == 0 || clickCount % 10 == 0;
    if (shouldLog) {
      print('[Click #${clickCount + 1}] Position:($targetX,$targetY) Interval:${actualInterval}ms');
    }

    // Move mouse and click
    try {
    _bindings.moveMouse(targetX, targetY);
    Future.delayed(const Duration(milliseconds: 50), () {
      _bindings.clickMouse(selectedButton.value);

      // Record click
      clickCount++;
      final record = ClickRecord(
        DateTime.now(),
        MousePosition(targetX, targetY),
        selectedButton,
      );
      clickHistory.insert(0, record);
      if (clickHistory.length > maxHistorySize) {
        clickHistory.removeLast();
      }
    });
    } catch (e) {
      print('× Click execution failed: $e');
      stopAutoClick();
      return;
    }

    // Schedule next click
    _clickTimer = Timer(Duration(milliseconds: actualInterval), _performClick);
  }

  MousePosition getCurrentMousePosition() {
    final xPtr = calloc<Int32>();
    final yPtr = calloc<Int32>();

    try {
      _bindings.getMousePosition(xPtr, yPtr);
      return MousePosition(xPtr.value, yPtr.value);
    } finally {
      calloc.free(xPtr);
      calloc.free(yPtr);
    }
  }

  void setTargetPosition(int x, int y) {
    targetPosition = MousePosition(x, y);
  }

  void setClickInterval(int milliseconds) {
    clickIntervalMs = milliseconds;
  }

  void setRandomOffset(int offset) {
    randomOffsetRange = offset;
  }

  void setRandomInterval(int interval) {
    randomIntervalRange = interval;
  }

  void setMouseButton(MouseButton button) {
    selectedButton = button;
  }

  void dispose() {
    stopAutoClick();
    _hotkeyCheckTimer?.cancel();
    _bindings.unregisterHotkey(hotkeyIdToggle);
    _bindings.unregisterHotkey(hotkeyIdCapture);
    _bindings.dispose();
  }
}
