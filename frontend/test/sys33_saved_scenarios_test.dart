import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';
import 'package:frontend/features/scenario_history/data/services/saved_scenario_service.dart';
import 'package:frontend/features/scenario_history/presentation/controllers/scenario_history_controller.dart';

Map<String, dynamic> _summaryJson({
  int id = 1,
  String name = 'Cenário Centro',
  String regionName = 'Centro',
  double? totalCoveragePct = 85.5,
  int? usedGatewayCount = 3,
  double? totalEstimatedCost = 4500.0,
}) {
  return {
    'id': id,
    'name': name,
    'regionName': regionName,
    'coverageTargetPct': 90.0,
    'maxGateways': 5,
    'propagationModel': 'OKUMURA_HATA_SUBURBAN',
    'status': 'concluido',
    'totalCoveragePct': totalCoveragePct,
    'usedGatewayCount': usedGatewayCount,
    'totalEstimatedCost': totalEstimatedCost,
    'processedAt': '2026-10-13T12:34:56Z',
  };
}

Map<String, dynamic> _detailJson() {
  return {
    'id': 7,
    'name': 'Cenário Centro',
    'regionName': 'Centro',
    'areaWkt': 'POLYGON((-47.1 -22.9, -47.0 -22.9, -47.0 -22.8, -47.1 -22.8, -47.1 -22.9))',
    'coverageTargetPct': 90.0,
    'maxGateways': 5,
    'gatewayUnitCost': 1500.0,
    'propagationModel': 'OKUMURA_HATA_SUBURBAN',
    'rfParameter': {
      'frequencyMhz': 915.0,
      'transmitPowerDbm': 21.0,
      'receiverSensitivityDbm': -120.0,
      'antennaHeightM': 6.0,
      'deviceHeightM': 5.0,
      'antennaGainDbi': 0.0,
      'systemLossDb': 14.0,
    },
    'status': 'concluido',
    'processingTimeMs': 42,
    'processedAt': '2026-10-13T12:34:56Z',
    'selectedGateways': [
      {
        'candidateId': 1,
        'latitude': -22.9,
        'longitude': -47.1,
        'coverageRadiusMeters': 1850.5,
        'manuallyAdjusted': false,
      },
      {
        'candidateId': 2,
        'latitude': -22.8,
        'longitude': -47.0,
        'coverageRadiusMeters': 2100.0,
        'manuallyAdjusted': true,
      },
    ],
    'indicator': {
      'totalCoveragePct': 85.5,
      'coveragePctByAssetType': {'religador': 91.0, 'medidor': 80.0},
      'usedGatewayCount': 2,
      'totalEstimatedCost': 3000.0,
      'targetReached': false,
    },
  };
}

class FakeSavedScenarioService implements SavedScenarioService {
  List<ScenarioSummary> scenarios;
  String? filterUsed;
  Object? listError;
  int detailCalls = 0;
  int deleteCalls = 0;
  int duplicateCalls = 0;
  String? duplicateName;

  FakeSavedScenarioService({this.scenarios = const [], this.listError});

  @override
  Future<List<ScenarioSummary>> listScenarios({String? regionName}) async {
    if (listError != null) throw listError!;
    filterUsed = regionName;
    if (regionName == null) return scenarios;
    return scenarios.where((s) => s.regionName == regionName).toList();
  }

  @override
  Future<ScenarioDetail> getScenario(int id) async {
    detailCalls++;
    if (listError != null) throw listError!;
    return ScenarioDetail.fromJson(_detailJson());
  }

  @override
  Future<ScenarioSummary> duplicateScenario(int id, {String? name}) async {
    duplicateCalls++;
    duplicateName = name;
    if (listError != null) throw listError!;
    final copy = ScenarioSummary.fromJson(_summaryJson(id: 99, name: name ?? 'Cenário Centro (cópia)'));
    scenarios = [...scenarios, copy];
    return copy;
  }

  @override
  Future<void> deleteScenario(int id) async {
    deleteCalls++;
    if (listError != null) throw listError!;
    scenarios = scenarios.where((s) => s.id != id).toList();
  }

  @override
  Future<ScenarioComparisonResponse> compareScenarios(List<int> ids) async {
    if (listError != null) throw listError!;
    final matching = scenarios.where((s) => ids.contains(s.id)).toList();
    return ScenarioComparisonResponse(
      scenarios: matching,
      comparisonIndicators: {'count': matching.length},
    );
  }
}

void main() {
  group('ScenarioSummary.fromJson', () {
    test('le nome, regiao e indicadores da listagem', () {
      final summary = ScenarioSummary.fromJson(_summaryJson());

      expect(summary.id, 1);
      expect(summary.name, 'Cenário Centro');
      expect(summary.regionName, 'Centro');
      expect(summary.totalCoveragePct, 85.5);
      expect(summary.usedGatewayCount, 3);
      expect(summary.totalEstimatedCost, 4500.0);
      expect(summary.processedAt, DateTime.utc(2026, 10, 13, 12, 34, 56));
    });

    test('aceita cenarios sem indicadores calculados', () {
      final summary = ScenarioSummary.fromJson(
        _summaryJson(totalCoveragePct: null, usedGatewayCount: null, totalEstimatedCost: null),
      );

      expect(summary.totalCoveragePct, isNull);
      expect(summary.usedGatewayCount, isNull);
      expect(summary.totalEstimatedCost, isNull);
    });
  });

  group('ScenarioDetail.fromJson', () {
    test('le parametros, gateways e indicadores salvos', () {
      final detail = ScenarioDetail.fromJson(_detailJson());

      expect(detail.id, 7);
      expect(detail.regionName, 'Centro');
      expect(detail.coverageTargetPct, 90.0);
      expect(detail.gatewayUnitCost, 1500.0);
      expect(detail.rfParameter!.frequencyMhz, 915.0);
      expect(detail.rfParameter!.systemLossDb, 14.0);
      expect(detail.processingTimeMs, 42);
      expect(detail.selectedGateways, hasLength(2));
      expect(detail.selectedGateways.first.coverageRadiusMeters, 1850.5);
      expect(detail.selectedGateways.last.manuallyAdjusted, isTrue);
      expect(detail.indicator!.totalCoveragePct, 85.5);
      expect(detail.indicator!.coveragePctByAssetType['religador'], 91.0);
      expect(detail.indicator!.targetReached, isFalse);
    });

    test('toSimulationScenario reaproveita os gateways salvos', () {
      final detail = ScenarioDetail.fromJson(_detailJson());
      final scenario = detail.toSimulationScenario();

      expect(scenario.id, '7');
      expect(scenario.region, 'Centro');
      expect(scenario.parameters.propagationModel, 'OKUMURA_HATA_SUBURBAN');
      expect(scenario.parameters.gatewayCount, 2);
      expect(scenario.results.coveragePercent, 85.5);
      expect(scenario.results.gateways, hasLength(2));
      expect(scenario.results.gateways.first.coverageRadiusMeters, 1850.5);
      expect(scenario.centerLat, closeTo(-22.85, 0.0001));
      expect(scenario.centerLng, closeTo(-47.05, 0.0001));
    });
  });

  group('ScenarioHistoryController', () {
    test('carrega a listagem inicial', () async {
      final service = FakeSavedScenarioService(
        scenarios: [
          ScenarioSummary.fromJson(_summaryJson()),
          ScenarioSummary.fromJson(_summaryJson(id: 2, name: 'Cenário Norte', regionName: 'Norte')),
        ],
      );
      final controller = ScenarioHistoryController(service: service);

      expect(controller.isLoading, isFalse);
      expect(controller.isEmpty, isTrue);

      await controller.loadScenarios();

      expect(controller.scenarios, hasLength(2));
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.isEmpty, isFalse);
      expect(controller.regions, ['Centro', 'Norte']);
    });

    test('filtra por regiao usando o parametro da API', () async {
      final service = FakeSavedScenarioService(
        scenarios: [
          ScenarioSummary.fromJson(_summaryJson()),
          ScenarioSummary.fromJson(_summaryJson(id: 2, name: 'Cenário Norte', regionName: 'Norte')),
        ],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();

      await controller.selectRegion('Norte');

      expect(service.filterUsed, 'Norte');
      expect(controller.selectedRegion, 'Norte');
      expect(controller.scenarios.single.name, 'Cenário Norte');

      await controller.selectRegion(null);
      expect(service.filterUsed, isNull);
      expect(controller.scenarios, hasLength(2));
    });

    test('trata erro de requisicao com mensagem e lista vazia', () async {
      final service = FakeSavedScenarioService(
        listError: const SavedScenarioException('Falha ao listar cenários'),
      );
      final controller = ScenarioHistoryController(service: service);

      await controller.loadScenarios();

      expect(controller.errorMessage, 'Falha ao listar cenários');
      expect(controller.scenarios, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.isEmpty, isFalse);
    });

    test('trata resposta vazia da API sem erro', () async {
      final controller = ScenarioHistoryController(service: FakeSavedScenarioService());

      await controller.loadScenarios();

      expect(controller.errorMessage, isNull);
      expect(controller.isEmpty, isTrue);
      expect(controller.regions, isEmpty);
    });

    test('duplica o cenario e atualiza a listagem', () async {
      final service = FakeSavedScenarioService(
        scenarios: [ScenarioSummary.fromJson(_summaryJson())],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();

      final ok = await controller.duplicateScenario(1, name: 'Cenário Centro (cópia)');

      expect(ok, isTrue);
      expect(service.duplicateCalls, 1);
      expect(service.duplicateName, 'Cenário Centro (cópia)');
      expect(controller.scenarios, hasLength(2));
      expect(controller.scenarios.last.name, 'Cenário Centro (cópia)');
      expect(controller.successMessage, contains('duplicado'));
      expect(controller.isMutating, isFalse);
    });

    test('nao duplica quando a API falha', () async {
      final service = FakeSavedScenarioService(
        scenarios: [ScenarioSummary.fromJson(_summaryJson())],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();
      service.listError = const SavedScenarioException('Cenário não encontrado.');

      final ok = await controller.duplicateScenario(1);

      expect(ok, isFalse);
      expect(service.duplicateCalls, 1);
      expect(controller.errorMessage, 'Cenário não encontrado.');
      expect(controller.scenarios, hasLength(1));
      expect(controller.isMutating, isFalse);
    });

    test('exclui o cenario apos confirmacao e atualiza a listagem', () async {
      final service = FakeSavedScenarioService(
        scenarios: [
          ScenarioSummary.fromJson(_summaryJson()),
          ScenarioSummary.fromJson(_summaryJson(id: 2, name: 'Cenário Norte', regionName: 'Norte')),
        ],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();

      final ok = await controller.deleteScenario(1);

      expect(ok, isTrue);
      expect(service.deleteCalls, 1);
      expect(controller.scenarios, hasLength(1));
      expect(controller.scenarios.single.name, 'Cenário Norte');
      expect(controller.successMessage, 'Cenário excluído com sucesso.');
    });

    test('mantem o cenario quando a exclusao falha', () async {
      final service = FakeSavedScenarioService(
        scenarios: [ScenarioSummary.fromJson(_summaryJson())],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();
      service.listError = const SavedScenarioException('Falha ao excluir cenário');

      final ok = await controller.deleteScenario(1);

      expect(ok, isFalse);
      expect(controller.errorMessage, 'Falha ao excluir cenário');
      expect(controller.scenarios, hasLength(1));
    });

    test('carrega os detalhes do cenario selecionado', () async {
      final service = FakeSavedScenarioService(
        scenarios: [ScenarioSummary.fromJson(_summaryJson())],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();

      final detail = await controller.loadScenarioDetail(1);

      expect(service.detailCalls, 1);
      expect(detail, isNotNull);
      expect(detail!.indicator!.totalCoveragePct, 85.5);
      expect(controller.errorMessage, isNull);
    });

    test('devolve null e sinaliza o erro quando os detalhes falham', () async {
      final service = FakeSavedScenarioService(
        scenarios: [ScenarioSummary.fromJson(_summaryJson())],
      );
      final controller = ScenarioHistoryController(service: service);
      await controller.loadScenarios();
      service.listError = const SavedScenarioException('Falha ao buscar cenário');

      final detail = await controller.loadScenarioDetail(1);

      expect(detail, isNull);
      expect(controller.errorMessage, 'Falha ao buscar cenário');
    });
  });
}
