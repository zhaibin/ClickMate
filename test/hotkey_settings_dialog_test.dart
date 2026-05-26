import 'package:clickmate/l10n/app_localizations.dart';
import 'package:clickmate/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDialog({
    required ValueChanged<int> onToggleChanged,
    required ValueChanged<int> onCaptureChanged,
    int toggleCode = 0x31,
    int captureCode = 0x32,
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

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (value) => toggleCode = value,
        onCaptureChanged: (value) => captureCode = value,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('A'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(toggleCode, 0x41);
    expect(captureCode, isNull);
    expect(find.byType(HotkeySettingsDialog), findsNothing);
  });

  testWidgets('capture tab saves capture hotkey without changing toggle',
      (tester) async {
    int? toggleCode;
    int? captureCode;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (value) => toggleCode = value,
        onCaptureChanged: (value) => captureCode = value,
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

  testWidgets('cancel closes without invoking callbacks', (tester) async {
    var called = false;

    await tester.pumpWidget(
      buildDialog(
        onToggleChanged: (_) => called = true,
        onCaptureChanged: (_) => called = true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(called, isFalse);
    expect(find.byType(HotkeySettingsDialog), findsNothing);
  });
}
