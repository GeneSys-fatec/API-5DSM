import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/scenario_storage_service.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';
import 'package:frontend/features/scenario_history/data/services/saved_scenario_service.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';
import 'package:frontend/features/scenario_results/presentation/screens/scenario_results_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingSavedScenarioService extends SavedScenarioService {
  final List<Map<String, dynamic>> updateCalls = [];
  Object? errorToThrow;

  @override
  Future<ScenarioSummary> updateScenario(
    int id, {
    required String name,
    String? regionName,
  }) async {
    updateCalls.add({'id': id, 'name': name, 'regionName': regionName});
    if (errorToThrow != null) throw errorToThrow!;
    return ScenarioSummary(
      id: id,
      name: name,
      regionName: regionName ?? '',
    );
  }
}

SimulationScenario _buildScenario({
  String id = '42',
  String? name = 'Cenário 2026-11-11 10:00',
  String feederName = '',
  String region = 'Regional Leste',
}) {
  return SimulationScenario(
    id: id,
    code: name ?? '',
    name: name,
    region: region,
    centerLat: -23.1896,
    centerLng: -45.8841,
    executedAt: DateTime(2026, 11, 11, 10, 0),
    parameters: ScenarioParameters(
      feederName: feederName,
      gatewayCount: 1,
      txPowerDbm: 21.0,
      propagationModel: 'OKUMURA_HATA_SUBURBAN',
    ),
    results: const ScenarioResults(
      coveragePercent: 95.0,
      connectedAssets: 19,
      totalAssets: 20,
      implementationCost: 1500.0,
      gateways: [
        GatewayPoint(
          id: 'GW-1',
          posteId: 'POSTE-1',
          lat: -23.1896,
          lng: -45.8841,
          antennaHeight: 6.0,
          txPowerDbm: 21.0,
          linkedAssets: 19,
          avgFadeMarginDb: 12.0,
          coverageRadiusMeters: 1500.0,
        ),
      ],
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'test-jwt'});
  });

  group('SavedScenarioService.updateScenario', () {
    test('envia name e regionName no payload PATCH /scenarios/{id}', () async {
      late http.Request capturedRequest;
      final client = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'id': 42,
            'name': 'Cenário Renomeado',
            'regionName': 'Campinas - SP',
            'status': 'concluido',
          }),
          200,
        );
      });

      final service = SavedScenarioService(httpClient: client);
      final updated = await service.updateScenario(
        42,
        name: '  Cenário Renomeado  ',
        regionName: '  Campinas - SP  ',
      );

      expect(capturedRequest.method, 'PATCH');
      expect(capturedRequest.url.path, endsWith('/scenarios/42'));
      expect(
        jsonDecode(capturedRequest.body),
        {'name': 'Cenário Renomeado', 'regionName': 'Campinas - SP'},
      );
      expect(updated.id, 42);
      expect(updated.name, 'Cenário Renomeado');
      expect(updated.regionName, 'Campinas - SP');
    });
  });

  group('ScenarioSummary e ScenarioDetail nome padrão', () {
    test('mantém o nome salvo quando informado e usa padrão apenas quando vazio ou nulo', () {
      final named = ScenarioSummary.fromJson({
        'id': 1,
        'name': '  Cenário Centro  ',
        'regionName': 'Centro',
      });
      final emptyName = ScenarioSummary.fromJson({
        'id': 2,
        'name': '',
        'regionName': 'Centro',
      });
      final nullName = ScenarioSummary.fromJson({
        'id': 3,
        'name': null,
        'regionName': 'Norte',
      });
      final whitespaceName = ScenarioSummary.fromJson({
        'id': 4,
        'name': '   ',
        'regionName': 'Sul',
      });

      expect(named.displayName, 'Cenário Centro');
      expect(emptyName.displayName, 'Cenário 2');
      expect(nullName.displayName, 'Cenário 3');
      expect(whitespaceName.displayName, 'Cenário 4');
    });

    test('ScenarioDetail.toSimulationScenario preserva nome salvo ou usa padrão quando sem nome', () {
      final detailWithoutName = ScenarioDetail.fromJson({
        'id': 15,
        'name': null,
        'regionName': 'Norte',
        'selectedGateways': const [],
      });

      final scenario = detailWithoutName.toSimulationScenario();
      expect(detailWithoutName.displayName, 'Cenário 15');
      expect(scenario.name, isNull);
      expect(scenario.parameters.feederName, 'Cenário 15');
    });
  });

  group('ScenarioResultsScreen Salvar Cenário', () {
    Future<void> pumpResults(
      WidgetTester tester, {
      required SimulationScenario scenario,
      required SavedScenarioService savedService,
    }) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ScenarioResultsScreen(
            scenario: scenario,
            savedScenarioService: savedService,
            storageService: ScenarioStorageService(),
            enableMapTiles: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('envia o nome informado ao backend ao salvar cenário e atualiza exibição', (tester) async {
      final service = _RecordingSavedScenarioService();
      await pumpResults(
        tester,
        scenario: _buildScenario(id: '42', name: 'Cenário 2026-11-11 10:00'),
        savedService: service,
      );

      await tester.tap(find.text('Salvar Cenário'));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextFormField).first;
      final regionField = find.byType(TextFormField).last;
      await tester.enterText(nameField, 'Cenário Subestação Norte');
      await tester.enterText(regionField, 'Regional Norte');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(service.updateCalls, [
        {
          'id': 42,
          'name': 'Cenário Subestação Norte',
          'regionName': 'Regional Norte',
        },
      ]);
      expect(find.text('Cenário Subestação Norte'), findsOneWidget);
      expect(
        find.text('Cenário "Cenário Subestação Norte" salvo na região "Regional Norte"!'),
        findsOneWidget,
      );
    });

    testWidgets('exibe erro e não confirma salvamento quando o servidor falha', (tester) async {
      final service = _RecordingSavedScenarioService()
        ..errorToThrow = const SavedScenarioException('Falha ao atualizar cenário');
      await pumpResults(
        tester,
        scenario: _buildScenario(id: '42', name: 'Nome Antigo'),
        savedService: service,
      );

      await tester.tap(find.text('Salvar Cenário'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'Nome Novo');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(service.updateCalls, hasLength(1));
      expect(find.text('Falha ao atualizar cenário'), findsOneWidget);
      expect(find.text('Nome Antigo'), findsOneWidget);
      expect(find.text('Nome Novo'), findsNothing);
    });

    testWidgets('exibe valor padrão quando cenário revisitado não tem nome salvo', (tester) async {
      final service = _RecordingSavedScenarioService();
      await pumpResults(
        tester,
        scenario: _buildScenario(id: '77', name: null, feederName: ''),
        savedService: service,
      );

      expect(find.text('Cenário 77'), findsOneWidget);
    });
  });
}

