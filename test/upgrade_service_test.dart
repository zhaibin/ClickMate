import 'package:clickmate/upgrade_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatFileSize chooses bytes, KB, and MB units', () {
    final service = UpgradeService.instance;

    expect(service.formatFileSize(42), '42 B');
    expect(service.formatFileSize(1536), '1.5 KB');
    expect(service.formatFileSize(3 * 1024 * 1024), '3.0 MB');
  });

  test('debugCompareVersions compares semantic version segments', () {
    final service = UpgradeService.instance;

    expect(service.debugCompareVersions('2.2.2', '2.2.1'), greaterThan(0));
    expect(service.debugCompareVersions('2.1.9', '2.2.0'), lessThan(0));
    expect(service.debugCompareVersions('2.2', '2.2.0'), 0);
  });

  test('debugParseGitHubRelease selects a platform asset and update state', () {
    final service = UpgradeService.instance;

    final info = service.debugParseGitHubRelease({
      'tag_name': 'v99.0.0',
      'body': 'Release notes',
      'assets': [
        {
          'name': 'ClickMate_v99.0.0_Setup.exe',
          'browser_download_url': 'https://example.com/clickmate.exe',
          'size': 2048,
        },
        {
          'name': 'ClickMate_v99.0.0.dmg',
          'browser_download_url': 'https://example.com/clickmate.dmg',
          'size': 4096,
        },
      ],
    });

    expect(info, isNotNull);
    expect(info!.latestVersion, '99.0.0');
    expect(info.releaseNotes, 'Release notes');
    expect(info.hasUpdate, isTrue);
    expect(info.downloadUrl, startsWith('https://example.com/clickmate.'));
    expect(info.fileName, anyOf(endsWith('.dmg'), endsWith('.exe')));
  });

  test('debugParseGitHubRelease returns null when no platform asset exists', () {
    final service = UpgradeService.instance;

    final info = service.debugParseGitHubRelease({
      'tag_name': 'v99.0.0',
      'assets': [
        {
          'name': 'ClickMate_v99.0.0.tar.gz',
          'browser_download_url': 'https://example.com/clickmate.tar.gz',
          'size': 1024,
        },
      ],
    });

    expect(info, isNull);
  });

  test('debugParseGitHubRelease marks older releases as not an update', () {
    final service = UpgradeService.instance;

    final info = service.debugParseGitHubRelease({
      'tag_name': 'v1.0.0',
      'assets': [
        {
          'name': 'ClickMate_v1.0.0_Setup.exe',
          'browser_download_url': 'https://example.com/clickmate.exe',
          'size': 2048,
        },
        {
          'name': 'ClickMate_v1.0.0.dmg',
          'browser_download_url': 'https://example.com/clickmate.dmg',
          'size': 4096,
        },
      ],
    });

    expect(info, isNotNull);
    expect(info!.hasUpdate, isFalse);
  });

  test('startUpgrade returns false before any file has been downloaded',
      () async {
    final service = UpgradeService.instance;
    service.resetDownloadState();

    expect(await service.startUpgrade(), isFalse);
    expect(service.downloadedFilePath, isNull);
    expect(service.downloadProgress, 0);
    expect(service.isDownloading, isFalse);
  });
}
