import 'package:clickmate/click_config.dart';
import 'package:clickmate/l10n/app_localizations.dart';
import 'package:clickmate/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget buildPage({ValueChanged<Locale>? onLanguageChanged}) {
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
        onLanguageChanged: onLanguageChanged ?? (_) {},
      ),
    );
  }

  Future<void> openMenuAndTap(WidgetTester tester, String itemText) async {
    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemText).last);
    await tester.pump(const Duration(milliseconds: 300));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ClickConfigService.instance.initialize();
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.clearAllTestValues();
  });

  testWidgets('help menu opens platform help content', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump(const Duration(milliseconds: 500));

    await openMenuAndTap(tester, 'Help');

    expect(find.byIcon(Icons.help_outline), findsWidgets);
    expect(find.text('Quick Start'), findsOneWidget);
    expect(find.text('FAQ'), findsOneWidget);
  });

  testWidgets('about menu opens app and library information', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump(const Duration(milliseconds: 500));

    await openMenuAndTap(tester, 'About');

    expect(find.text('ClickMate'), findsWidgets);
    expect(find.text('clickmate.xants.net'), findsOneWidget);
    expect(find.byIcon(Icons.code), findsOneWidget);
  });

  testWidgets('language menu reports selected language', (tester) async {
    Locale? selectedLocale;
    await tester.pumpWidget(buildPage(onLanguageChanged: (value) {
      selectedLocale = value;
    }));
    await tester.pump(const Duration(milliseconds: 500));

    await openMenuAndTap(tester, 'Language');
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(selectedLocale, const Locale('en', ''));
  });

  testWidgets('hotkey menu opens settings from the main page', (tester) async {
    await tester.pumpWidget(buildPage());
    await tester.pump(const Duration(milliseconds: 500));

    await openMenuAndTap(tester, 'Hotkey Settings');

    expect(find.byType(HotkeySettingsDialog), findsOneWidget);
    expect(find.text('Start/Stop'), findsWidgets);
    expect(find.text('Capture Position'), findsWidgets);
  });
}
