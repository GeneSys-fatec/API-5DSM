import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';
import 'package:frontend/features/scenario_history/data/services/saved_scenario_service.dart';
import 'package:frontend/features/scenario_history/presentation/controllers/scenario_history_controller.dart';
import 'package:frontend/features/scenario_history/presentation/screens/history_screen.dart';

class FakeSavedScenarioService implements SavedScenarioService {
  List<ScenarioSummary> scenarios;
  Object? listError;
  String? filterUsed;
  final List<int> deletedIds = [];
  final List<String> duplicatedNames = [];

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
    if (listError != null) throw listError!;
    return ScenarioDetail.fromJson({
      'id': id,
      'name': 'Cenário Centro',
      'regionName': 'Centro',
      'coverageTargetPct': 90.0,
      'maxGateways': 5,
      'propagationModel': 'OKUMURA_HATA_SUBURBAN',
      'status': 'concluido',
      'processingTimeMs': 42,
      'processedAt': '2026-10-13T12:34:56Z',
      'selectedGateways': [
        {
          'candidateId': 1,
          'latitude': -22.9,
          'longitude': -47.1,
          'coverageRadiusMeters': 1850.0,
          'manuallyAdjusted': false,
        },
      ],
      'indicator': {
        'totalCoveragePct': 85.5,
        'coveragePctByAssetType': {'POSTE': 91.0},
        'usedGatewayCount': 1,
        'totalEstimatedCost': 1500.0,
        'targetReached': false,
      },
    });
  }

  @override
  Future<ScenarioSummary> duplicateScenario(int id, {String? name}) async {
    if (listError != null) throw listError!;
    duplicatedNames.add(name ?? '');
    final copy = ScenarioSummary.fromJson({
      'id': 999,
      'name': name ?? 'copia',
      'regionName': 'Centro',
      'coverageTargetPct': 90.0,
      'maxGateways': 5,
      'status': 'rascunho',
    });
    scenarios = [...scenarios, copy];
    return copy;
  }

  @override
  Future<void> deleteScenario(int id) async {
    if (listError != null) throw listError!;
    deletedIds.add(id);
    scenarios = scenarios.where((s) => s.id != id).toList();
  }
}

ScenarioSummary _summary({
  required int id,
  required String name,
  required String regionName,
  double? totalCoveragePct = 85.5,
}) {
  return ScenarioSummary.fromJson({
    'id': id,
    'name': name,
    'regionName': regionName,
    'coverageTargetPct': 90.0,
    'maxGateways': 5,
    'status': 'concluido',
    'totalCoveragePct': totalCoveragePct,
    'usedGatewayCount': 3,
    'totalEstimatedCost': 4500.0,
    'processedAt': '2026-10-13T12:34:56Z',
  });
}

void main() {
  Future<void> pump(WidgetTester tester, SavedScenarioService service) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final controller = ScenarioHistoryController(service: service);
    await tester.pumpWidget(
      MaterialApp(
        home: HistoryScreen(controller: controller, enableMapTiles: false),
      ),
    );
    await tester.pump();
  }

  testWidgets('exibe nome e regiao de cada cenario retornado pela API', (tester) async {
    await pump(
      tester,
      FakeSavedScenarioService(scenarios: [
        _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
        _summary(id: 2, name: 'Cenário Norte', regionName: 'Norte', totalCoveragePct: null),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cenário Centro'), findsOneWidget);
    expect(find.text('Centro'), findsOneWidget);
    expect(find.text('85.5% Cobertura'), findsOneWidget);

    expect(find.text('Cenário Norte'), findsOneWidget);
    expect(find.text('Norte'), findsOneWidget);
    expect(find.text('85.5% Cobertura'), findsNWidgets(1));
  });

  testWidgets('trata lista vazia retornada pela API', (tester) async {
    await pump(tester, FakeSavedScenarioService());
    await tester.pumpAndSettle();

    expect(find.text('Nenhum cenário salvo'), findsOneWidget);
    expect(find.text('Nova Simulação'), findsWidgets);
    expect(find.text('Ver Detalhes'), findsNothing);
  });

  testWidgets('exibe erro de requisicao e permite tentar novamente', (tester) async {
    final service = FakeSavedScenarioService(
      listError: const SavedScenarioException('Falha ao listar cenários'),
    );
    await pump(tester, service);
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível carregar os cenários'), findsOneWidget);
    expect(find.text('Falha ao listar cenários'), findsOneWidget);

    service.listError = null;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('Nenhum cenário salvo'), findsOneWidget);
  });

  testWidgets('filtra a listagem por regiao selecionada', (tester) async {
    final service = FakeSavedScenarioService(scenarios: [
      _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
      _summary(id: 2, name: 'Cenário Norte', regionName: 'Norte'),
    ]);
    await pump(tester, service);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Norte').last);
    await tester.pumpAndSettle();

    expect(service.filterUsed, 'Norte');
    expect(find.text('Cenário Norte'), findsOneWidget);
    expect(find.text('Cenário Centro'), findsNothing);
  });

  testWidgets('exclui o cenario apos confirmacao e atualiza a listagem', (tester) async {
    final service = FakeSavedScenarioService(scenarios: [
      _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
    ]);
    await pump(tester, service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir').first);
    await tester.pumpAndSettle();

    expect(find.text('Excluir Cenário'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(service.deletedIds, [1]);
    expect(find.text('Nenhum cenário salvo'), findsOneWidget);
    expect(find.text('Cenário excluído com sucesso.'), findsOneWidget);
  });

  testWidgets('cancela a exclusao quando o usuario desiste', (tester) async {
    final service = FakeSavedScenarioService(scenarios: [
      _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
    ]);
    await pump(tester, service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(service.deletedIds, isEmpty);
    expect(find.text('Cenário Centro'), findsOneWidget);
  });

  testWidgets('duplica o cenario com o nome informado e atualiza a listagem', (tester) async {
    final service = FakeSavedScenarioService(scenarios: [
      _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
    ]);
    await pump(tester, service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Duplicar').first);
    await tester.pumpAndSettle();

    expect(find.text('Duplicar Cenário'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Cenário Centro (cópia)');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Duplicar'));
    await tester.pumpAndSettle();

    expect(service.duplicatedNames, ['Cenário Centro (cópia)']);
    expect(find.text('Cenário Centro (cópia)'), findsOneWidget);
    expect(find.textContaining('duplicado com sucesso'), findsOneWidget);
  });

  testWidgets('abre os detalhes salvos sem reexecutar a simulacao', (tester) async {
    final service = FakeSavedScenarioService(scenarios: [
      _summary(id: 1, name: 'Cenário Centro', regionName: 'Centro'),
    ]);
    await pump(tester, service);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver Detalhes').first);
    await tester.pumpAndSettle();

    expect(find.text('Parâmetros do Cenário'), findsOneWidget);
    expect(find.text('Parâmetros RF'), findsOneWidget);
    expect(find.text('Resultados da Simulação'), findsOneWidget);
    expect(find.text('Gateways Selecionados (1)'), findsOneWidget);
    expect(find.text('85.5%'), findsWidgets);
    expect(find.text('POSTE'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Resultados da Simulação'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -200),
    );
    expect(find.text('Custo total estimado'.toUpperCase()), findsOneWidget);
    final currencyText = find
        .descendant(
          of: find.ancestor(
            of: find.text('Custo total estimado'.toUpperCase()),
            matching: find.byType(Column),
          ),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((e) => (e.widget as Text).data ?? '')
        .toList();
    expect(
      currencyText.any((t) => t.contains('1.500,00') || t.contains('1,500.00')),
      isTrue,
      reason: 'esperava o custo total estimado formatado, encontrado: $currencyText',
    );
  });
}
