import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';

class ScenarioSummary {
  final int id;
  final String name;
  final String regionName;
  final double? coverageTargetPct;
  final int? maxGateways;
  final String? propagationModel;
  final String? status;
  final double? totalCoveragePct;
  final int? usedGatewayCount;
  final double? totalEstimatedCost;
  final DateTime? processedAt;

  const ScenarioSummary({
    required this.id,
    required this.name,
    required this.regionName,
    this.coverageTargetPct,
    this.maxGateways,
    this.propagationModel,
    this.status,
    this.totalCoveragePct,
    this.usedGatewayCount,
    this.totalEstimatedCost,
    this.processedAt,
  });

  factory ScenarioSummary.fromJson(Map<String, dynamic> json) {
    return ScenarioSummary(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      regionName: json['regionName'] as String? ?? '',
      coverageTargetPct: (json['coverageTargetPct'] as num?)?.toDouble(),
      maxGateways: (json['maxGateways'] as num?)?.toInt(),
      propagationModel: json['propagationModel'] as String?,
      status: json['status'] as String?,
      totalCoveragePct: (json['totalCoveragePct'] as num?)?.toDouble(),
      usedGatewayCount: (json['usedGatewayCount'] as num?)?.toInt(),
      totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
    );
  }
}

class SelectedGateway {
  final int? candidateId;
  final double? latitude;
  final double? longitude;
  final double? coverageRadiusMeters;
  final bool manuallyAdjusted;

  const SelectedGateway({
    this.candidateId,
    this.latitude,
    this.longitude,
    this.coverageRadiusMeters,
    this.manuallyAdjusted = false,
  });

  factory SelectedGateway.fromJson(Map<String, dynamic> json) {
    return SelectedGateway(
      candidateId: (json['candidateId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      coverageRadiusMeters: (json['coverageRadiusMeters'] as num?)?.toDouble(),
      manuallyAdjusted: json['manuallyAdjusted'] as bool? ?? false,
    );
  }
}

class ScenarioIndicator {
  final double? totalCoveragePct;
  final Map<String, double> coveragePctByAssetType;
  final int? usedGatewayCount;
  final double? totalEstimatedCost;
  final bool targetReached;

  const ScenarioIndicator({
    this.totalCoveragePct,
    this.coveragePctByAssetType = const {},
    this.usedGatewayCount,
    this.totalEstimatedCost,
    this.targetReached = false,
  });

  factory ScenarioIndicator.fromJson(Map<String, dynamic> json) {
    final rawCoverage = json['coveragePctByAssetType'] as Map<String, dynamic>? ?? const {};
    return ScenarioIndicator(
      totalCoveragePct: (json['totalCoveragePct'] as num?)?.toDouble(),
      coveragePctByAssetType: rawCoverage.map(
        (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0.0),
      ),
      usedGatewayCount: (json['usedGatewayCount'] as num?)?.toInt(),
      totalEstimatedCost: (json['totalEstimatedCost'] as num?)?.toDouble(),
      targetReached: json['targetReached'] as bool? ?? false,
    );
  }
}

class ScenarioRfParameters {
  final double? frequencyMhz;
  final double? transmitPowerDbm;
  final double? receiverSensitivityDbm;
  final double? antennaHeightM;
  final double? deviceHeightM;
  final double? antennaGainDbi;
  final double? systemLossDb;

  const ScenarioRfParameters({
    this.frequencyMhz,
    this.transmitPowerDbm,
    this.receiverSensitivityDbm,
    this.antennaHeightM,
    this.deviceHeightM,
    this.antennaGainDbi,
    this.systemLossDb,
  });

  factory ScenarioRfParameters.fromJson(Map<String, dynamic> json) {
    return ScenarioRfParameters(
      frequencyMhz: (json['frequencyMhz'] as num?)?.toDouble(),
      transmitPowerDbm: (json['transmitPowerDbm'] as num?)?.toDouble(),
      receiverSensitivityDbm: (json['receiverSensitivityDbm'] as num?)?.toDouble(),
      antennaHeightM: (json['antennaHeightM'] as num?)?.toDouble(),
      deviceHeightM: (json['deviceHeightM'] as num?)?.toDouble(),
      antennaGainDbi: (json['antennaGainDbi'] as num?)?.toDouble(),
      systemLossDb: (json['systemLossDb'] as num?)?.toDouble(),
    );
  }
}

class ScenarioDetail {
  final int id;
  final String name;
  final String regionName;
  final String? areaWkt;
  final double? coverageTargetPct;
  final int? maxGateways;
  final double? gatewayUnitCost;
  final String? propagationModel;
  final ScenarioRfParameters? rfParameter;
  final String? status;
  final int? processingTimeMs;
  final DateTime? processedAt;
  final List<SelectedGateway> selectedGateways;
  final ScenarioIndicator? indicator;

  const ScenarioDetail({
    required this.id,
    required this.name,
    required this.regionName,
    this.areaWkt,
    this.coverageTargetPct,
    this.maxGateways,
    this.gatewayUnitCost,
    this.propagationModel,
    this.rfParameter,
    this.status,
    this.processingTimeMs,
    this.processedAt,
    this.selectedGateways = const [],
    this.indicator,
  });

  factory ScenarioDetail.fromJson(Map<String, dynamic> json) {
    final rawGateways = json['selectedGateways'] as List<dynamic>? ?? const [];
    return ScenarioDetail(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
      regionName: json['regionName'] as String? ?? '',
      areaWkt: json['areaWkt'] as String?,
      coverageTargetPct: (json['coverageTargetPct'] as num?)?.toDouble(),
      maxGateways: (json['maxGateways'] as num?)?.toInt(),
      gatewayUnitCost: (json['gatewayUnitCost'] as num?)?.toDouble(),
      propagationModel: json['propagationModel'] as String?,
      rfParameter: json['rfParameter'] != null
          ? ScenarioRfParameters.fromJson(json['rfParameter'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String?,
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'] as String)
          : null,
      selectedGateways: rawGateways
          .map((e) => SelectedGateway.fromJson(e as Map<String, dynamic>))
          .toList(),
      indicator: json['indicator'] != null
          ? ScenarioIndicator.fromJson(json['indicator'] as Map<String, dynamic>)
          : null,
    );
  }

  SimulationScenario toSimulationScenario() {
    final rf = rfParameter;
    final gateways = selectedGateways
        .where((g) => g.latitude != null && g.longitude != null)
        .toList();

    final centerLat = gateways.isEmpty
        ? 0.0
        : gateways.map((g) => g.latitude!).reduce((a, b) => a + b) / gateways.length;
    final centerLng = gateways.isEmpty
        ? 0.0
        : gateways.map((g) => g.longitude!).reduce((a, b) => a + b) / gateways.length;

    return SimulationScenario(
      id: id.toString(),
      code: name,
      region: regionName,
      centerLat: centerLat,
      centerLng: centerLng,
      executedAt: processedAt ?? DateTime.now(),
      parameters: ScenarioParameters(
        feederName: name,
        gatewayCount: indicator?.usedGatewayCount ?? gateways.length,
        txPowerDbm: rf?.transmitPowerDbm ?? 21.0,
        propagationModel: propagationModel ?? '',
      ),
      results: ScenarioResults(
        coveragePercent: indicator?.totalCoveragePct ?? 0.0,
        connectedAssets: 0,
        totalAssets: 0,
        implementationCost: indicator?.totalEstimatedCost ?? 0.0,
        avgRssiDbm: rf?.receiverSensitivityDbm ?? -120.0,
        gateways: gateways
            .asMap()
            .entries
            .map(
              (entry) => GatewayPoint(
                id: 'GW-${entry.value.candidateId ?? entry.key + 1}',
                posteId: 'Candidato ${entry.value.candidateId ?? entry.key + 1}',
                lat: entry.value.latitude!,
                lng: entry.value.longitude!,
                antennaHeight: rf?.antennaHeightM ?? 6.0,
                txPowerDbm: rf?.transmitPowerDbm ?? 21.0,
                linkedAssets: 0,
                avgFadeMarginDb: rf?.systemLossDb ?? 0.0,
                coverageRadiusMeters: entry.value.coverageRadiusMeters ?? 0.0,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ScenarioComparisonResponse {
  final List<ScenarioSummary> scenarios;
  final Map<String, dynamic> comparisonIndicators;

  const ScenarioComparisonResponse({
    this.scenarios = const [],
    this.comparisonIndicators = const {},
  });

  factory ScenarioComparisonResponse.fromJson(Map<String, dynamic> json) {
    final rawScenarios = json['scenarios'] as List<dynamic>? ?? const [];
    return ScenarioComparisonResponse(
      scenarios: rawScenarios
          .map((e) => ScenarioSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      comparisonIndicators:
          (json['comparisonIndicators'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
