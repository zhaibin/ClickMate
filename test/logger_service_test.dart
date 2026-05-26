import 'dart:io';

import 'package:clickmate/logger_service.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'path_provider_test_helper.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('clickmate_logger_test_');
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);
  });

  tearDown(() async {
    LoggerService.instance.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('initialize writes logs under ClickMate and migrates legacy log files',
      () async {
    final legacyLogDir = Directory('${tempDir.path}/MouseControl/logs');
    await legacyLogDir.create(recursive: true);
    await File('${legacyLogDir.path}/app_20260101.log').writeAsString('old');

    await LoggerService.instance.initialize();

    expect(
      await File('${tempDir.path}/ClickMate/logs/app_20260101.log')
          .readAsString(),
      'old',
    );
    expect(LoggerService.instance.logFilePath, contains('/ClickMate/logs/'));
    expect(await File(LoggerService.instance.logFilePath!).exists(), isTrue);
  });

  test('warning and error messages are written to the current log file',
      () async {
    await LoggerService.instance.initialize();

    LoggerService.instance.warning('test warning');
    LoggerService.instance.error('test error');

    final log = await File(LoggerService.instance.logFilePath!).readAsString();
    expect(log, contains('test warning'));
    expect(log, contains('test error'));
  });
}
