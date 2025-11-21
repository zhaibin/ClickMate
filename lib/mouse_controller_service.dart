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
  static const int hotkeyIdToggle = 1;    // 开始/停止快捷键ID
  static const int hotkeyIdCapture = 2;   // 捕获位置快捷键ID
  int currentToggleHotkeyCode = 0x31;     // 默认1键 (Ctrl+Shift+1)
  int currentCaptureHotkeyCode = 0x32;    // 默认2键 (Ctrl+Shift+2)
  
  // 捕获回调函数
  Function(int, int)? onPositionCaptured;

  MouseControllerService(this._bindings) {
    print('========================================');
    print('鼠标控制服务初始化中...');
    print('========================================');
    
    // 初始化热键系统
    LoggerService.instance.info('========================================');
    LoggerService.instance.info('初始化热键系统...');
    try {
      bool initSuccess = _bindings.initHotkeySystem();
      print('✓ 热键系统初始化: ${initSuccess ? "成功" : "失败"}');
      LoggerService.instance.info('热键系统初始化: ${initSuccess ? "成功" : "失败"}');
      
      if (initSuccess) {
        // 注册快捷键1: 开始/停止 (Ctrl+Shift+1)
        bool regToggle = _bindings.registerHotkey(hotkeyIdToggle, currentToggleHotkeyCode);
        print('${regToggle ? "✓" : "×"} 快捷键1 [开始/停止] Ctrl+Shift+1 (VK:0x${currentToggleHotkeyCode.toRadixString(16).toUpperCase()}): ${regToggle ? "成功" : "失败"}');
        LoggerService.instance.info('快捷键1 [开始/停止] Ctrl+Shift+1: ${regToggle ? "注册成功" : "注册失败"}');
        
        // 注册快捷键2: 捕获位置 (Ctrl+Shift+2)
        bool regCapture = _bindings.registerHotkey(hotkeyIdCapture, currentCaptureHotkeyCode);
        print('${regCapture ? "✓" : "×"} 快捷键2 [捕获位置] Ctrl+Shift+2 (VK:0x${currentCaptureHotkeyCode.toRadixString(16).toUpperCase()}): ${regCapture ? "成功" : "失败"}');
        LoggerService.instance.info('快捷键2 [捕获位置] Ctrl+Shift+2: ${regCapture ? "注册成功" : "注册失败"}');
        
        if (regToggle || regCapture) {
    // 启动热键检查定时器
    _startHotkeyCheck();
          print('✓ 热键监听已启动');
          LoggerService.instance.info('热键监听已启动');
        } else {
          print('× 所有热键注册失败！可能原因:');
          print('  1. 快捷键已被其他程序占用');
          print('  2. 需要以管理员权限运行');
          print('  解决方法: 尝试更换其他快捷键或以管理员身份运行');
          LoggerService.instance.warning('所有热键注册失败 - 可能需要管理员权限或快捷键被占用');
        }
      } else {
        print('× 热键系统初始化失败！');
        print('  原因: DLL加载失败或Windows API调用失败');
        print('  解决方法: 确保mouse_controller.dll在应用目录');
        LoggerService.instance.error('热键系统初始化失败 - DLL加载失败');
      }
    } catch (e) {
      print('× 热键系统初始化异常: $e');
      print('  请确保mouse_controller.dll文件存在');
      LoggerService.instance.error('热键系统初始化异常', e);
    }
    
    print('========================================');
    LoggerService.instance.info('========================================');
  }

  bool setToggleHotkey(int vkCode) {
    print('========================================');
    print('更换快捷键 [开始/停止]...');
    
    // 取消旧热键
    try {
      _bindings.unregisterHotkey(hotkeyIdToggle);
      print('✓ 旧快捷键已注销');
    } catch (e) {
      print('× 注销旧快捷键失败: $e');
    }
    
    // 注册新热键
    currentToggleHotkeyCode = vkCode;
    bool success = false;
    
    try {
      success = _bindings.registerHotkey(hotkeyIdToggle, vkCode);
      print('${success ? "✓" : "×"} 新快捷键注册 Ctrl+Shift+${_getKeyName(vkCode)} (VK:0x${vkCode.toRadixString(16).toUpperCase()}): ${success ? "成功" : "失败"}');
      
      if (!success) {
        print('× 注册失败可能原因:');
        print('  1. 该快捷键已被占用');
        print('  2. 需要管理员权限');
        print('  建议: 尝试其他快捷键');
      }
    } catch (e) {
      print('× 热键注册异常: $e');
    }
    
    print('========================================');
    return success;
  }
  
  bool setCaptureHotkey(int vkCode) {
    print('========================================');
    print('更换快捷键 [捕获位置]...');
    
    // 取消旧热键
    try {
      _bindings.unregisterHotkey(hotkeyIdCapture);
      print('✓ 旧快捷键已注销');
    } catch (e) {
      print('× 注销旧快捷键失败: $e');
    }
    
    // 注册新热键
    currentCaptureHotkeyCode = vkCode;
    bool success = false;
    
    try {
      success = _bindings.registerHotkey(hotkeyIdCapture, vkCode);
      print('${success ? "✓" : "×"} 新快捷键注册 Ctrl+Shift+${_getKeyName(vkCode)} (VK:0x${vkCode.toRadixString(16).toUpperCase()}): ${success ? "成功" : "失败"}');
      
      if (!success) {
        print('× 注册失败可能原因:');
        print('  1. 该快捷键已被占用');
        print('  2. 需要管理员权限');
        print('  建议: 尝试其他快捷键');
      }
    } catch (e) {
      print('× 热键注册异常: $e');
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
    print('启动热键监听定时器（每100ms检查一次）...');
    LoggerService.instance.debug('启动热键监听定时器（每100ms检查一次）');
    
    _hotkeyCheckTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      try {
        // 检查开始/停止快捷键
        if (_bindings.checkHotkeyPressed(hotkeyIdToggle)) {
          print('⚡ 检测到快捷键 [开始/停止] 按下！');
          LoggerService.instance.info('快捷键触发: 开始/停止');
        toggleAutoClick();
        }
        
        // 检查捕获位置快捷键
        if (_bindings.checkHotkeyPressed(hotkeyIdCapture)) {
          print('⚡ 检测到快捷键 [捕获位置] 按下！');
          LoggerService.instance.info('快捷键触发: 捕获位置');
          _capturePosition();
        }
      } catch (e) {
        print('× 热键检查异常: $e');
        LoggerService.instance.error('热键检查异常', e);
      }
    });
  }
  
  void _capturePosition() {
    try {
      final pos = getCurrentMousePosition();
      print('📍 捕获位置: (${pos.x}, ${pos.y})');
      
      // 如果有回调函数，调用它
      if (onPositionCaptured != null) {
        onPositionCaptured!(pos.x, pos.y);
      }
      
      // 自动设置为目标位置
      setTargetPosition(pos.x, pos.y);
      print('✓ 已设置为目标位置');
    } catch (e) {
      print('× 捕获位置失败: $e');
    }
  }

  void toggleAutoClick() {
    print('>>> 切换点击状态 (当前: ${_isRunning ? "运行中" : "已停止"})');
    if (_isRunning) {
      print('>>> 停止点击...');
      stopAutoClick();
    } else {
      print('>>> 尝试开始点击...');
      startAutoClick();
    }
  }

  void startAutoClick() {
    print('--- 开始点击检查 ---');
    LoggerService.instance.info('--- 开始点击检查 ---');
    
    if (_isRunning) {
      print('× 已经在运行中，忽略');
      LoggerService.instance.warning('尝试启动但已在运行中');
      return;
    }
    
    if (targetPosition == null) {
      print('× 无法开始：未设置目标位置！');
      print('  请先设置X和Y坐标（点击"捕获"按钮或手动输入）');
      LoggerService.instance.warning('无法开始 - 未设置目标位置');
      return;
    }
    
    print('✓ 目标位置: (${targetPosition!.x}, ${targetPosition!.y})');
    print('✓ 点击间隔: ${clickIntervalMs}ms');
    print('✓ 随机间隔: ±${randomIntervalRange}ms');
    print('✓ 位置偏移: ±${randomOffsetRange}px');
    print('✓ 鼠标按钮: ${selectedButton.name}');
    print('>>> 开始自动点击！');
    LoggerService.instance.info('开始自动点击 - 目标: (${targetPosition!.x}, ${targetPosition!.y}), 间隔: ${clickIntervalMs}ms, 按钮: ${selectedButton.name}');

    _isRunning = true;
    clickCount = 0; // 重置计数
    _performClick();
  }

  void stopAutoClick() {
    print('>>> 已停止点击');
    print('    总计点击: $clickCount 次');
    LoggerService.instance.info('停止自动点击 - 总计: $clickCount 次');
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

    // 计算带随机偏移的时间间隔
    final intervalOffset = randomIntervalRange > 0
        ? random.nextInt(randomIntervalRange * 2 + 1) - randomIntervalRange
        : 0;
    final actualInterval = (clickIntervalMs + intervalOffset).clamp(10, 1000000);

    // 每10次点击输出一次统计
    final shouldLog = clickCount == 0 || clickCount % 10 == 0;
    if (shouldLog) {
      LoggerService.instance.debug('点击统计: $clickCount 次, 目标: ($targetX, $targetY), 间隔: ${actualInterval}ms');
    }
    if (shouldLog) {
      print('[点击 #${clickCount + 1}] 位置:(${targetX},${targetY}) 间隔:${actualInterval}ms');
    }

    // 移动鼠标并点击
    try {
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
    } catch (e) {
      print('× 点击执行失败: $e');
      stopAutoClick();
      return;
    }

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
    _bindings.unregisterHotkey(hotkeyIdToggle);
    _bindings.unregisterHotkey(hotkeyIdCapture);
    _bindings.dispose();
  }
}
