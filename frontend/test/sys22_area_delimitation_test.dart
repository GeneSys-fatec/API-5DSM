import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/area_delimitation_service.dart';
import 'package:frontend/features/scenario_config/domain/models/area_delimitation_model.dart';
import 'package:frontend/features/scenario_config/presentation/controllers/area_delimitation_controller.dart';
import 'package:frontend/features/scenario_config/presentation/screens/area_delimitation_screen.dart';

void main() {
  group('AreaDelimitation Domain & Service Tests', () {
    test('Configuracao padrao possui os valores corretos de Campinas e raio de 3.5 km', () {
      const config = AreaDelimitationConfig();
      expect(config.centerLatitude, -22.9068);
      expect(config.centerLongitude, -47.0616);
      expect(config.radiusKm, 3.5);
      expect(config.radiusMeters, 3500.0);
      expect(config.isUnitKm, true);
      expect(config.defineClickingOnMap, false);
      expect(config.selectedAssetTypes.length, 4);
    });

    test('AreaDelimitationService avalia raio valido e detecta interceptacao de borda em 3.5 km', () async {
      final service = AreaDelimitationService();
      const config = AreaDelimitationConfig(radiusKm: 3.5);

      final result = await service.evaluateArea(config);

      expect(result.isValid, true);
      expect(result.isRadiusExceeded, false);
      expect(result.intersectsBoundary, true);
      expect(result.boundaryOverlapPct, 12.0);
      expect(result.countFor(CandidateAssetType.poste), 342);
      expect(result.countFor(CandidateAssetType.trafo), 88);
      expect(result.countFor(CandidateAssetType.religador), 24);
      expect(result.countFor(CandidateAssetType.subestacao), 2);
    });

    test('AreaDelimitationService bloqueia raio quando excede o teto de 8.0 km', () async {
      final service = AreaDelimitationService();
      const config = AreaDelimitationConfig(radiusKm: 8.5);

      final result = await service.evaluateArea(config);

      expect(result.isValid, false);
      expect(result.isRadiusExceeded, true);
      expect(result.maxAllowedRadiusKm, 8.0);
    });
  });

  group('AreaDelimitationController State Tests', () {
    test('Atualiza coordenadas centrais e recalculada area', () async {
      final controller = AreaDelimitationController();
      await controller.init();

      expect(controller.config.centerLatitude, -22.9068);

      controller.setCenterCoordinates(-22.8500, -47.1000);

      expect(controller.config.centerLatitude, -22.8500);
      expect(controller.config.centerLongitude, -47.1000);
      expect(controller.result, isNotNull);
    });

    test('Alterna unidade entre km e metros mantendo integridade', () async {
      final controller = AreaDelimitationController();
      await controller.init();

      controller.toggleUnit(false);
      expect(controller.isUnitKm, false);

      controller.toggleUnit(true);
      expect(controller.isUnitKm, true);
    });

    test('Filtra candidatos ao desmarcar classes de ativos', () async {
      final controller = AreaDelimitationController();
      await controller.init();

      final initialCount = controller.filteredCandidates.length;
      expect(initialCount, greaterThan(0));

      controller.toggleAssetType(CandidateAssetType.poste);

      final countWithoutPoste = controller.filteredCandidates.length;
      expect(countWithoutPoste, lessThan(initialCount));

      controller.toggleAssetType(CandidateAssetType.poste);
      expect(controller.filteredCandidates.length, initialCount);
    });

    test('Valida canAdvance quando raio esta dentro ou fora do limite', () async {
      final controller = AreaDelimitationController();
      await controller.init();

      expect(controller.canAdvance, true);

      controller.setRadius(9.5, isUnitKm: true);
      await controller.evaluateArea();

      expect(controller.isRadiusExceeded, true);
      expect(controller.canAdvance, false);

      controller.setRadius(4.0, isUnitKm: true);
      await controller.evaluateArea();

      expect(controller.isRadiusExceeded, false);
      expect(controller.canAdvance, true);
    });
  });

  group('AreaDelimitationScreen Widget Tests', () {
    testWidgets('Renderiza Stepper, os tres cards principais e o mapa', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = AreaDelimitationController();
      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: AreaDelimitationScreen(
            controller: controller,
            enableMapTiles: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1. Delimitação de Área & Candidatos'), findsWidgets);
      expect(find.text('Ponto Central da Simulação'), findsOneWidget);
      expect(find.text('Raio da Área de Busca'), findsOneWidget);
      expect(find.text('Ativos Candidatos Identificados'), findsOneWidget);
      expect(find.text('Definir Clicando no Mapa'), findsOneWidget);
      expect(find.text('454 Locais'), findsOneWidget);
      expect(find.text('Voltar para Importação BDGD'), findsOneWidget);
      expect(find.text('Avançar para Etapa 2: Parâmetros de RF e Otimização'), findsOneWidget);
    });

    testWidgets('Exibe mensagem de erro e desabilita avanço quando raio excede 8 km', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = AreaDelimitationController();
      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: AreaDelimitationScreen(
            controller: controller,
            enableMapTiles: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final advanceButtonInitial = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Avançar para Etapa 2: Parâmetros de RF e Otimização'),
      );
      expect(advanceButtonInitial.onPressed, isNotNull);

      controller.setRadius(9.0, isUnitKm: true);
      await tester.pumpAndSettle();

      expect(find.textContaining('O raio ultrapassou 8.0 km'), findsOneWidget);

      final advanceButtonDisabled = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Avançar para Etapa 2: Parâmetros de RF e Otimização'),
      );
      expect(advanceButtonDisabled.onPressed, isNull);
    });
  });
}
