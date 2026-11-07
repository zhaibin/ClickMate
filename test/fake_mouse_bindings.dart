import 'dart:ffi';

import 'package:clickmate/mouse_controller_bindings.dart';

/// In-memory mouse/hotkey backend used to simulate a real Windows/macOS device
/// without loading the native DLL/dylib.
class FakeMouseBindings {
  int x = 10;
  int y = 20;
  int clickCount = 0;
  int moveCount = 0;
  final List<int> registeredIds = [];
  final List<int> unregisteredIds = [];
  final List<int> clickedButtons = [];
  final Map<int, int> hotkeyPresses = {};
  bool initHotkeyResult = true;
  bool registerHotkeyResult = true;
  bool throwOnClick = false;

  MouseControllerBindings asBindings() {
    return MouseControllerBindings.testing(
      moveMouse: (newX, newY) {
        moveCount++;
        x = newX;
        y = newY;
      },
      clickMouse: (button) {
        if (throwOnClick) {
          throw StateError('click failed');
        }
        clickCount++;
        clickedButtons.add(button);
      },
      getMousePosition: (Pointer<Int32> xPtr, Pointer<Int32> yPtr) {
        xPtr.value = x;
        yPtr.value = y;
      },
      registerHotkey: (id, vkCode, modifiers) {
        registeredIds.add(id);
        return registerHotkeyResult;
      },
      unregisterHotkey: (id) {
        unregisteredIds.add(id);
      },
      checkHotkeyPressed: (id) {
        final remaining = hotkeyPresses[id] ?? 0;
        if (remaining <= 0) {
          return false;
        }
        hotkeyPresses[id] = remaining - 1;
        return true;
      },
      initHotkeySystem: () => initHotkeyResult,
      cleanupHotkeySystem: () {},
    );
  }
}
