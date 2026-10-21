import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';
import 'package:frontend/features/scenario_results/presentation/widgets/gateway_info_card.dart';
import 'package:frontend/features/scenario_results/presentation/widgets/scenario_map.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SimulationScenario _createMockScenario({
  String? address,
  String? municipio,
  double coverageRadiusMeters = 3500.0,
  List<String> shadowedAssetKeys = const [],
  int gatewayCount = 1,
}) {
  final gateways = List.generate(
    gatewayCount,
    (i) => GatewayPoint(
      id: 'GW-${(i + 1).toString().padLeft(2, '0')}',
      posteId: 'POS-${1042 + i}',
      lat: -22.906800 + (i * 0.01),
      lng: -47.061600 + (i * 0.01),
      antennaHeight: 15.0,
      txPowerDbm: 27.0,
      linkedAssets: 120,
      avgFadeMarginDb: 18.5,
      coverageRadiusMeters: coverageRadiusMeters,
      address: address,
      municipio: municipio,
      shadowedAssetKeys: shadowedAssetKeys,
    ),
  );

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
      gateways: gateways,
    ),
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

// ---------------------------------------------------------------------------
// Test groups
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // 1. GatewayInfoCard — Requisitos de exibição
  // =========================================================================
  group('GatewayInfoCard — Exibição de Detalhes', () {
    testWidgets(
      'exibe ID, posteId, seção de localização, endereço, município e coordenadas',
      (tester) async {
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
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        // Cabeçalho
        expect(find.text('GW-01'), findsOneWidget);
        expect(find.text('POS-1042'), findsOneWidget);

        // Seção de localização
        expect(find.text('DETALHES DE LOCALIZAÇÃO'), findsOneWidget);
        expect(find.text('Av. Francisco Glicério, 1000'), findsOneWidget);
        expect(find.text('Campinas - SP'), findsOneWidget);

        // Coordenadas
        expect(find.text('-22.906800'), findsOneWidget);
        expect(find.text('-47.061600'), findsOneWidget);
      },
    );

    testWidgets(
      'exibe todos os parâmetros técnicos: altura, potência, ativos, margem de fade e alcance',
      (tester) async {
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
        );

        await tester.pumpWidget(
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        expect(find.text('PARÂMETROS TÉCNICOS'), findsOneWidget);
        expect(find.text('15.0 m'), findsOneWidget);       // Altura Antena
        expect(find.text('+27.0 dBm'), findsOneWidget);    // Potência TX
        expect(find.text('120'), findsOneWidget);           // Ativos Vinculados
        expect(find.text('18.5 dB'), findsOneWidget);       // Margem Fade
        expect(find.textContaining('3.5 km'), findsOneWidget); // Alcance
      },
    );

    testWidgets('exibe os botões Copiar Coordenadas e Abrir no Mapa',
        (tester) async {
      const gateway = GatewayPoint(
        id: 'GW-01',
        posteId: 'POS-1042',
        lat: -22.0,
        lng: -47.0,
        antennaHeight: 10.0,
        txPowerDbm: 20.0,
        linkedAssets: 50,
        avgFadeMarginDb: 10.0,
        coverageRadiusMeters: 1000.0,
      );

      await tester.pumpWidget(
        _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
      );

      expect(find.text('Copiar Coordenadas'), findsOneWidget);
      expect(find.text('Abrir no Mapa'), findsOneWidget);
    });

    testWidgets('botão de fechar chama onClose', (tester) async {
      bool closed = false;
      const gateway = GatewayPoint(
        id: 'GW-01',
        posteId: 'POS-1042',
        lat: -22.0,
        lng: -47.0,
        antennaHeight: 10.0,
        txPowerDbm: 20.0,
        linkedAssets: 50,
        avgFadeMarginDb: 10.0,
        coverageRadiusMeters: 1000.0,
      );

      await tester.pumpWidget(
        _wrap(
          GatewayInfoCard(
            gateway: gateway,
            onClose: () => closed = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      expect(closed, isTrue);
    });
  });

  // =========================================================================
  // 2. GatewayInfoCard — Copiar Coordenadas
  // =========================================================================
  group('GatewayInfoCard — Copiar Coordenadas', () {
    testWidgets(
      'copia texto formatado "lat, lng" com 6 casas para o clipboard',
      (tester) async {
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
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
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
        expect(
          find.textContaining('Coordenadas copiadas: -23.550520, -46.633308'),
          findsOneWidget,
        );
      },
    );
  });

  // =========================================================================
  // 3. GatewayInfoCard — Fallbacks de localização
  // =========================================================================
  group('GatewayInfoCard — Fallbacks de localização', () {
    testWidgets(
      'usa defaultMunicipio quando gateway não possui municipio próprio',
      (tester) async {
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
          _wrap(
            GatewayInfoCard(
              gateway: gateway,
              defaultMunicipio: 'São José dos Campos - SP',
              onClose: () {},
            ),
          ),
        );

        expect(find.text('São José dos Campos - SP'), findsOneWidget);
      },
    );

    testWidgets(
      'não exibe endereço nem município quando ambos são nulos e não há default',
      (tester) async {
        const gateway = GatewayPoint(
          id: 'GW-04',
          posteId: 'POS-4000',
          lat: -10.0,
          lng: -40.0,
          antennaHeight: 10.0,
          txPowerDbm: 20.0,
          linkedAssets: 10,
          avgFadeMarginDb: 12.0,
          coverageRadiusMeters: 1000.0,
        );

        await tester.pumpWidget(
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        // Seção de localização ainda existe com coordenadas
        expect(find.text('DETALHES DE LOCALIZAÇÃO'), findsOneWidget);
        // Mas não tem ícone de place/endereço
        expect(find.byIcon(Icons.place_outlined), findsNothing);
      },
    );

    testWidgets(
      'exibe somente endereço quando municipio é nulo e não há default',
      (tester) async {
        const gateway = GatewayPoint(
          id: 'GW-05',
          posteId: 'POS-5000',
          lat: -10.0,
          lng: -40.0,
          antennaHeight: 10.0,
          txPowerDbm: 20.0,
          linkedAssets: 10,
          avgFadeMarginDb: 12.0,
          coverageRadiusMeters: 1000.0,
          address: 'Rua das Flores, 42',
        );

        await tester.pumpWidget(
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        expect(find.text('Rua das Flores, 42'), findsOneWidget);
        expect(find.byIcon(Icons.place_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'prioriza municipio do gateway sobre defaultMunicipio',
      (tester) async {
        const gateway = GatewayPoint(
          id: 'GW-06',
          posteId: 'POS-6000',
          lat: -10.0,
          lng: -40.0,
          antennaHeight: 10.0,
          txPowerDbm: 20.0,
          linkedAssets: 10,
          avgFadeMarginDb: 12.0,
          coverageRadiusMeters: 1000.0,
          municipio: 'Recife - PE',
        );

        await tester.pumpWidget(
          _wrap(
            GatewayInfoCard(
              gateway: gateway,
              defaultMunicipio: 'Campinas - SP',
              onClose: () {},
            ),
          ),
        );

        expect(find.text('Recife - PE'), findsOneWidget);
        expect(find.text('Campinas - SP'), findsNothing);
      },
    );
  });

  // =========================================================================
  // 4. GatewayInfoCard — Exibição condicional
  // =========================================================================
  group('GatewayInfoCard — Exibição condicional', () {
    testWidgets('exibe ativos em sombra quando shadowedAssetKeys não é vazio',
        (tester) async {
      const gateway = GatewayPoint(
        id: 'GW-07',
        posteId: 'POS-7000',
        lat: -10.0,
        lng: -40.0,
        antennaHeight: 10.0,
        txPowerDbm: 20.0,
        linkedAssets: 50,
        avgFadeMarginDb: 10.0,
        coverageRadiusMeters: 2000.0,
        shadowedAssetKeys: ['A1', 'A2', 'A3'],
      );

      await tester.pumpWidget(
        _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
      );

      expect(find.text('3'), findsOneWidget); // 3 ativos em sombra
      expect(find.text('Ativos em Sombra'), findsOneWidget);
    });

    testWidgets(
      'não exibe ativos em sombra quando shadowedAssetKeys é vazio',
      (tester) async {
        const gateway = GatewayPoint(
          id: 'GW-08',
          posteId: 'POS-8000',
          lat: -10.0,
          lng: -40.0,
          antennaHeight: 10.0,
          txPowerDbm: 20.0,
          linkedAssets: 50,
          avgFadeMarginDb: 10.0,
          coverageRadiusMeters: 2000.0,
        );

        await tester.pumpWidget(
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        expect(find.text('Ativos em Sombra'), findsNothing);
      },
    );

    testWidgets(
      'não exibe alcance quando coverageRadiusMeters é 0',
      (tester) async {
        const gateway = GatewayPoint(
          id: 'GW-09',
          posteId: 'POS-9000',
          lat: -10.0,
          lng: -40.0,
          antennaHeight: 10.0,
          txPowerDbm: 20.0,
          linkedAssets: 50,
          avgFadeMarginDb: 10.0,
          coverageRadiusMeters: 0.0,
        );

        await tester.pumpWidget(
          _wrap(GatewayInfoCard(gateway: gateway, onClose: () {})),
        );

        expect(find.byIcon(Icons.radar_rounded), findsNothing);
      },
    );
  });

  // =========================================================================
  // 5. GatewayPoint — Serialização/Desserialização
  // =========================================================================
  group('GatewayPoint — Serialização roundtrip', () {
    test('toMap/fromMap preserva todos os campos incluindo address e municipio',
        () {
      const gw = GatewayPoint(
        id: 'GW-X',
        posteId: 'POS-X',
        lat: -15.123456,
        lng: -47.654321,
        antennaHeight: 12.5,
        txPowerDbm: 25.0,
        linkedAssets: 80,
        avgFadeMarginDb: 16.0,
        coverageRadiusMeters: 4200.0,
        address: 'Av. Paulista, 100',
        municipio: 'São Paulo - SP',
        shadowedAssetKeys: ['k1', 'k2'],
      );

      final map = gw.toMap();
      final restored = GatewayPoint.fromMap(map);

      expect(restored.id, gw.id);
      expect(restored.posteId, gw.posteId);
      expect(restored.lat, gw.lat);
      expect(restored.lng, gw.lng);
      expect(restored.antennaHeight, gw.antennaHeight);
      expect(restored.txPowerDbm, gw.txPowerDbm);
      expect(restored.linkedAssets, gw.linkedAssets);
      expect(restored.avgFadeMarginDb, gw.avgFadeMarginDb);
      expect(restored.coverageRadiusMeters, gw.coverageRadiusMeters);
      expect(restored.address, gw.address);
      expect(restored.municipio, gw.municipio);
      expect(restored.shadowedAssetKeys, gw.shadowedAssetKeys);
    });

    test('fromMap aceita chaves alternativas "endereco" e "cidade"', () {
      final map = {
        'id': 'GW-ALT',
        'posteId': 'POS-ALT',
        'lat': -10.0,
        'lng': -40.0,
        'antennaHeight': 10.0,
        'txPowerDbm': 20.0,
        'linkedAssets': 5,
        'avgFadeMarginDb': 8.0,
        'coverageRadiusMeters': 500.0,
        'endereco': 'Rua Alternativa, 1',
        'cidade': 'Cidade Alternativa',
      };

      final gw = GatewayPoint.fromMap(map);
      expect(gw.address, 'Rua Alternativa, 1');
      expect(gw.municipio, 'Cidade Alternativa');
    });

    test('fromMap com campos ausentes usa defaults seguros', () {
      final gw = GatewayPoint.fromMap({});

      expect(gw.id, '');
      expect(gw.posteId, '');
      expect(gw.lat, 0.0);
      expect(gw.lng, 0.0);
      expect(gw.antennaHeight, 6.0);
      expect(gw.txPowerDbm, 21.0);
      expect(gw.linkedAssets, 0);
      expect(gw.avgFadeMarginDb, 14.0);
      expect(gw.coverageRadiusMeters, 0.0);
      expect(gw.address, isNull);
      expect(gw.municipio, isNull);
      expect(gw.shadowedAssetKeys, isEmpty);
    });

    test('JSON encode/decode roundtrip completo via SimulationScenario', () {
      final scenario = _createMockScenario(
        address: 'Rua Teste',
        municipio: 'Cidade Teste',
        shadowedAssetKeys: ['s1'],
      );

      final jsonStr = scenario.toJson();
      final restored = SimulationScenario.fromJson(jsonStr);

      expect(restored.results.gateways.length, 1);
      final gw = restored.results.gateways.first;
      expect(gw.address, 'Rua Teste');
      expect(gw.municipio, 'Cidade Teste');
      expect(gw.shadowedAssetKeys, ['s1']);
      expect(gw.antennaHeight, 15.0);
      expect(gw.txPowerDbm, 27.0);
      expect(gw.linkedAssets, 120);
      expect(gw.avgFadeMarginDb, 18.5);
    });
  });

  // =========================================================================
  // 6. ScenarioMap — Integração com popup
  // =========================================================================
  group('ScenarioMap — Integração com popup do gateway', () {
    testWidgets(
      'clicar no marcador do gateway abre o popup e fechar o oculta',
      (tester) async {
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
          _wrap(
            SizedBox(
              height: 700,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
            ),
          ),
        );
        await tester.pump();

        // Popup não visível inicialmente
        expect(find.byType(GatewayInfoCard), findsNothing);

        // Clica no marcador do gateway
        final markerFinder = find.descendant(
          of: find.byType(MarkerLayer),
          matching: find.byIcon(Icons.cell_tower),
        );
        await tester.tap(markerFinder);
        await tester.pumpAndSettle();

        // Popup aparece com dados
        expect(find.byType(GatewayInfoCard), findsOneWidget);
        expect(find.text('GW-01'), findsOneWidget);
        expect(find.text('Rua Central, 50'), findsOneWidget);

        // Fecha o popup
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(GatewayInfoCard), findsNothing);
      },
    );

    testWidgets(
      'clicar em outro gateway troca o popup selecionado',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scenario = _createMockScenario(gatewayCount: 2);

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              height: 700,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
            ),
          ),
        );
        await tester.pump();

        final markers = find.descendant(
          of: find.byType(MarkerLayer),
          matching: find.byIcon(Icons.cell_tower),
        );

        // Clica no primeiro marcador
        await tester.tap(markers.first);
        await tester.pumpAndSettle();
        expect(find.text('GW-01'), findsOneWidget);

        // Clica no segundo marcador
        await tester.tap(markers.last);
        await tester.pumpAndSettle();
        expect(find.text('GW-02'), findsOneWidget);
      },
    );

    testWidgets(
      'renderiza responsivamente em viewport mobile (360x640) sem overflow',
      (tester) async {
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
          _wrap(
            SizedBox(
              width: 360,
              height: 640,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
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
      },
    );

    testWidgets(
      'renderiza responsivamente em viewport tablet (768x1024) sem overflow',
      (tester) async {
        tester.view.physicalSize = const Size(768, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scenario = _createMockScenario(
          address: 'Av. Brasil, 1500',
          municipio: 'Rio de Janeiro - RJ',
        );

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 768,
              height: 1024,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
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
      },
    );

    testWidgets(
      'renderiza responsivamente em viewport desktop (1920x1080) sem overflow',
      (tester) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final scenario = _createMockScenario(
          address: 'Av. Paulista, 2000',
          municipio: 'São Paulo - SP',
        );

        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 1920,
              height: 1080,
              child: ScenarioMap(scenario: scenario, enableTiles: false),
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
      },
    );
  });
}
