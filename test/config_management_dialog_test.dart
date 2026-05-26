import 'package:clickmate/click_config.dart';
import 'package:clickmate/config_management_dialog.dart';
import 'package:clickmate/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ClickConfigService service;

  ClickConfig config({
    String id = 'config-1',
    String name = 'Morning Run',
    int mouseButton = 0,
    int randomInterval = 10,
    int offset = 5,
  }) {
    final now = DateTime.utc(2026, 5, 26, 9, 30);
    return ClickConfig(
      id: id,
      name: name,
      x: 320,
      y: 640,
      interval: 750,
      randomInterval: randomInterval,
      offset: offset,
      mouseButton: mouseButton,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildDialog({
    required ValueChanged<ClickConfig> onLoaded,
    String? currentConfigId,
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
        body: ConfigManagementDialog(
          currentConfigId: currentConfigId,
          onConfigLoaded: onLoaded,
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ClickConfigService.instance;
    await service.initialize();
  });

  testWidgets('shows an empty state when there are no saved configs',
      (tester) async {
    await tester.pumpWidget(buildDialog(onLoaded: (_) {}));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('renders saved configs with badges and selected state',
      (tester) async {
    await service.addConfig(config());
    await service.addConfig(
      config(
        id: 'config-2',
        name: 'Right Button',
        mouseButton: 1,
        randomInterval: 0,
        offset: 0,
      ),
    );

    await tester.pumpWidget(
      buildDialog(onLoaded: (_) {}, currentConfigId: 'config-1'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('Right Button'), findsOneWidget);
    expect(find.text('(320, 640)'), findsNWidgets(2));
    expect(find.text('750ms'), findsNWidgets(2));
    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('tapping a config loads it and dismisses the dialog',
      (tester) async {
    final saved = config();
    ClickConfig? loaded;
    await service.addConfig(saved);

    await tester.pumpWidget(buildDialog(onLoaded: (value) => loaded = value));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Run'));
    await tester.pumpAndSettle();

    expect(loaded?.id, saved.id);
    expect(service.getLastUsedConfigId(), saved.id);
    expect(find.byType(ConfigManagementDialog), findsNothing);
  });

  testWidgets('rename action updates the saved config name', (tester) async {
    await service.addConfig(config());

    await tester.pumpWidget(buildDialog(onLoaded: (_) {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed Config');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
    await tester.pumpAndSettle();

    expect(service.getConfigById('config-1')?.name, 'Renamed Config');
    expect(find.text('Renamed Config'), findsOneWidget);
    expect(find.text('Morning Run'), findsNothing);
  });

  testWidgets('delete action removes a config after confirmation',
      (tester) async {
    await service.addConfig(config());

    await tester.pumpWidget(buildDialog(onLoaded: (_) {}));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(service.getConfigById('config-1'), isNull);
    expect(find.text('Morning Run'), findsNothing);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });
}
