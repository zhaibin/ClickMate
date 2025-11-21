import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:window_manager/window_manager.dart';
import 'mouse_controller_bindings.dart';
import 'mouse_controller_service.dart';
import 'logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化日志系统
  await LoggerService.instance.initialize();
  LoggerService.instance.info('应用启动中...');
  
  // 初始化窗口管理器
  await windowManager.ensureInitialized();
  LoggerService.instance.info('窗口管理器初始化完成');
  
  // 设置窗口属性
  WindowOptions windowOptions = const WindowOptions(
    size: Size(520, 680),          // 增加窗口高度以容纳点击历史
    minimumSize: Size(520, 680),   // 固定窗口大小，避免调整导致布局问题
    maximumSize: Size(520, 680),   // 固定窗口大小
    center: true,                  // 居中显示
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: '鼠标自动控制器',
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '鼠标自动控制器',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MouseControlPage(),
    );
  }
}

class MouseControlPage extends StatefulWidget {
  const MouseControlPage({super.key});

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
  String _currentPosition = '未获取';
  Timer? _uiUpdateTimer;
  bool _autoCapture = true; // 默认开启自动获取

  @override
  void initState() {
    super.initState();
    try {
      final bindings = MouseControllerBindings();
      _service = MouseControllerService(bindings);
      
      // 设置捕获位置回调
      _service.onPositionCaptured = (x, y) {
        if (mounted) {
          setState(() {
            _xController.text = x.toString();
            _yController.text = y.toString();
          });
          // 显示提示
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('已捕获位置: ($x, $y)'),
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
      
      // 延迟显示快捷键状态提示
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _checkHotkeyStatus();
        }
      });
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showError('初始化失败: $e\n\n请查看控制台输出了解详细信息');
      });
    }
  }
  
  void _checkHotkeyStatus() {
    // 这里可以添加额外的状态检查
    print('界面已加载，快捷键系统状态已在控制台显示');
    print('提示: 如果快捷键不工作，请查看上方的初始化日志');
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
            
            // 如果开启自动捕获且未运行，更新坐标
            if (_autoCapture && !_isRunning) {
              _xController.text = pos.x.toString();
              _yController.text = pos.y.toString();
            }
          });
          
          // 实时同步参数到服务
          _syncParametersToService();
        } catch (e) {
          // 忽略错误
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
      // 忽略错误
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
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
            _showError('快捷键设置失败！\n可能原因：\n1. 该快捷键已被其他程序占用\n2. 需要管理员权限\n3. DLL加载失败');
          } else {
            setState(() {}); // 刷新显示
          }
        },
        onCaptureHotkeyChanged: (vkCode) {
          bool success = _service.setCaptureHotkey(vkCode);
          if (!success) {
            _showError('快捷键设置失败！\n可能原因：\n1. 该快捷键已被其他程序占用\n2. 需要管理员权限\n3. DLL加载失败');
          } else {
            setState(() {}); // 刷新显示
          }
        },
      ),
    );
  }

  void _captureCurrentPosition() {
    try {
      final pos = _service.getCurrentMousePosition();
      setState(() {
        _xController.text = pos.x.toString();
        _yController.text = pos.y.toString();
      });
    } catch (e) {
      _showError('捕获位置失败: $e');
    }
  }

  void _toggleAutoClick() {
    print('========================================');
    print('界面按钮点击 - 开始/停止');
    print('========================================');
    
    try {
      final x = int.tryParse(_xController.text);
      final y = int.tryParse(_yController.text);
      final interval = int.tryParse(_intervalController.text);
      final intervalRandom = int.tryParse(_intervalRandomController.text);
      final offset = int.tryParse(_offsetController.text);

      print('参数验证:');
      print('  X坐标: ${_xController.text} → ${x ?? "无效"}');
      print('  Y坐标: ${_yController.text} → ${y ?? "无效"}');
      print('  间隔: ${_intervalController.text} → ${interval ?? "无效"}ms');
      print('  随机: ${_intervalRandomController.text} → ${intervalRandom ?? "无效"}ms');
      print('  偏移: ${_offsetController.text} → ${offset ?? "无效"}px');

      if (x == null || y == null) {
        print('× 验证失败：坐标无效');
        _showError('请输入有效的目标坐标\n\n提示：\n1. 点击"捕获"按钮获取当前鼠标位置\n2. 或手动输入X和Y坐标');
        return;
      }

      if (interval == null || interval < 10) {
        print('× 验证失败：间隔无效');
        _showError('点击间隔必须≥10毫秒');
        return;
      }

      if (intervalRandom == null || intervalRandom < 0) {
        print('× 验证失败：随机范围无效');
        _showError('间隔随机范围必须≥0');
        return;
      }

      if (offset == null || offset < 0) {
        print('× 验证失败：偏移无效');
        _showError('位置偏移必须≥0');
        return;
      }

      print('✓ 参数验证通过');
      print('设置参数到服务...');
      
      _service.setTargetPosition(x, y);
      _service.setClickInterval(interval);
      _service.setRandomInterval(intervalRandom);
      _service.setRandomOffset(offset);
      _service.setMouseButton(_selectedButton);

      print('触发切换操作...');
      _service.toggleAutoClick();
      
      print('========================================');
    } catch (e) {
      print('× 异常: $e');
      _showError('操作失败: $e');
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
          // 点击输入框自动切换到手动模式
          if (_autoCapture) {
            setState(() {
              _autoCapture = false;
            });
            print('切换到手动输入模式');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('鼠标自动控制器', style: TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard, size: 20),
            onPressed: _showHotkeySettings,
            tooltip: '快捷键设置',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 当前位置和状态卡片
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    // 第一行：位置和计数
                    Row(
                      children: [
                        const Icon(Icons.mouse, size: 18, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('当前位置: $_currentPosition', 
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
                                '${_service.clickCount}次',
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
                    // 第二行：当前快捷键
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // 开始/停止快捷键
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
                                '开始/停止: ',
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
                        // 捕获位置快捷键
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
                                '捕获: ',
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

            // 目标位置设置
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('目标位置', 
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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
                                _autoCapture ? '自动' : '手动',
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
                            print('切换模式: ${_autoCapture ? "自动跟随" : "手动输入"}');
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
                        Expanded(child: _buildCompactField('X坐标', _xController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField('Y坐标', _yController, width: double.infinity)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // 点击设置
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('点击设置', 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _buildCompactField('间隔(ms)', _intervalController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField('随机±(ms)', _intervalRandomController, width: double.infinity)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildCompactField('偏移(px)', _offsetController, width: double.infinity)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('鼠标按钮', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<MouseButton>(
                        segments: const [
                          ButtonSegment(
                            value: MouseButton.left, 
                            label: Text('左键', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.mouse, size: 16),
                          ),
                          ButtonSegment(
                            value: MouseButton.right, 
                            label: Text('右键', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.mouse, size: 16),
                          ),
                          ButtonSegment(
                            value: MouseButton.middle, 
                            label: Text('中键', style: TextStyle(fontSize: 12)),
                            icon: Icon(Icons.mouse, size: 16),
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

            // 控制按钮
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _toggleAutoClick,
                icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow, size: 20),
                label: Text(
                  _isRunning ? '停止点击' : '开始点击',
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

            // 点击历史
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
                            '点击历史（最近10次）',
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
                                    '暂无点击记录',
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
                                      // 序号
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
                                      // 时间
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
                                      // 位置
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
                                      // 按钮
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

// 快捷键设置对话框
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
  int _activeTab = 0; // 0=开始/停止, 1=捕获位置

  // 常用按键的虚拟键码映射
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
    return '未知';
  }

  @override
  Widget build(BuildContext context) {
    final currentKey = _activeTab == 0 ? _selectedToggleKey : _selectedCaptureKey;
    final keyName = _getKeyName(currentKey);
    final tabTitle = _activeTab == 0 ? '开始/停止' : '捕获位置';
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.keyboard, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Text('快捷键设置', style: TextStyle(fontSize: 16)),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 选项卡按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _activeTab = 0),
                    icon: Icon(Icons.play_arrow, size: 16),
                    label: const Text('开始/停止', style: TextStyle(fontSize: 12)),
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
                    icon: Icon(Icons.my_location, size: 16),
                    label: const Text('捕获位置', style: TextStyle(fontSize: 12)),
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
                      '设置[$tabTitle]快捷键 (Ctrl+Shift+按键)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择按键:',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                    '[$tabTitle] 快捷键预览',
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
          child: const Text('取消', style: TextStyle(fontSize: 13)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            // 根据当前选项卡调用不同的回调
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
                    Text('[$tabTitle]快捷键已设置为: Ctrl+Shift+$keyName'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          icon: const Icon(Icons.check, size: 16),
          label: const Text('保存', style: TextStyle(fontSize: 13)),
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
