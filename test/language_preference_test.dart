import 'dart:io';

import 'package:clickmate/language_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'path_provider_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('clickmate_language_test_');
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('initialize migrates a valid legacy language over invalid new content',
      () async {
    await Directory('${tempDir.path}/MouseControl').create(recursive: true);
    await Directory('${tempDir.path}/ClickMate').create(recursive: true);
    await File('${tempDir.path}/MouseControl/language.txt')
        .writeAsString('zh_CN');
    await File('${tempDir.path}/ClickMate/language.txt').writeAsString('\u0000');

    await LanguagePreference.instance.initialize();

    expect(LanguagePreference.instance.currentLocale, const Locale('zh', 'CN'));
    expect(
      await File('${tempDir.path}/ClickMate/language.txt').readAsString(),
      'zh_CN',
    );
  });

  test('initialize ignores unsupported legacy language and saves fallback',
      () async {
    await Directory('${tempDir.path}/MouseControl').create(recursive: true);
    await File('${tempDir.path}/MouseControl/language.txt')
        .writeAsString('xx_YY');

    await LanguagePreference.instance.initialize();

    final saved = await File('${tempDir.path}/ClickMate/language.txt')
        .readAsString();

    expect(saved, isNot('xx_YY'));
    expect(saved, isNotEmpty);
  });

  test('changeLanguage persists the selected locale', () async {
    await LanguagePreference.instance.initialize();

    await LanguagePreference.instance.changeLanguage(const Locale('ja', ''));

    expect(
      await File('${tempDir.path}/ClickMate/language.txt').readAsString(),
      'ja',
    );
  });
}
