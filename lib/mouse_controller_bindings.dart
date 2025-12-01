import 'dart:ffi';
import 'dart:io';

// Mouse button enum
enum MouseButton {
  left(0),
  right(1),
  middle(2);

  final int value;
  const MouseButton(this.value);
}

// C function type definitions
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
    // Load dynamic library based on platform
    if (Platform.isWindows) {
      _dylib = DynamicLibrary.open('mouse_controller.dll');
    } else if (Platform.isMacOS) {
      // Try multiple paths for macOS dylib
      final home = Platform.environment['HOME'] ?? '/Users/${Platform.environment['USER']}';
      final executablePath = Platform.resolvedExecutable;
      final executableDir = executablePath.substring(0, executablePath.lastIndexOf('/'));
      
      final possiblePaths = [
        // For packaged app: check Frameworks directory inside .app bundle
        '$executableDir/../Frameworks/libmouse_controller.dylib',
        // For development: check project root
        'libmouse_controller.dylib',
        'build/macos/Build/Products/Debug/libmouse_controller.dylib',
        'build/macos/Build/Products/Release/libmouse_controller.dylib',
        '${Directory.current.path}/libmouse_controller.dylib',
        // Fallback paths
        '$home/Library/Containers/com.xants.clickmate/Data/libmouse_controller.dylib',
        '/usr/local/lib/libmouse_controller.dylib',
        '$executableDir/libmouse_controller.dylib',
      ];
      
      DynamicLibrary? lib;
      for (final path in possiblePaths) {
        try {
          lib = DynamicLibrary.open(path);
          print('Loaded native library from: $path');
          break;
        } catch (e) {
          // Try next path
        }
      }
      
      if (lib == null) {
        throw UnsupportedError(
          'Could not load libmouse_controller.dylib. '
          'Please ensure the library is compiled and available in one of these locations:\n'
          '${possiblePaths.join("\n")}'
        );
      }
      _dylib = lib;
    } else {
      throw UnsupportedError('Platform ${Platform.operatingSystem} is not supported');
    }

    // Bind functions
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
