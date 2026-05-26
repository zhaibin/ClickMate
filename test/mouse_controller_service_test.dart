import 'dart:ffi';

import 'package:clickmate/mouse_controller_bindings.dart';
import 'package:clickmate/mouse_controller_service.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';

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
      registerHotkey: (id, vkCode) {
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

void main() {
  test('ClickRecord formats time and mouse button names', () {
    final time = DateTime(2026, 5, 26, 7, 8, 9, 12);

    expect(
      ClickRecord(time, MousePosition(1, 2), MouseButton.left).timeString,
      '07:08:09.012',
    );
    expect(
      ClickRecord(time, MousePosition(1, 2), MouseButton.left).buttonString,
      'L',
    );
    expect(
      ClickRecord(time, MousePosition(1, 2), MouseButton.right).buttonString,
      'R',
    );
    expect(
      ClickRecord(time, MousePosition(1, 2), MouseButton.middle).buttonString,
      'M',
    );
  });

  test('constructor initializes and registers both default hotkeys', () {
    final fake = FakeMouseBindings();
    final service = MouseControllerService(
      fake.asBindings(),
      hotkeyArmDelay: Duration.zero,
    );

    expect(fake.registeredIds, [
      MouseControllerService.hotkeyIdToggle,
      MouseControllerService.hotkeyIdCapture,
    ]);

    service.dispose();
  });

  test('setToggleHotkey and setCaptureHotkey replace registrations', () {
    final fake = FakeMouseBindings();
    final service = MouseControllerService(
      fake.asBindings(),
      hotkeyArmDelay: Duration.zero,
    );

    expect(service.setToggleHotkey(0x41), isTrue);
    expect(service.currentToggleHotkeyCode, 0x41);
    expect(service.setCaptureHotkey(0x42), isTrue);
    expect(service.currentCaptureHotkeyCode, 0x42);
    expect(
      fake.unregisteredIds,
      containsAll([
        MouseControllerService.hotkeyIdToggle,
        MouseControllerService.hotkeyIdCapture,
      ]),
    );

    service.dispose();
  });

  test('getCurrentMousePosition reads coordinates from bindings', () {
    final fake = FakeMouseBindings()
      ..x = 123
      ..y = 456;
    final service = MouseControllerService(fake.asBindings());

    final position = service.getCurrentMousePosition();

    expect(position.x, 123);
    expect(position.y, 456);
    expect(position.toString(), 'MousePosition(x: 123, y: 456)');

    service.dispose();
  });

  test('startAutoClick does nothing without a target position', () {
    final fake = FakeMouseBindings();
    final service = MouseControllerService(
      fake.asBindings(),
      hotkeyArmDelay: Duration.zero,
    );

    service.startAutoClick();

    expect(service.isRunning, isFalse);
    expect(fake.clickCount, 0);

    service.dispose();
  });

  test(
    'startAutoClick moves, clicks, and records history without auto-pause',
    () async {
      final fake = FakeMouseBindings();
      final service =
          MouseControllerService(
              fake.asBindings(),
              hotkeyArmDelay: Duration.zero,
            )
            ..setEnableAutoPauseResume(false)
            ..setTargetPosition(50, 60)
            ..setClickInterval(10000)
            ..setRandomOffset(0)
            ..setRandomInterval(0)
            ..setMouseButton(MouseButton.middle);

      service.startAutoClick();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(service.isRunning, isTrue);
      expect(fake.moveCount, 1);
      expect(fake.x, 50);
      expect(fake.y, 60);
      expect(fake.clickedButtons, [MouseButton.middle.value]);
      expect(service.clickCount, 1);
      expect(service.clickHistory, hasLength(1));
      expect(service.clickHistory.first.position.x, 50);

      service.dispose();
    },
  );

  test('stopAutoClick prevents scheduled follow-up clicks', () async {
    final fake = FakeMouseBindings();
    final service =
        MouseControllerService(fake.asBindings(), hotkeyArmDelay: Duration.zero)
          ..setEnableAutoPauseResume(false)
          ..setTargetPosition(40, 50)
          ..setClickInterval(60);

    service.startAutoClick();
    await Future<void>.delayed(const Duration(milliseconds: 70));
    service.stopAutoClick();
    final countAfterStop = service.clickCount;
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(countAfterStop, greaterThanOrEqualTo(1));
    expect(service.clickCount, countAfterStop);
    expect(service.isRunning, isFalse);

    service.dispose();
  });

  test(
    'random offset keeps click coordinates inside configured bounds',
    () async {
      final fake = FakeMouseBindings();
      final service =
          MouseControllerService(
              fake.asBindings(),
              hotkeyArmDelay: Duration.zero,
            )
            ..setEnableAutoPauseResume(false)
            ..setTargetPosition(100, 200)
            ..setRandomOffset(5)
            ..setClickInterval(10000);

      service.startAutoClick();
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(service.clickHistory, hasLength(1));
      final position = service.clickHistory.first.position;
      expect(position.x, inInclusiveRange(95, 105));
      expect(position.y, inInclusiveRange(195, 205));

      service.dispose();
    },
  );

  test('click history keeps only the most recent records', () async {
    final fake = FakeMouseBindings();
    final service =
        MouseControllerService(fake.asBindings(), hotkeyArmDelay: Duration.zero)
          ..setEnableAutoPauseResume(false)
          ..setTargetPosition(10, 20)
          ..setClickInterval(10);

    service.startAutoClick();
    await Future<void>.delayed(const Duration(milliseconds: 260));

    expect(
      service.clickCount,
      greaterThan(MouseControllerService.maxHistorySize),
    );
    expect(
      service.clickHistory,
      hasLength(MouseControllerService.maxHistorySize),
    );

    service.dispose();
  });

  test('toggleAutoClick awaits onBeforeStart before starting', () async {
    final fake = FakeMouseBindings();
    final service =
        MouseControllerService(fake.asBindings(), hotkeyArmDelay: Duration.zero)
          ..setEnableAutoPauseResume(false)
          ..setTargetPosition(10, 20);
    var beforeStartCalled = false;
    service.onBeforeStart = () async {
      beforeStartCalled = true;
    };

    service.toggleAutoClick();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(beforeStartCalled, isTrue);
    expect(service.isRunning, isTrue);

    service.dispose();
  });

  test('capture hotkey captures current position and updates target', () async {
    final fake = FakeMouseBindings()
      ..x = 77
      ..y = 88;
    fake.hotkeyPresses[MouseControllerService.hotkeyIdCapture] = 1;
    final service = MouseControllerService(
      fake.asBindings(),
      hotkeyArmDelay: Duration.zero,
    );
    MousePosition? captured;
    service.onPositionCaptured = (x, y) => captured = MousePosition(x, y);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(captured?.x, 77);
    expect(captured?.y, 88);
    expect(service.targetPosition?.x, 77);
    expect(service.targetPosition?.y, 88);

    service.dispose();
  });

  test('failed click stops auto click', () async {
    final fake = FakeMouseBindings()..throwOnClick = true;
    final service =
        MouseControllerService(fake.asBindings(), hotkeyArmDelay: Duration.zero)
          ..setEnableAutoPauseResume(false)
          ..setTargetPosition(10, 20);

    service.startAutoClick();
    await Future<void>.delayed(const Duration(milliseconds: 80));

    expect(service.isRunning, isFalse);

    service.dispose();
  });

  test('startup arm delay drains hotkeys without triggering actions', () async {
    final fake = FakeMouseBindings()
      ..x = 77
      ..y = 88;
    fake.hotkeyPresses[MouseControllerService.hotkeyIdToggle] = 1;
    fake.hotkeyPresses[MouseControllerService.hotkeyIdCapture] = 1;
    final service = MouseControllerService(
      fake.asBindings(),
      hotkeyArmDelay: const Duration(milliseconds: 300),
    );
    MousePosition? captured;
    service.onPositionCaptured = (x, y) => captured = MousePosition(x, y);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    expect(service.isRunning, isFalse);
    expect(captured, isNull);
    expect(service.targetPosition, isNull);

    service.dispose();
  });
}
