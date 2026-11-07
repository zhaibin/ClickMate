import 'package:clickmate/click_config.dart';
import 'package:clickmate/l10n/app_localizations.dart';
import 'package:clickmate/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDialog({
    required void Function(int, HotkeyModifiers) onToggleChanged,
    required void Function(int, HotkeyModifiers) onCaptureChanged,
    int toggleCode = 0x31,
    int captureCode = 0x32,
    HotkeyModifiers modifiers = HotkeyModifiers.controlShift,
  }) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HotkeySettingsDialog(
          currentToggleHotkeyCode: toggleCode,
          currentCaptureHotkeyCode: captureCode,
          currentModifiers: modifiers,
          onToggleHotkeyChanged: onToggleChanged,
          onCaptureHotkeyChanged: onCaptureChanged,
        ),
      ),
    );
  }

  testWidgets('saving on the start/stop tab reports the selected key',
      (tester) async {
    int? toggleCode;
    int? captureCode;
    HotkeyModifiers? toggleMods;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (value, mods) {
          toggleCode = value;
          toggleMods = mods;
        },
        onCaptureChanged: (value, mods) => captureCode = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(toggleCode, 0x41);
    expect(toggleMods, HotkeyModifiers.controlShift);
    expect(captureCode, isNull);
    expect(find.byType(HotkeySettingsDialog), findsNothing);
  });

  testWidgets('capture tab saves capture hotkey without changing toggle',
      (tester) async {
    int? toggleCode;
    int? captureCode;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (value, mods) => toggleCode = value,
        onCaptureChanged: (value, mods) => captureCode = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.my_location));
    await tester.pump();
    await tester.tap(find.text('B'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(toggleCode, isNull);
    expect(captureCode, 0x42);
  });

  testWidgets('none modifier allows single-key preview like F9', (tester) async {
    int? toggleCode;
    HotkeyModifiers? mods;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (value, m) {
          toggleCode = value;
          mods = m;
        },
        onCaptureChanged: (_, __) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('None'));
    await tester.pump();
    // Digit defaults are coerced to F9/F10; saving keeps the coerced toggle key.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(toggleCode, HotkeyKeyPolicy.defaultNoneToggle);
    expect(mods, HotkeyModifiers.none);
  });

  testWidgets('none modifier hides letters and digits', (tester) async {
    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (_, __) {},
        onCaptureChanged: (_, __) {},
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.text('None'));
    await tester.pump();

    expect(find.text('A'), findsNothing);
    expect(find.text('2'), findsNothing);
    expect(find.text('F9'), findsWidgets);
    expect(find.text('F12'), findsOneWidget);
  });

  testWidgets('switching to none coerces digit keys before save',
      (tester) async {
    int? toggleCode;
    HotkeyModifiers? mods;

    await tester.pumpWidget(
      buildDialog(
        toggleCode: 0x31,
        captureCode: 0x32,
        onToggleChanged: (value, m) {
          toggleCode = value;
          mods = m;
        },
        onCaptureChanged: (_, __) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('None'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(mods, HotkeyModifiers.none);
    expect(toggleCode, HotkeyKeyPolicy.defaultNoneToggle);
  });

  testWidgets('cancel closes without invoking callbacks', (tester) async {
    var called = false;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (_, __) => called = true,
        onCaptureChanged: (_, __) => called = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.byType(HotkeySettingsDialog), findsNothing);
  });
}
