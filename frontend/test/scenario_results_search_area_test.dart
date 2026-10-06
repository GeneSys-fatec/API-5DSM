import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/models/api_models.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';
import 'package:frontend/features/scenario_results/presentation/widgets/scenario_map.dart';

SimulationScenario _scenario({double searchRadiusMeters = 3500}) {
  return SimulationScenario(
    id: '1',
    code: 'SIM-1',
    region: 'Aracaju - SE',
    centerLat: -10.909,
    centerLng: -37.068,
    searchRadiusMeters: searchRadiusMeters,
    executedAt: DateTime(2026, 10, 2),
    parameters: const ScenarioParameters(
      feederName: 'x',
      gatewayCount: 1,
      txPowerDbm: 21,
      propagationModel: 'OKUMURA_HATA_SUBURBAN',
    ),
    results: const ScenarioResults(
      coveragePercent: 91,
      connectedAssets: 91,
      totalAssets: 100,
      implementationCost: 1500,
      avgRssiDbm: -120,
      gateways: [
        GatewayPoint(
          id: 'GW-1',
          posteId: 'p1',
          lat: -10.909,
          lng: -37.068,
          antennaHeight: 6,
          txPowerDbm: 21,
          linkedAssets: 91,
          avgFadeMarginDb: 14,
          coverageRadiusMeters: 1751,
        ),
      ],
    ),
  );
}

void main() {
  group('SimulationScenario.searchRadiusMeters', () {
    test('sobrevive a serializacao (historico/cache local)', () {
      final restored = SimulationScenario.fromJson(_scenario().toJson());
      expect(restored.searchRadiusMeters, 3500);
    });

    test('cenarios salvos antes do campo existir voltam com raio 0', () {
      final map = _scenario().toMap()..remove('searchRadiusMeters');
      expect(SimulationScenario.fromMap(map).searchRadiusMeters, 0.0);
    });

    test('SimulationResponse.toSimulationScenario repassa o raio da busca', () {
      final response = SimulationResponse.fromMap({
        'scenarioId': 7,
        'status': 'concluido',
        'propagationModel': 'OKUMURA_HATA_SUBURBAN',
        'rfParameter': <String, dynamic>{},
        'selectedGateways': [
          {'candidateId': 1, 'latitude': -10.9, 'longitude': -37.0, 'coverageRadiusMeters': 1751.0},
        ],
        'totalCoveragePct': 91.0,
        'coveragePctByAssetType': <String, dynamic>{},
        'coveredAssetKeys': ['a'],
        'uncoveredAssetKeys': <String>[],
        'usedGatewayCount': 1,
        'totalEstimatedCost': 1500.0,
        'processingTimeMs': 10,
        'targetReached': true,
      });
      final scenario = response.toSimulationScenario(
        centerLat: '-10.909',
        centerLng: '-37.068',
        regionName: 'Aracaju',
        searchRadiusMeters: 3500,
      );
      expect(scenario.searchRadiusMeters, 3500);
    });
  });

  group('computeScenarioViewBounds', () {
    test('sem area de busca mantem o enquadramento padrao', () {
      expect(computeScenarioViewBounds(_scenario(searchRadiusMeters: 0)), isNull);
    });

    test('engloba a area de busca inteira', () {
      final bounds = computeScenarioViewBounds(_scenario())!;
      expect(bounds.south, lessThan(-10.909 - 0.031));
      expect(bounds.north, greaterThan(-10.909 + 0.031));
      expect(bounds.west, lessThan(-37.068 - 0.031));
      expect(bounds.east, greaterThan(-37.068 + 0.031));
    });

    test('estende o enquadramento quando o alcance do gateway passa da area de busca', () {
      final wide = SimulationScenario(
        id: '2',
        code: 'SIM-2',
        region: 'x',
        centerLat: -10.909,
        centerLng: -37.068,
        searchRadiusMeters: 500,
        executedAt: DateTime(2026, 10, 2),
        parameters: _scenario().parameters,
        results: _scenario().results,
      );
      final bounds = computeScenarioViewBounds(wide)!;
      expect(bounds.north, greaterThan(-10.909 + 0.0157));
    });
  });

  group('ScenarioMap', () {
    Future<void> pump(WidgetTester tester, SimulationScenario scenario) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 700,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('desenha o circulo da area de busca e o toggle da camada', (tester) async {
      await pump(tester, _scenario());

      expect(find.text('Área de busca'), findsOneWidget);
      expect(find.textContaining('Área de busca (raio 3.5 km)'), findsOneWidget);

      final radii = tester
          .widgetList<CircleLayer>(find.byType(CircleLayer))
          .expand((layer) => layer.circles)
          .map((c) => c.radius)
          .toList();
      expect(radii, contains(3500.0));
      expect(radii, contains(1751.0));
    });

    testWidgets('desligar a camada remove o circulo e a legenda', (tester) async {
      await pump(tester, _scenario());

      await tester.tap(find.text('Área de busca'));
      await tester.pump();

      final radii = tester
          .widgetList<CircleLayer>(find.byType(CircleLayer))
          .expand((layer) => layer.circles)
          .map((c) => c.radius)
          .toList();
      expect(radii, isNot(contains(3500.0)));
      expect(find.textContaining('Área de busca (raio'), findsNothing);
    });

    testWidgets('cenario sem raio nao mostra a camada de area de busca', (tester) async {
      await pump(tester, _scenario(searchRadiusMeters: 0));

      expect(find.text('Área de busca'), findsNothing);
      expect(find.textContaining('Área de busca (raio'), findsNothing);
    });
  });
}
