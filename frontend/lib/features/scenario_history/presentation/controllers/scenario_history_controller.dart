import 'package:flutter/material.dart';

import '../../data/models/scenario_models.dart';
import '../../data/services/saved_scenario_service.dart';

class ScenarioHistoryController extends ChangeNotifier {
  final SavedScenarioService _service;

  List<ScenarioSummary> _scenarios = [];
  final Set<String> _regions = {};
  String? _selectedRegion;
  String _searchQuery = '';
  final Set<int> _selectedIds = {};
  bool _groupByRegion = true;
  bool _isLoading = false;
  bool _isMutating = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isDisposed = false;

  ScenarioHistoryController({SavedScenarioService? service})
      : _service = service ?? SavedScenarioService();

  List<ScenarioSummary> get scenarios => filteredScenarios;

  List<ScenarioSummary> get rawScenarios => _scenarios;

  List<String> get regions => _regions.toList()..sort();

  String? get selectedRegion => _selectedRegion;
  String get searchQuery => _searchQuery;
  bool get groupByRegion => _groupByRegion;
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get canCompare => _selectedIds.length >= 2;
  bool isSelected(int id) => _selectedIds.contains(id);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get isEmpty => !_isLoading && _errorMessage == null && filteredScenarios.isEmpty;

  List<ScenarioSummary> get filteredScenarios {
    if (_searchQuery.trim().isEmpty) return _scenarios;
    final q = _searchQuery.trim().toLowerCase();
    return _scenarios.where((s) {
      return s.name.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<ScenarioSummary>> get groupedScenarios {
    final grouped = <String, List<ScenarioSummary>>{};
    for (final s in filteredScenarios) {
      final reg = s.regionName.trim().isEmpty ? 'Sem Região' : s.regionName.trim();
      grouped.putIfAbsent(reg, () => []).add(s);
    }
    return grouped;
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotify();
  }

  void setGroupByRegion(bool value) {
    _groupByRegion = value;
    _safeNotify();
  }

  void toggleSelection(int id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    _safeNotify();
  }

  void clearSelection() {
    _selectedIds.clear();
    _safeNotify();
  }

  Future<ScenarioComparisonResponse?> compareSelectedScenarios() async {
    if (_selectedIds.length < 2) return null;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final result = await _service.compareScenarios(_selectedIds.toList());
      return result;
    } on SavedScenarioException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (_) {
      _errorMessage = 'Falha ao comparar os cenários selecionados.';
      return null;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> loadScenarios() => _fetch(_selectedRegion);

  Future<void> selectRegion(String? region) {
    _selectedRegion = region;
    return _fetch(region);
  }

  Future<ScenarioDetail?> loadScenarioDetail(int id) async {
    try {
      return await _service.getScenario(id);
    } on SavedScenarioException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return null;
    }
  }

  Future<bool> duplicateScenario(int id, {String? name}) async {
    _isMutating = true;
    _successMessage = null;
    _errorMessage = null;
    _safeNotify();

    try {
      final duplicated = await _service.duplicateScenario(id, name: name);
      _successMessage = 'Cenário "${duplicated.name}" duplicado com sucesso.';
      await _fetch(_selectedRegion);
      return true;
    } on SavedScenarioException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return false;
    } finally {
      _isMutating = false;
      _safeNotify();
    }
  }

  Future<bool> deleteScenario(int id) async {
    _isMutating = true;
    _successMessage = null;
    _errorMessage = null;
    _safeNotify();

    try {
      await _service.deleteScenario(id);
      _successMessage = 'Cenário excluído com sucesso.';
      await _fetch(_selectedRegion);
      return true;
    } on SavedScenarioException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return false;
    } finally {
      _isMutating = false;
      _safeNotify();
    }
  }

  void clearMessages() {
    _successMessage = null;
    _errorMessage = null;
    _safeNotify();
  }

  Future<void> _fetch(String? regionName) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final scenarios = await _service.listScenarios(regionName: regionName);
      for (final scenario in scenarios) {
        if (scenario.regionName.isNotEmpty) {
          _regions.add(scenario.regionName);
        }
      }
      _scenarios = scenarios;
    } on SavedScenarioException catch (e) {
      _scenarios = [];
      _errorMessage = e.message;
    } catch (e) {
      _scenarios = [];
      _errorMessage = 'Erro inesperado ao carregar os cenários salvos.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
