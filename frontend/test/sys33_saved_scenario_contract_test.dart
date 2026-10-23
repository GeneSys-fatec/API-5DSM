import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';

void main() {
  late List<dynamic> listPayload;
  late Map<String, dynamic> detailPayload;

  setUpAll(() {
    listPayload = jsonDecode(File('test/fixtures/scenarios_list.json').readAsStringSync()) as List<dynamic>;
    detailPayload = jsonDecode(File('test/fixtures/scenario_detail.json').readAsStringSync()) as Map<String, dynamic>;
  });

  test('ScenarioSummary le o payload real de GET /scenarios', () {
    final summaries = listPayload
        .map((e) => ScenarioSummary.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(summaries, isNotEmpty);
    for (final s in summaries) {
      expect(s.id, greaterThan(0));
      expect(s.name, isNotEmpty);
      expect(s.regionName, isNotNull);
    }
    expect(summaries.first.totalCoveragePct, isNotNull);
    expect(summaries.first.usedGatewayCount, isNotNull);
  });

  test('ScenarioDetail le o payload real de GET /scenarios/{id}', () {
    final detail = ScenarioDetail.fromJson(detailPayload);

    expect(detail.id, detailPayload['id']);
    expect(detail.name, detailPayload['name']);
    expect(detail.regionName, detailPayload['regionName']);
    expect(detail.propagationModel, detailPayload['propagationModel']);
    expect(detail.coverageTargetPct, detailPayload['coverageTargetPct']);
    expect(detail.rfParameter, isNotNull);
    expect(detail.rfParameter!.frequencyMhz, detailPayload['rfParameter']['frequencyMhz']);
    expect(detail.indicator, isNotNull);
    expect(detail.indicator!.totalCoveragePct, detailPayload['indicator']['totalCoveragePct']);
    expect(
      detail.indicator!.coveragePctByAssetType.keys.toSet(),
      (detailPayload['indicator']['coveragePctByAssetType'] as Map).keys.toSet(),
    );

    for (final gw in detail.selectedGateways) {
      expect(gw.candidateId, isNotNull);
      expect(gw.latitude, isNotNull);
      expect(gw.longitude, isNotNull);
    }
  });

  test('cenário salvo vira SimulationScenario utilizável pelo mapa', () {
    final scenario = ScenarioDetail.fromJson(detailPayload).toSimulationScenario();

    expect(scenario.id, detailPayload['id'].toString());
    expect(scenario.results.gateways, isNotEmpty);
    for (final gw in scenario.results.gateways) {
      expect(gw.lat, isA<double>());
      expect(gw.lng, isA<double>());
      expect(gw.coverageRadiusMeters, greaterThan(0));
    }
    expect(scenario.results.coveragePercent, greaterThan(0));
  });
}
