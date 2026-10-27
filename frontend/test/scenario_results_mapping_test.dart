import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/models/api_models.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';

void main() {
  group('SimulationResponse -> SimulationScenario', () {
    SimulationResponse response() => SimulationResponse(
          scenarioId: 7,
          scenarioName: 'Cenario',
          status: 'concluido',
          propagationModel: 'OKUMURA_HATA_SUBURBAN',
          rfParameter: const {
            'frequencyMhz': 915.0,
            'transmitPowerDbm': 21.0,
            'antennaHeightM': 6.0,
            'systemLossDb': 14.0,
          },
          selectedGateways: const [
            SelectedGatewayResponse(
              candidateId: 3,
              latitude: -10.9,
              longitude: -37.0,
              coverageRadiusMeters: 800,
              assetKey: 'POSTE::TESTE::3',
              coveredAssetCount: 420,
              averageLinkMarginDb: 7.26,
            ),
            SelectedGatewayResponse(
              candidateId: 9,
              latitude: -10.91,
              longitude: -37.01,
              coverageRadiusMeters: 650,
              assetKey: 'POSTE::TESTE::9',
              coveredAssetCount: 15,
              averageLinkMarginDb: 2.04,
            ),
          ],
          totalCoveragePct: 88.9,
          coveragePctByAssetType: const {},
          coveredAssetKeys: const ['a', 'b', 'c'],
          uncoveredAssetKeys: const ['d'],
          usedGatewayCount: 2,
          totalEstimatedCost: 3000,
          processingTimeMs: 10,
          targetReached: false,
        );

    test('usa os valores calculados de cada gateway e nao medias globais', () {
      final scenario = response().toSimulationScenario(
        centerLat: '-10.9',
        centerLng: '-37.0',
        regionName: 'Teste',
      );

      final first = scenario.results.gateways[0];
      final second = scenario.results.gateways[1];
      expect(first.posteId, 'POSTE::TESTE::3');
      expect(first.linkedAssets, 420);
      expect(second.linkedAssets, 15);
      expect(first.avgFadeMarginDb, 7.3);
      expect(second.avgFadeMarginDb, 2.0);
      expect(first.coverageRadiusMeters, 800);
      expect(second.coverageRadiusMeters, 650);
    });

    test('carrega o poligono da area de busca no cenario', () {
      final scenario = response().toSimulationScenario(
        centerLat: '-10.9',
        centerLng: '-37.0',
        regionName: 'Teste',
        searchPolygon: const [
          [-10.90, -37.00],
          [-10.90, -37.02],
          [-10.92, -37.00],
        ],
      );

      expect(scenario.searchPolygon.length, 3);
      expect(SimulationScenario.fromJson(scenario.toJson()).searchPolygon, scenario.searchPolygon);
    });
  });

  group('ScenarioDetail (historico) -> SimulationScenario', () {
    Map<String, dynamic> detailJson() => {
          'id': 5,
          'name': 'Cenário 2026-10-27 08:07',
          'regionName': 'ANATEL (Norte)',
          'areaWkt': 'POLYGON((-37.0 -10.9, -37.02 -10.9, -37.0 -10.92, -37.0 -10.9))',
          'coverageTargetPct': 95.0,
          'maxGateways': 12,
          'propagationModel': 'OKUMURA_HATA_SUBURBAN',
          'rfParameter': {
            'frequencyMhz': 915.0,
            'transmitPowerDbm': 21.0,
            'receiverSensitivityDbm': -120.0,
            'antennaHeightM': 6.0,
            'deviceHeightM': 5.0,
            'systemLossDb': 14.0,
          },
          'selectedGateways': [
            {
              'candidateId': 1,
              'latitude': -10.9,
              'longitude': -37.0,
              'coverageRadiusMeters': 500.0,
              'linkedAssets': 2,
              'assetKey': 'POSTE::TESTE::1',
              'coveredAssetCount': 420,
              'averageLinkMarginDb': 7.26,
              'coverageGeometryGeoJson': '{"type":"Polygon","coordinates":[[[-37.0,-10.9],[-37.01,-10.9],[-37.0,-10.91],[-37.0,-10.9]]]}',
              'shadowedAssetKeys': ['POSTE::9'],
            },
          ],
          'averageRssiDbm': -104.5,
          'indicator': {'totalCoveragePct': 66.7, 'usedGatewayCount': 1, 'totalEstimatedCost': 1500.0},
          'assets': [
            {'assetKey': 'POSTE::1', 'type': 'POSTE', 'latitude': -10.9, 'longitude': -37.0, 'covered': true},
            {'assetKey': 'POSTE::2', 'type': 'POSTE', 'latitude': -10.901, 'longitude': -37.001, 'covered': true},
            {'assetKey': 'SUB::3', 'type': 'SUB', 'latitude': -10.95, 'longitude': -37.05, 'covered': false},
          ],
        };

    test('reabre o resultado com ativos, area e valores por gateway', () {
      final scenario = ScenarioDetail.fromJson(detailJson()).toSimulationScenario();

      expect(scenario.results.totalAssets, 3);
      expect(scenario.results.connectedAssets, 2);
      expect(scenario.results.assets.length, 3);
      expect(scenario.results.assets.last.type, 'SUB');
      final gateway = scenario.results.gateways.single;
      expect(gateway.linkedAssets, 420, reason: 'usa o que o gateway cobre individualmente, como no resultado direto');
      expect(gateway.posteId, 'POSTE::TESTE::1');
      expect(gateway.avgFadeMarginDb, 7.3);
      expect(gateway.shadowedAssetKeys, ['POSTE::9']);
      expect(gateway.coverageGeometryGeoJson, isNotNull,
          reason: 'sem a geometria o mapa cai no circulo padrao');
      expect(scenario.searchPolygon.length, 3, reason: 'o ponto de fechamento nao deve se repetir');
      expect(scenario.searchPolygon.first, [-10.9, -37.0]);
      expect(scenario.results.avgRssiDbm, -104.5);
      expect(scenario.parameters.frequencyMhz, 915.0);
      expect(scenario.parameters.coverageTargetPct, 95.0);
      expect(scenario.parameters.maxGateways, 12);
    });

    test('parsePolygonWkt ignora WKT invalido', () {
      expect(ScenarioDetail.parsePolygonWkt(null), isEmpty);
      expect(ScenarioDetail.parsePolygonWkt('POINT(1 2)'), isEmpty);
    });
  });
}
