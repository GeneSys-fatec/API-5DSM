import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_history/data/models/scenario_models.dart';
import 'package:frontend/features/scenario_results/data/services/scenario_report_service.dart';

void main() {
  Map<String, dynamic> detailJson({String? propagationModel}) => {
        'id': 5,
        'name': 'Cenário histórico',
        'regionName': 'ANATEL (Norte)',
        'coverageTargetPct': 95.0,
        'maxGateways': 12,
        if (propagationModel != null) 'propagationModel': propagationModel,
        'rfParameter': {
          'frequencyMhz': 915.0,
          'transmitPowerDbm': 21.0,
          'receiverSensitivityDbm': -120.0,
          'antennaHeightM': 6.0,
          'deviceHeightM': 5.0,
          'systemLossDb': 14.0,
        },
        'selectedGateways': [
          {'candidateId': 1, 'latitude': -10.9, 'longitude': -37.0, 'coverageRadiusMeters': 500.0},
        ],
        'indicator': {'totalCoveragePct': 66.7, 'usedGatewayCount': 1, 'totalEstimatedCost': 1500.0},
        'assets': [
          {'assetKey': 'A', 'type': 'POSTE', 'latitude': -10.9, 'longitude': -37.0, 'covered': true},
          {'assetKey': 'B', 'type': 'POSTE', 'latitude': -10.9, 'longitude': -37.1, 'covered': false},
        ],
      };

  test('cenario reaberto do historico sem modelo nao envia propagationModel vazio', () {
    final scenario =
        ScenarioDetail.fromJson(detailJson()).toSimulationScenario();
    expect(scenario.parameters.propagationModel, isEmpty);

    final payload = ScenarioReportService.buildReportPayload(
      scenario: scenario,
      mapImageBase64: 'abc',
    );

    // O backend exige o modelo (@NotBlank): vazio faria o relatorio ser rejeitado com 400.
    expect(payload['propagationModel'], isNotEmpty);
    expect(payload['propagationModel'], 'Não informado');
  });

  test('payload usa o modelo real quando ele existe e os totais batem', () {
    final scenario = ScenarioDetail.fromJson(
      detailJson(propagationModel: 'ITM_LONGLEY_RICE'),
    ).toSimulationScenario();

    final payload = ScenarioReportService.buildReportPayload(
      scenario: scenario,
      mapImageBase64: 'abc',
    );

    expect(payload['propagationModel'], 'ITM_LONGLEY_RICE');
    expect(payload['totalAssetCount'], 2);
    expect(payload['connectedAssetCount'], 1);
    expect(payload['shadowedAssetCount'], 1);
    expect(payload['mapImageBase64'], 'abc');
    expect(payload['frequencyMhz'], 915.0);
    expect(payload['maxGateways'], 12);
  });
}
