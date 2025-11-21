import 'dart:ffi';
import 'dart:io';

// 鼠标按钮枚举
enum MouseButton {
  left(0),
  right(1),
  middle(2);

  final int value;
  const MouseButton(this.value);
}

// C函数类型定义
typedef MoveMouseNative = Void Function(Int32 x, Int32 y);
typedef MoveMouse = void Function(int x, int y);

typedef ClickMouseNative = Void Function(Int32 button);
typedef ClickMouse = void Function(int button);

typedef GetMousePositionNative = Void Function(Pointer<Int32> x, Pointer<Int32> y);
typedef GetMousePosition = void Function(Pointer<Int32> x, Pointer<Int32> y);

typedef RegisterHotkeyNative = Bool Function(Int32 id, Uint32 vkCode);
typedef RegisterHotkey = bool Function(int id, int vkCode);

typedef UnregisterHotkeyNative = Void Function(Int32 id);
typedef UnregisterHotkey = void Function(int id);

typedef CheckHotkeyPressedNative = Bool Function(Int32 id);
typedef CheckHotkeyPressed = bool Function(int id);

typedef InitHotkeySystemNative = Bool Function();
typedef InitHotkeySystem = bool Function();

typedef CleanupHotkeySystemNative = Void Function();
typedef CleanupHotkeySystem = void Function();

class MouseControllerBindings {
  late final DynamicLibrary _dylib;
  late final MoveMouse moveMouse;
  late final ClickMouse clickMouse;
  late final GetMousePosition getMousePosition;
  late final RegisterHotkey registerHotkey;
  late final UnregisterHotkey unregisterHotkey;
  late final CheckHotkeyPressed checkHotkeyPressed;
  late final InitHotkeySystem initHotkeySystem;
  late final CleanupHotkeySystem cleanupHotkeySystem;

  MouseControllerBindings() {
    // 加载动态库
    if (Platform.isWindows) {
      _dylib = DynamicLibrary.open('mouse_controller.dll');
    } else {
      throw UnsupportedError('This platform is not supported');
    }

    // 绑定函数
    moveMouse = _dylib
        .lookup<NativeFunction<MoveMouseNative>>('moveMouse')
        .asFunction<MoveMouse>();

    clickMouse = _dylib
        .lookup<NativeFunction<ClickMouseNative>>('clickMouse')
        .asFunction<ClickMouse>();

    getMousePosition = _dylib
        .lookup<NativeFunction<GetMousePositionNative>>('getMousePosition')
        .asFunction<GetMousePosition>();

    registerHotkey = _dylib
        .lookup<NativeFunction<RegisterHotkeyNative>>('registerHotkey')
        .asFunction<RegisterHotkey>();

    unregisterHotkey = _dylib
        .lookup<NativeFunction<UnregisterHotkeyNative>>('unregisterHotkey')
        .asFunction<UnregisterHotkey>();

    checkHotkeyPressed = _dylib
        .lookup<NativeFunction<CheckHotkeyPressedNative>>('checkHotkeyPressed')
        .asFunction<CheckHotkeyPressed>();

    initHotkeySystem = _dylib
        .lookup<NativeFunction<InitHotkeySystemNative>>('initHotkeySystem')
        .asFunction<InitHotkeySystem>();

    cleanupHotkeySystem = _dylib
        .lookup<NativeFunction<CleanupHotkeySystemNative>>('cleanupHotkeySystem')
        .asFunction<CleanupHotkeySystem>();
  }

  void dispose() {
    cleanupHotkeySystem();
  }
}
