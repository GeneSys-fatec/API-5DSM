import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/area_delimitation_service.dart';
import 'package:frontend/features/scenario_config/domain/models/area_delimitation_model.dart';
import 'package:frontend/features/scenario_config/presentation/controllers/area_delimitation_controller.dart';
import 'package:frontend/features/scenario_config/presentation/screens/area_delimitation_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAreaDelimitationService extends AreaDelimitationService {
  @override
  Future<AreaDelimitationResult> evaluateArea(AreaDelimitationConfig config) async {
    final isExceeded = config.radiusKm > AreaDelimitationService.maxRadiusKm;
    if (isExceeded) {
      return const AreaDelimitationResult(
        isValid: false,
        isRadiusExceeded: true,
        intersectsBoundary: false,
        boundaryOverlapPct: 0.0,
        candidates: [],
        countsByType: {},
      );
    }
    final candidates = <CandidateAsset>[
      CandidateAsset(
        id: 'fake-poste-1',
        assetKey: 'FAKE-POSTE-01',
        type: CandidateAssetType.poste,
        latitude: config.centerLatitude,
        longitude: config.centerLongitude,
      ),
      CandidateAsset(
        id: 'fake-poste-2',
        assetKey: 'FAKE-POSTE-02',
        type: CandidateAssetType.poste,
        latitude: config.centerLatitude,
        longitude: config.centerLongitude,
      ),
      CandidateAsset(
        id: 'fake-trafo-1',
        assetKey: 'FAKE-TRAFO-01',
        type: CandidateAssetType.trafo,
        latitude: config.centerLatitude,
        longitude: config.centerLongitude,
      ),
      CandidateAsset(
        id: 'fake-sub-1',
        assetKey: 'FAKE-SUB-01',
        type: CandidateAssetType.subestacao,
        latitude: config.centerLatitude,
        longitude: config.centerLongitude,
      ),
    ];
    final counts = <CandidateAssetType, int>{
      for (final type in CandidateAssetType.values)
        type: candidates.where((c) => c.type == type).length,
    };
    return AreaDelimitationResult(
      isValid: true,
      isRadiusExceeded: false,
      intersectsBoundary: false,
      boundaryOverlapPct: 0.0,
      candidates: candidates,
      countsByType: counts,
    );
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AreaDelimitation Domain & Service Tests', () {
    test(
      'Configuracao padrao possui os valores corretos de Campinas e raio de 3.5 km',
      () {
        const config = AreaDelimitationConfig();
        expect(config.centerLatitude, -22.9068);
        expect(config.centerLongitude, -47.0616);
        expect(config.radiusKm, 3.5);
        expect(config.radiusMeters, 3500.0);
        expect(config.isUnitKm, true);
        expect(config.defineClickingOnMap, false);
        expect(config.selectedAssetTypes.length, 4);
        expect(config.bdgdImportId, isNull);
      },
    );

    test(
      'Serializa e restaura bdgdImportId via toMap/fromMap',
      () {
        const config = AreaDelimitationConfig(bdgdImportId: 'import-123');
        final restored = AreaDelimitationConfig.fromMap(config.toMap());

        expect(restored.bdgdImportId, 'import-123');
      },
    );

    test(
      'copyWith preserva bdgdImportId quando nao informado',
      () {
        const config = AreaDelimitationConfig(bdgdImportId: 'import-123');
        final updated = config.copyWith(radiusKm: 5.0);

        expect(updated.bdgdImportId, 'import-123');
        expect(updated.radiusKm, 5.0);
      },
    );

    test('isPointInsidePolygon detecta ponto dentro do poligono', () {
      final square = [
        const LatLng(0.0, 0.0),
        const LatLng(0.0, 10.0),
        const LatLng(10.0, 10.0),
        const LatLng(10.0, 0.0),
      ];

      expect(isPointInsidePolygon(5.0, 5.0, square), true);
    });

    test('isPointInsidePolygon detecta ponto fora do poligono', () {
      final square = [
        const LatLng(0.0, 0.0),
        const LatLng(0.0, 10.0),
        const LatLng(10.0, 10.0),
        const LatLng(10.0, 0.0),
      ];

      expect(isPointInsidePolygon(50.0, 50.0, square), false);
    });

    test('isPointInsidePolygon aceita qualquer ponto quando poligono e invalido', () {
      expect(isPointInsidePolygon(5.0, 5.0, const [LatLng(0.0, 0.0)]), true);
    });

    test(
      'AreaDelimitationService bloqueia raio quando excede o teto de 8.0 km',
      () async {
        final service = AreaDelimitationService();
        const config = AreaDelimitationConfig(radiusKm: 8.5);

        final result = await service.evaluateArea(config);

        expect(result.isValid, false);
        expect(result.isRadiusExceeded, true);
        expect(result.maxAllowedRadiusKm, 8.0);
      },
    );
  });

  group('AreaDelimitationController State Tests', () {
    test('Atualiza coordenadas centrais e recalculada area', () async {
      final controller = AreaDelimitationController(service: _FakeAreaDelimitationService());
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
      final controller = AreaDelimitationController(service: _FakeAreaDelimitationService());
      await controller.init();

      final initialCount = controller.filteredCandidates.length;
      expect(initialCount, greaterThan(0));

      controller.toggleAssetType(CandidateAssetType.poste);

      final countWithoutPoste = controller.filteredCandidates.length;
      expect(countWithoutPoste, lessThan(initialCount));

      controller.toggleAssetType(CandidateAssetType.poste);
      expect(controller.filteredCandidates.length, initialCount);
    });

    test(
      'Valida canAdvance quando raio esta dentro ou fora do limite',
      () async {
        final controller = AreaDelimitationController(service: _FakeAreaDelimitationService());
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
      },
    );

    test(
      'Preserva configuracao compartilhada entre instancias do controlador',
      () async {
        AreaDelimitationController.resetSharedState();
        final controller1 = AreaDelimitationController(service: _FakeAreaDelimitationService());
        await controller1.init();

        controller1.setRadius(5.5, isUnitKm: true);
        controller1.setCenterCoordinates(-22.8000, -47.2000);
        controller1.setAddressQuery('Rua Teste, 123');
        await controller1.evaluateArea();

        final controller2 = AreaDelimitationController();
        expect(controller2.config.radiusKm, 5.5);
        expect(controller2.config.centerLatitude, -22.8000);
        expect(controller2.config.centerLongitude, -47.2000);
        expect(controller2.config.address, 'Rua Teste, 123');
        expect(controller2.result, isNotNull);
      },
    );
  });

  group('AreaDelimitationScreen Widget Tests', () {
    testWidgets('Renderiza Stepper, os tres cards principais e o mapa', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = AreaDelimitationController(service: _FakeAreaDelimitationService());
      await controller.init();

      await tester.pumpWidget(
        MaterialApp(
          home: AreaDelimitationScreen(
            controller: controller,
            enableMapTiles: false,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1. Delimitação de Área & Candidatos'), findsWidgets);
      expect(find.text('Ponto Central da Simulação'), findsOneWidget);
      expect(find.text('Raio da Área de Busca'), findsOneWidget);
      expect(find.text('Ativos Candidatos Identificados'), findsOneWidget);
      expect(find.text('Definir Clicando no Mapa'), findsOneWidget);
      expect(find.textContaining('Locais'), findsOneWidget);
      expect(find.text('Voltar para Importação BDGD'), findsOneWidget);
      expect(
        find.text('Avançar para Etapa 2: Parâmetros de RF e Otimização'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Exibe mensagem de erro e desabilita avanço quando raio excede 8 km',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1024);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final controller = AreaDelimitationController(service: _FakeAreaDelimitationService());
        await controller.init();

        await tester.pumpWidget(
          MaterialApp(
            home: AreaDelimitationScreen(
              controller: controller,
              enableMapTiles: false,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final advanceButtonInitial = tester.widget<ElevatedButton>(
          find.widgetWithText(
            ElevatedButton,
            'Avançar para Etapa 2: Parâmetros de RF e Otimização',
          ),
        );
        expect(advanceButtonInitial.onPressed, isNotNull);

        controller.setRadius(9.0, isUnitKm: true);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.textContaining('O raio ultrapassou 8.0 km'),
          findsOneWidget,
        );

        final advanceButtonDisabled = tester.widget<ElevatedButton>(
          find.widgetWithText(
            ElevatedButton,
            'Avançar para Etapa 2: Parâmetros de RF e Otimização',
          ),
        );
        expect(advanceButtonDisabled.onPressed, isNull);
      },
    );
  });
}
