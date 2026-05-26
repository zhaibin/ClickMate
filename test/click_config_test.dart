import 'package:clickmate/click_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late ClickConfigService service;

  ClickConfig sampleConfig({
    String id = 'config-1',
    String name = 'Primary',
    int x = 120,
    int y = 240,
    int interval = 500,
    int randomInterval = 25,
    int offset = 6,
    int mouseButton = 0,
  }) {
    final createdAt = DateTime.utc(2026, 5, 25, 8, 30);
    final updatedAt = DateTime.utc(2026, 5, 25, 9, 45);

    return ClickConfig(
      id: id,
      name: name,
      x: x,
      y: y,
      interval: interval,
      randomInterval: randomInterval,
      offset: offset,
      mouseButton: mouseButton,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ClickConfigService.instance;
    await service.initialize();
  });

  test('ClickConfig round-trips through JSON without losing fields', () {
    final config = sampleConfig(mouseButton: 1);

    final restored = ClickConfig.fromJson(config.toJson());

    expect(restored.id, config.id);
    expect(restored.name, config.name);
    expect(restored.x, config.x);
    expect(restored.y, config.y);
    expect(restored.interval, config.interval);
    expect(restored.randomInterval, config.randomInterval);
    expect(restored.offset, config.offset);
    expect(restored.mouseButton, config.mouseButton);
    expect(restored.createdAt, config.createdAt);
    expect(restored.updatedAt, config.updatedAt);
  });

  test('copyWith changes only requested fields', () {
    final config = sampleConfig();
    final newUpdatedAt = DateTime.utc(2026, 5, 26);

    final copy = config.copyWith(name: 'Renamed', updatedAt: newUpdatedAt);

    expect(copy.id, config.id);
    expect(copy.name, 'Renamed');
    expect(copy.x, config.x);
    expect(copy.updatedAt, newUpdatedAt);
    expect(copy.createdAt, config.createdAt);
  });

  test('addConfig persists and loadConfigs restores saved configs', () async {
    final config = sampleConfig();

    await service.addConfig(config);
    expect(service.getConfigById('config-1'), isNotNull);

    await service.loadConfigs();

    expect(service.getAllConfigs(), hasLength(1));
    expect(service.getConfigById('config-1')?.name, 'Primary');
  });

  test('autoSaveConfig reuses an existing matching config', () async {
    final config = sampleConfig(name: 'Existing');
    await service.addConfig(config);

    final saved = await service.autoSaveConfig(
      x: config.x,
      y: config.y,
      interval: config.interval,
      randomInterval: config.randomInterval,
      offset: config.offset,
      mouseButton: config.mouseButton,
    );

    expect(saved.id, config.id);
    expect(service.getAllConfigs(), hasLength(1));
    expect(service.getLastUsedConfigId(), config.id);
  });

  test('deleteConfig removes matching config and clears last used id', () async {
    final config = sampleConfig();
    await service.addConfig(config);
    await service.setLastUsedConfig(config.id);

    await service.deleteConfig(config.id);

    expect(service.getAllConfigs(), isEmpty);
    expect(service.getLastUsedConfigId(), isNull);
    expect(service.getLastUsedConfig(), isNull);
  });

  test('renameConfig updates the config name and keeps it findable', () async {
    final config = sampleConfig();
    await service.addConfig(config);

    await service.renameConfig(config.id, 'Renamed');

    expect(service.getConfigById(config.id)?.name, 'Renamed');
    expect(service.getConfigById(config.id)?.x, config.x);
  });

  test('updateConfig ignores unknown ids', () async {
    await service.updateConfig(sampleConfig(id: 'missing'));

    expect(service.getAllConfigs(), isEmpty);
  });

  test('loadConfigs falls back to empty when stored JSON is invalid', () async {
    SharedPreferences.setMockInitialValues({
      'click_configs': 'not json',
    });
    await service.initialize();

    expect(service.getAllConfigs(), isEmpty);
  });

  test('getLastUsedConfig restores a persisted last used id', () async {
    final config = sampleConfig();
    await service.addConfig(config);
    await service.setLastUsedConfig(config.id);

    await service.initialize();

    expect(service.getLastUsedConfig()?.id, config.id);
  });

  test('findMatchingConfig returns null when settings differ', () async {
    await service.addConfig(sampleConfig());

    final match = service.findMatchingConfig(
      x: 999,
      y: 240,
      interval: 500,
      randomInterval: 25,
      offset: 6,
      mouseButton: 0,
    );

    expect(match, isNull);
  });

  test('generateDefaultName skips existing config names', () async {
    await service.addConfig(sampleConfig(id: '1', name: 'Config 1'));
    await service.addConfig(sampleConfig(id: '2', name: 'Config 2'));

    expect(service.generateDefaultName(), 'Config 3');
  });
}
