import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/core/constants/api_config.dart';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';
import 'report_file_saver.dart';

class ScenarioReportService {
  Future<bool> exportReport({
    required SimulationScenario scenario,
    required Uint8List mapImageBytes,
  }) async {
    final scenarioId = int.tryParse(scenario.id);
    if (scenarioId == null || scenarioId <= 0) {
      throw const ScenarioReportException(
        'O identificador deste cenário não é válido para exportação.',
      );
    }
    if (mapImageBytes.isEmpty) {
      throw const ScenarioReportException('Não foi possível capturar o mapa.');
    }

    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('auth_token');
    if (token == null || token.isEmpty) {
      throw const ScenarioReportException(
        'Sessão expirada. Faça login novamente.',
      );
    }

    final parameters = scenario.parameters;
    final results = scenario.results;
    final response = await http
        .post(
          Uri.parse('${ApiConfig.baseUrl}/simulations/$scenarioId/report'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/pdf, application/json',
          },
          body: jsonEncode({
            'scenarioName': scenario.name ?? parameters.feederName,
            'regionName': scenario.region,
            'mapImageBase64': base64Encode(mapImageBytes),
            'propagationModel': parameters.propagationModel,
            'frequencyMhz': parameters.frequencyMhz,
            'txPowerDbm': parameters.txPowerDbm,
            'antennaGainDbi': parameters.antennaGainDbi,
            'receiverSensitivityDbm': parameters.receiverSensitivityDbm,
            'antennaHeightM': parameters.antennaHeightM,
            'deviceHeightM': parameters.deviceHeightM,
            'systemLossDb': parameters.systemLossDb,
            'coverageTargetPct': parameters.coverageTargetPct,
            'maxGateways': parameters.maxGateways,
            'totalCoveragePct': results.coveragePercent,
            'gatewayCount': parameters.gatewayCount,
            'totalAssetCount': results.totalAssets,
            'connectedAssetCount': results.connectedAssets,
            'shadowedAssetCount': results.assetsInShadow,
            'totalEstimatedCost': results.implementationCost,
            'averageRssiDbm': results.avgRssiDbm,
            'gatewayUnitCost': parameters.gatewayUnitCost,
            'searchRadiusMeters': scenario.searchRadiusMeters > 0
                ? scenario.searchRadiusMeters
                : null,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200 ||
        response.headers['content-type']?.contains('application/pdf') != true) {
      var message = 'Falha ao gerar o relatório (HTTP ${response.statusCode}).';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map<String, dynamic>) {
          message =
              body['error'] as String? ?? body['message'] as String? ?? message;
        }
      } on FormatException {
  
      }
      throw ScenarioReportException(message);
    }

    return saveReportFile(
      response.bodyBytes,
      'cenario-${scenario.id}-relatorio.pdf',
    );
  }
}

class ScenarioReportException implements Exception {
  final String message;

  const ScenarioReportException(this.message);

  @override
  String toString() => message;
}
