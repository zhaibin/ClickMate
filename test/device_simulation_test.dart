import 'package:clickmate/click_config.dart';
import 'package:clickmate/l10n/app_localizations.dart';
import 'package:clickmate/main.dart';
import 'package:clickmate/mouse_controller_bindings.dart';
import 'package:clickmate/mouse_controller_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_mouse_bindings.dart';

/// End-to-end device simulation coverage for Linux CI / cloud agents.
///
/// Native mouse libraries only exist on Windows and macOS. These tests inject
/// [FakeMouseBindings] so the full UI + service pipeline can still be exercised
/// as if a real machine delivered mouse moves, clicks, and hotkeys.
void main() {
  late FakeMouseBindings fake;

  Widget buildSimulatedDevice({FakeMouseBindings? bindings}) {
    return MaterialApp(
      locale: const Locale('en', ''),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: MouseControlPage(
        onLanguageChanged: (_) {},
        bindings: (bindings ?? fake).asBindings(),
        hotkeyArmDelay: Duration.zero,
      ),
    );
  }

  Future<void> pumpDevice(
    WidgetTester tester, {
    FakeMouseBindings? bindings,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildSimulatedDevice(bindings: bindings));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> seedManualSession({
    required int x,
    required int y,
    int interval = 10000,
    int mouseButton = 0,
  }) async {
    await ClickConfigService.instance.saveSessionSettings(
      SessionSettings(
        x: x,
        y: y,
        interval: interval,
        randomInterval: 0,
        offset: 0,
        mouseButton: mouseButton,
        deviationThreshold: 100,
        autoCapture: false,
        enableAutoPauseResume: false,
        toggleHotkeyCode: 0x31,
        captureHotkeyCode: 0x32,
        hotkeyModifiers: HotkeyModifiers.controlShift,
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ClickConfigService.instance.initialize();
    fake = FakeMouseBindings();
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('simulated device boots into the main control UI', (tester) async {
    await pumpDevice(tester);

    expect(find.byTooltip('Menu'), findsOneWidget);
    expect(find.text('Start Clicking'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(
      fake.registeredIds,
      containsAll([
        MouseControllerService.hotkeyIdToggle,
        MouseControllerService.hotkeyIdCapture,
      ]),
    );
  });

  testWidgets('capture hotkey fills coordinates like a real F-key press',
      (tester) async {
    fake.x = 321;
    fake.y = 654;
    fake.hotkeyPresses[MouseControllerService.hotkeyIdCapture] = 1;

    await pumpDevice(tester);
    // Hotkey poll interval is 100ms.
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('321'), findsWidgets);
    expect(find.text('654'), findsWidgets);
  });

  testWidgets('toggle hotkey starts and stops auto-click on the fake device',
      (tester) async {
    await seedManualSession(x: 120, y: 240);
    fake = FakeMouseBindings();
    fake.hotkeyPresses[MouseControllerService.hotkeyIdToggle] = 1;

    await pumpDevice(tester);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Stop Clicking'), findsOneWidget);
    expect(fake.clickCount, greaterThanOrEqualTo(1));
    expect(fake.x, 120);
    expect(fake.y, 240);

    fake.hotkeyPresses[MouseControllerService.hotkeyIdToggle] = 1;
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Start Clicking'), findsOneWidget);
  });

  testWidgets('Start Clicking button drives the simulated mouse', (tester) async {
    await seedManualSession(x: 55, y: 66, mouseButton: MouseButton.middle.value);
    fake = FakeMouseBindings();

    await pumpDevice(tester);

    await tester.tap(find.text('Start Clicking'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Stop Clicking'), findsOneWidget);
    expect(fake.moveCount, greaterThanOrEqualTo(1));
    expect(fake.clickCount, greaterThanOrEqualTo(1));
    expect(fake.clickedButtons, contains(MouseButton.middle.value));
    expect(fake.x, 55);
    expect(fake.y, 66);

    await tester.tap(find.text('Stop Clicking'));
    await tester.pump(const Duration(milliseconds: 250));
    final clicksAfterStop = fake.clickCount;
    await tester.pump(const Duration(milliseconds: 300));
    expect(fake.clickCount, clicksAfterStop);
    expect(find.text('Start Clicking'), findsOneWidget);
  });

  testWidgets('session settings survive a simulated app restart', (tester) async {
    final firstFake = FakeMouseBindings();
    await pumpDevice(tester, bindings: firstFake);

    await tester.tap(find.text('Auto'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Manual'), findsOneWidget);

    final textFields = find.byType(TextField);
    expect(textFields, findsWidgets);

    await tester.enterText(textFields.at(0), '111');
    await tester.enterText(textFields.at(1), '222');
    await tester.enterText(textFields.at(2), '1500');
    await tester.pump(const Duration(milliseconds: 600));

    final restored = ClickConfigService.instance.loadSessionSettings();
    expect(restored, isNotNull);
    expect(restored!.x, 111);
    expect(restored.y, 222);
    expect(restored.interval, 1500);
    expect(restored.autoCapture, isFalse);

    // Simulate restart with a fresh fake device using the same prefs.
    final secondFake = FakeMouseBindings();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await pumpDevice(tester, bindings: secondFake);

    expect(find.text('111'), findsWidgets);
    expect(find.text('222'), findsWidgets);
    expect(find.text('1500'), findsWidgets);
    expect(find.text('Manual'), findsOneWidget);
  });

  test(
    'service-level simulation: none+F9 toggle starts clicks without modifiers',
    () async {
      final device = FakeMouseBindings();
      final service = MouseControllerService(
        device.asBindings(),
        hotkeyArmDelay: Duration.zero,
        toggleHotkeyCode: 0x78, // F9
        captureHotkeyCode: 0x79, // F10
        hotkeyModifiers: HotkeyModifiers.none,
      )
        ..setEnableAutoPauseResume(false)
        ..setTargetPosition(90, 91)
        ..setClickInterval(10000);

      device.hotkeyPresses[MouseControllerService.hotkeyIdToggle] = 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(service.isRunning, isTrue);
      expect(device.clickCount, greaterThanOrEqualTo(1));
      expect(device.x, 90);
      expect(device.y, 91);

      service.dispose();
    },
  );
}
