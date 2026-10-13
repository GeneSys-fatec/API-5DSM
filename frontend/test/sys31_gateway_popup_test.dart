import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';
import 'package:frontend/features/scenario_results/presentation/widgets/gateway_info_card.dart';
import 'package:frontend/features/scenario_results/presentation/widgets/scenario_map.dart';

SimulationScenario _createMockScenario({
  String? address,
  String? municipio,
}) {
  return SimulationScenario(
    id: '1',
    code: 'SIM-TEST-01',
    region: 'Campinas - SP',
    centerLat: -22.9068,
    centerLng: -47.0616,
    searchRadiusMeters: 3000,
    executedAt: DateTime(2026, 10, 13),
    parameters: const ScenarioParameters(
      feederName: 'Alimentador Principal',
      gatewayCount: 1,
      txPowerDbm: 27,
      propagationModel: 'OKUMURA_HATA_URBAN',
    ),
    results: ScenarioResults(
      coveragePercent: 95.5,
      connectedAssets: 120,
      totalAssets: 125,
      implementationCost: 45000,
      avgRssiDbm: -85,
      gateways: [
        GatewayPoint(
          id: 'GW-01',
          posteId: 'POS-1042',
          lat: -22.906800,
          lng: -47.061600,
          antennaHeight: 15.0,
          txPowerDbm: 27.0,
          linkedAssets: 120,
          avgFadeMarginDb: 18.5,
          coverageRadiusMeters: 3500.0,
          address: address,
          municipio: municipio,
        ),
      ],
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GatewayInfoCard Widget Tests', () {
    testWidgets('exibe detalhes de localizacao, parametros tecnicos e acoes', (tester) async {
      bool closed = false;
      const gateway = GatewayPoint(
        id: 'GW-01',
        posteId: 'POS-1042',
        lat: -22.906800,
        lng: -47.061600,
        antennaHeight: 15.0,
        txPowerDbm: 27.0,
        linkedAssets: 120,
        avgFadeMarginDb: 18.5,
        coverageRadiusMeters: 3500.0,
        address: 'Av. Francisco Glicério, 1000',
        municipio: 'Campinas - SP',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatewayInfoCard(
              gateway: gateway,
              defaultMunicipio: 'Campinas - SP',
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      expect(find.text('GW-01'), findsOneWidget);
      expect(find.text('POS-1042'), findsOneWidget);
      expect(find.text('DETALHES DE LOCALIZAÇÃO'), findsOneWidget);
      expect(find.text('Av. Francisco Glicério, 1000'), findsOneWidget);
      expect(find.text('Campinas - SP'), findsOneWidget);
      expect(find.text('-22.906800'), findsOneWidget);
      expect(find.text('-47.061600'), findsOneWidget);

      expect(find.text('PARÂMETROS TÉCNICOS'), findsOneWidget);
      expect(find.text('15.0 m'), findsOneWidget);
      expect(find.text('+27.0 dBm'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text('18.5 dB'), findsOneWidget);
      expect(find.textContaining('3.5 km'), findsOneWidget);

      expect(find.text('Copiar Coordenadas'), findsOneWidget);
      expect(find.text('Abrir no Mapa'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('copiar coordenadas copia texto formatado para area de transferencia', (tester) async {
      final List<MethodCall> log = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          log.add(methodCall);
          return null;
        },
      );

      const gateway = GatewayPoint(
        id: 'GW-02',
        posteId: 'POS-2000',
        lat: -23.550520,
        lng: -46.633308,
        antennaHeight: 12.0,
        txPowerDbm: 20.0,
        linkedAssets: 45,
        avgFadeMarginDb: 14.0,
        coverageRadiusMeters: 2000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatewayInfoCard(
              gateway: gateway,
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Copiar Coordenadas'));
      await tester.pump();

      expect(
        log.any(
          (call) =>
              call.method == 'Clipboard.setData' &&
              call.arguments['text'] == '-23.550520, -46.633308',
        ),
        isTrue,
      );
      expect(find.textContaining('Coordenadas copiadas: -23.550520, -46.633308'), findsOneWidget);
    });

    testWidgets('usa defaultMunicipio quando gateway nao possui municipio proprio', (tester) async {
      const gateway = GatewayPoint(
        id: 'GW-03',
        posteId: 'POS-3000',
        lat: -10.0,
        lng: -40.0,
        antennaHeight: 10.0,
        txPowerDbm: 20.0,
        linkedAssets: 10,
        avgFadeMarginDb: 12.0,
        coverageRadiusMeters: 1000.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GatewayInfoCard(
              gateway: gateway,
              defaultMunicipio: 'São José dos Campos - SP',
              onClose: () {},
            ),
          ),
        ),
      );

      expect(find.text('São José dos Campos - SP'), findsOneWidget);
    });
  });

  group('ScenarioMap Gateway Popup Integration', () {
    testWidgets('clicar no marcador do gateway abre o popup e fechar o oculta', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final scenario = _createMockScenario(
        address: 'Rua Central, 50',
        municipio: 'Campinas - SP',
      );

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

      expect(find.byType(GatewayInfoCard), findsNothing);

      final markerFinder = find.descendant(
        of: find.byType(MarkerLayer),
        matching: find.byIcon(Icons.cell_tower),
      );
      await tester.tap(markerFinder);
      await tester.pumpAndSettle();

      expect(find.byType(GatewayInfoCard), findsOneWidget);
      expect(find.text('GW-01'), findsOneWidget);
      expect(find.text('Rua Central, 50'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(GatewayInfoCard), findsNothing);
    });

    testWidgets('renderiza responsivamente em viewport mobile sem overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final scenario = _createMockScenario(
        address: 'Av. Santos Dumont, 500',
        municipio: 'Campinas - SP',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
            ),
          ),
        ),
      );
      await tester.pump();

      final markerFinder = find.descendant(
        of: find.byType(MarkerLayer),
        matching: find.byIcon(Icons.cell_tower),
      );
      await tester.tap(markerFinder);
      await tester.pumpAndSettle();

      expect(find.byType(GatewayInfoCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
