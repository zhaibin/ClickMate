import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'mouse_controller_bindings.dart';

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
        return '左键';
      case MouseButton.right:
        return '右键';
      case MouseButton.middle:
        return '中键';
    }
  }
}

class MouseControllerService {
  final MouseControllerBindings _bindings;
  Timer? _clickTimer;
  Timer? _hotkeyCheckTimer;
  bool _isRunning = false;

  // 配置参数
  int clickIntervalMs = 1000;
  int randomOffsetRange = 0;
  int randomIntervalRange = 0; // 时间间隔随机范围
  MouseButton selectedButton = MouseButton.left;
  MousePosition? targetPosition;

  // 点击统计
  int clickCount = 0;
  final List<ClickRecord> clickHistory = [];
  static const int maxHistorySize = 10;

  // 热键ID和虚拟键码
  static const int hotkeyId = 1;
  int currentHotkeyCode = 0x53; // 默认S键

  MouseControllerService(this._bindings) {
    // 初始化热键系统
    bool initSuccess = _bindings.initHotkeySystem();
    print('热键系统初始化: ${initSuccess ? "成功" : "失败"}');
    
    if (initSuccess) {
      // 注册默认热键 (Ctrl+Shift+S)
      bool regSuccess = _bindings.registerHotkey(hotkeyId, currentHotkeyCode);
      print('默认热键注册(Ctrl+Shift+S): ${regSuccess ? "成功" : "失败"}');
      
      if (regSuccess) {
        // 启动热键检查定时器
        _startHotkeyCheck();
      }
    }
  }

  bool setHotkey(int vkCode) {
    // 取消旧热键
    _bindings.unregisterHotkey(hotkeyId);
    print('旧热键已注销');
    
    // 注册新热键
    currentHotkeyCode = vkCode;
    bool success = _bindings.registerHotkey(hotkeyId, vkCode);
    print('新热键注册(VK_CODE: 0x${vkCode.toRadixString(16)}): ${success ? "成功" : "失败"}');
    
    return success;
  }

  bool get isRunning => _isRunning;

  void _startHotkeyCheck() {
    _hotkeyCheckTimer?.cancel();
    _hotkeyCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_bindings.checkHotkeyPressed(hotkeyId)) {
        toggleAutoClick();
      }
    });
  }

  void toggleAutoClick() {
    if (_isRunning) {
      stopAutoClick();
    } else {
      startAutoClick();
    }
  }

  void startAutoClick() {
    if (_isRunning) return;
    if (targetPosition == null) return;

    _isRunning = true;
    clickCount = 0; // 重置计数
    _performClick();
  }

  void stopAutoClick() {
    _isRunning = false;
    _clickTimer?.cancel();
    _clickTimer = null;
  }

  void _performClick() {
    if (!_isRunning || targetPosition == null) return;

    // 计算带随机偏移的位置
    final random = Random();
    final offsetX = randomOffsetRange > 0
        ? random.nextInt(randomOffsetRange * 2 + 1) - randomOffsetRange
        : 0;
    final offsetY = randomOffsetRange > 0
        ? random.nextInt(randomOffsetRange * 2 + 1) - randomOffsetRange
        : 0;

    final targetX = targetPosition!.x + offsetX;
    final targetY = targetPosition!.y + offsetY;

    // 移动鼠标并点击
    _bindings.moveMouse(targetX, targetY);
    Future.delayed(const Duration(milliseconds: 50), () {
      _bindings.clickMouse(selectedButton.value);

      // 记录点击
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

    // 计算带随机偏移的时间间隔
    final intervalOffset = randomIntervalRange > 0
        ? random.nextInt(randomIntervalRange * 2 + 1) - randomIntervalRange
        : 0;
    final actualInterval = (clickIntervalMs + intervalOffset).clamp(10, 1000000);

    // 计划下次点击
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
    _bindings.unregisterHotkey(hotkeyId);
    _bindings.dispose();
  }
}
