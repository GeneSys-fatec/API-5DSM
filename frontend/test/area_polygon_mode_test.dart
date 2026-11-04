import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/data/services/area_delimitation_service.dart';
import 'package:frontend/features/scenario_config/domain/models/area_delimitation_model.dart';
import 'package:frontend/features/scenario_config/presentation/controllers/area_delimitation_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Serviço cujo resultado só é liberado quando o teste manda, para simular uma busca lenta.
class _ControllableService extends AreaDelimitationService {
  final List<Completer<AreaDelimitationResult>> pending = [];
  int calls = 0;

  @override
  Future<List<List<double>>?> fetchBdgdBounds(String importId) async => null;

  @override
  Future<AreaDelimitationResult> evaluateArea(AreaDelimitationConfig config) {
    calls++;
    final completer = Completer<AreaDelimitationResult>();
    pending.add(completer);
    return completer.future;
  }
}

AreaDelimitationResult _resultWithCandidates(int count) {
  final candidates = [
    for (var i = 0; i < count; i++)
      CandidateAsset(
        id: 'POSTE::TESTE::$i',
        assetKey: 'POSTE::TESTE::$i',
        type: CandidateAssetType.poste,
        latitude: -10.9,
        longitude: -37.0,
      ),
  ];
  return AreaDelimitationResult(
    isValid: true,
    isRadiusExceeded: false,
    intersectsBoundary: false,
    boundaryOverlapPct: 0.0,
    candidates: candidates,
    countsByType: {
      for (final type in CandidateAssetType.values)
        type: candidates.where((c) => c.type == type).length,
    },
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AreaDelimitationController.resetSharedState();
  });

  test('trocar para poligono descarta o resultado da busca circular', () async {
    final service = _ControllableService();
    final controller = AreaDelimitationController(service: service);

    final circular = controller.evaluateArea();
    await Future<void>.delayed(Duration.zero); // deixa a busca chegar ao servico
    service.pending.single.complete(_resultWithCandidates(5));
    await circular;
    expect(controller.result?.candidates.length, 5);

    controller.setUseDrawnPolygon(true);

    expect(controller.result, isNull);
    expect(AreaDelimitationController.sharedResult, isNull);
    expect(service.calls, 1, reason: 'sem 3 pontos nao deve haver nova busca');
  });

  test('busca circular em andamento nao repoe candidatos depois da troca para poligono', () async {
    final service = _ControllableService();
    final controller = AreaDelimitationController(service: service);

    final circular = controller.evaluateArea();
    await Future<void>.delayed(Duration.zero); // deixa a busca chegar ao servico
    controller.setUseDrawnPolygon(true);

    // A busca lenta termina depois de o usuario ja estar no modo poligono.
    service.pending.single.complete(_resultWithCandidates(1891));
    await circular;

    expect(controller.result, isNull);
    expect(controller.isLoading, isFalse);
  });

  test('evaluateArea em modo poligono com menos de 3 pontos nao cai na busca circular', () async {
    final service = _ControllableService();
    final controller = AreaDelimitationController(service: service);

    controller.setUseDrawnPolygon(true);
    await controller.evaluateArea();

    expect(service.calls, 0);
    expect(controller.result, isNull);
  });

  test('remover ponto abaixo de 3 vertices limpa o resultado do poligono', () async {
    final service = _ControllableService();
    final controller = AreaDelimitationController(service: service);

    controller.setUseDrawnPolygon(true);
    controller.addPolygonPoint(-10.90, -37.00);
    controller.addPolygonPoint(-10.90, -37.01);
    controller.addPolygonPoint(-10.91, -37.00);
    controller.removePolygonPoint(2);

    expect(controller.result, isNull);
    // O debounce da busca do 3o ponto foi cancelado: nada e disparado.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    expect(service.calls, 0);
  });
}
