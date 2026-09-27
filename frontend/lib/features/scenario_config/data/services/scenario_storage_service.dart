import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/scenario_config_model.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../../../scenario_results/models/scenario_results_models.dart';

class ScenarioStorageService {
  static const String _keyScenarioConfig = 'scenario_config';
  static const String _keyLastSimulation = 'last_simulation_scenario';
  static const String _keyAreaConfig = 'last_area_config';
  static const String _keyAreaResult = 'last_area_result';

  static ScenarioConfigModel? _inMemoryCache;

  Future<void> saveScenario(ScenarioConfigModel config) async {
    _inMemoryCache = config;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyScenarioConfig, config.toJson());
    } catch (_) {}
  }

  Future<ScenarioConfigModel> loadScenario() async {
    if (_inMemoryCache != null) {
      return _inMemoryCache!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyScenarioConfig);
      if (content != null && content.isNotEmpty) {
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

  Future<void> saveLastSimulationScenario(SimulationScenario scenario) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSimulation, scenario.toJson());
    } catch (_) {}
  }

  Future<SimulationScenario?> loadLastSimulationScenario() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyLastSimulation);
      if (content != null && content.isNotEmpty) {
        return SimulationScenario.fromJson(content);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveAreaConfig(AreaDelimitationConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAreaConfig, config.toJson());
    } catch (_) {}
  }

  Future<AreaDelimitationConfig?> loadAreaConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyAreaConfig);
      if (content != null && content.isNotEmpty) {
        return AreaDelimitationConfig.fromJson(content);
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveAreaResult(AreaDelimitationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAreaResult, result.toJson());
    } catch (_) {}
  }

  Future<AreaDelimitationResult?> loadAreaResult() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString(_keyAreaResult);
      if (content != null && content.isNotEmpty) {
        return AreaDelimitationResult.fromJson(content);
      }
    } catch (_) {}
    return null;
  }
}
