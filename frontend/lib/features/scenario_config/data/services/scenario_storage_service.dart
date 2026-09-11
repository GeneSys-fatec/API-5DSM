import 'dart:io';
import '../../domain/models/scenario_config_model.dart';

class ScenarioStorageService {
  static ScenarioConfigModel? _inMemoryCache;
  final String storagePath;

  ScenarioStorageService({this.storagePath = 'scenario_config.json'});

  Future<void> saveScenario(ScenarioConfigModel config) async {
    _inMemoryCache = config;
    try {
      final file = File(storagePath);
      file.writeAsStringSync(config.toJson());
    } catch (_) {}
  }

  Future<ScenarioConfigModel> loadScenario() async {
    if (_inMemoryCache != null) {
      return _inMemoryCache!;
    }
    try {
      final file = File(storagePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final config = ScenarioConfigModel.fromJson(content);
        _inMemoryCache = config;
        return config;
      }
    } catch (_) {}
    const defaultModel = ScenarioConfigModel();
    _inMemoryCache = defaultModel;
    return defaultModel;
  }

  Future<void> resetToDefaults() async {
    const defaultModel = ScenarioConfigModel();
    await saveScenario(defaultModel);
  }
}
