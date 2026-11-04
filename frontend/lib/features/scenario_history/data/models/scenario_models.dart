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
  final int? linkedAssets;
  final String? assetKey;
  final String? coverageGeometryGeoJson;
  final int? coveredAssetCount;
  final double? averageRssiDbm;
  final double? averageLinkMarginDb;
  final List<String> shadowedAssetKeys;

  const SelectedGateway({
    this.candidateId,
    this.latitude,
    this.longitude,
    this.coverageRadiusMeters,
    this.manuallyAdjusted = false,
    this.linkedAssets,
    this.assetKey,
    this.coverageGeometryGeoJson,
    this.coveredAssetCount,
    this.averageRssiDbm,
    this.averageLinkMarginDb,
    this.shadowedAssetKeys = const [],
  });

  factory SelectedGateway.fromJson(Map<String, dynamic> json) {
    return SelectedGateway(
      candidateId: (json['candidateId'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      coverageRadiusMeters: (json['coverageRadiusMeters'] as num?)?.toDouble(),
      manuallyAdjusted: json['manuallyAdjusted'] as bool? ?? false,
      linkedAssets: (json['linkedAssets'] as num?)?.toInt(),
      assetKey: json['assetKey'] as String?,
      coverageGeometryGeoJson: json['coverageGeometryGeoJson'] as String?,
      coveredAssetCount: (json['coveredAssetCount'] as num?)?.toInt(),
      averageRssiDbm: (json['averageRssiDbm'] as num?)?.toDouble(),
      averageLinkMarginDb: (json['averageLinkMarginDb'] as num?)?.toDouble(),
      shadowedAssetKeys: List<String>.from(
        json['shadowedAssetKeys'] as List? ?? const [],
      ),
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
  final List<ScenarioDetailAsset> assets;
  final double? averageRssiDbm;

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
    this.assets = const [],
    this.averageRssiDbm,
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
      assets: (json['assets'] as List<dynamic>? ?? const [])
          .map((e) => ScenarioDetailAsset.fromJson(e as Map<String, dynamic>))
          .toList(),
      averageRssiDbm: (json['averageRssiDbm'] as num?)?.toDouble(),
    );
  }

  /// Converte o WKT `POLYGON((lon lat, lon lat, ...))` em vértices [lat, lng], sem repetir o ponto de fechamento.
  static List<List<double>> parsePolygonWkt(String? wkt) {
    if (wkt == null) return const [];
    final match = RegExp(r'POLYGON\s*\(\((.*)\)\)', caseSensitive: false).firstMatch(wkt);
    if (match == null) return const [];
    final points = <List<double>>[];
    for (final pair in match.group(1)!.split(',')) {
      final parts = pair.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final lng = double.tryParse(parts[0]);
      final lat = double.tryParse(parts[1]);
      if (lat == null || lng == null) continue;
      points.add([lat, lng]);
    }
    if (points.length > 1 &&
        points.first[0] == points.last[0] &&
        points.first[1] == points.last[1]) {
      points.removeLast();
    }
    return points.length >= 3 ? points : const [];
  }

  SimulationScenario toSimulationScenario() {
    final rf = rfParameter;
    final gateways = selectedGateways
        .where((g) => g.latitude != null && g.longitude != null)
        .toList();
    final searchPolygon = parsePolygonWkt(areaWkt);

    double average(Iterable<double> values) =>
        values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

    // Centro da área de busca: média dos vértices do polígono salvo; sem ele, média dos gateways.
    final centerLat = searchPolygon.isNotEmpty
        ? average(searchPolygon.map((p) => p[0]))
        : average(gateways.map((g) => g.latitude!));
    final centerLng = searchPolygon.isNotEmpty
        ? average(searchPolygon.map((p) => p[1]))
        : average(gateways.map((g) => g.longitude!));

    final connectedAssets = assets.where((a) => a.covered).length;

    return SimulationScenario(
      id: id.toString(),
      code: name,
      name: name,
      region: regionName,
      centerLat: centerLat,
      centerLng: centerLng,
      searchPolygon: searchPolygon,
      executedAt: processedAt ?? DateTime.now(),
      parameters: ScenarioParameters(
        feederName: name,
        gatewayCount: indicator?.usedGatewayCount ?? gateways.length,
        txPowerDbm: rf?.transmitPowerDbm ?? 21.0,
        propagationModel: propagationModel ?? '',
        frequencyMhz: rf?.frequencyMhz,
        receiverSensitivityDbm: rf?.receiverSensitivityDbm,
        antennaHeightM: rf?.antennaHeightM,
        deviceHeightM: rf?.deviceHeightM,
        antennaGainDbi: rf?.antennaGainDbi,
        systemLossDb: rf?.systemLossDb,
        coverageTargetPct: coverageTargetPct,
        maxGateways: maxGateways,
        gatewayUnitCost: gatewayUnitCost,
      ),
      results: ScenarioResults(
        coveragePercent: indicator?.totalCoveragePct ?? 0.0,
        connectedAssets: connectedAssets,
        totalAssets: assets.length,
        implementationCost: indicator?.totalEstimatedCost ?? 0.0,
        avgRssiDbm: averageRssiDbm,
        gateways: gateways
            .asMap()
            .entries
            .map(
              (entry) => GatewayPoint(
                id: 'GW-${entry.value.candidateId ?? entry.key + 1}',
                posteId: entry.value.assetKey ??
                    'Candidato ${entry.value.candidateId ?? entry.key + 1}',
                lat: entry.value.latitude!,
                lng: entry.value.longitude!,
                antennaHeight: rf?.antennaHeightM ?? 6.0,
                txPowerDbm: rf?.transmitPowerDbm ?? 21.0,
                linkedAssets:
                    entry.value.coveredAssetCount ?? entry.value.linkedAssets ?? 0,
                avgFadeMarginDb: entry.value.averageLinkMarginDb != null
                    ? (entry.value.averageLinkMarginDb! * 10).roundToDouble() / 10
                    : rf?.systemLossDb ?? 0.0,
                coverageRadiusMeters: entry.value.coverageRadiusMeters ?? 0.0,
                coverageGeometryGeoJson: entry.value.coverageGeometryGeoJson,
                shadowedAssetKeys: entry.value.shadowedAssetKeys,
              ),
            )
            .toList(),
        assets: assets
            .map(
              (asset) => AssetPoint(
                assetKey: asset.assetKey,
                lat: asset.latitude,
                lng: asset.longitude,
                covered: asset.covered,
                type: asset.type,
              ),
            )
            .toList(),
      ),
    );
  }
}

class ScenarioDetailAsset {
  final String assetKey;
  final String type;
  final double latitude;
  final double longitude;
  final bool covered;

  const ScenarioDetailAsset({
    required this.assetKey,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.covered,
  });

  factory ScenarioDetailAsset.fromJson(Map<String, dynamic> json) {
    return ScenarioDetailAsset(
      assetKey: json['assetKey'] as String? ?? '',
      type: json['type'] as String? ?? 'POSTE',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      covered: json['covered'] as bool? ?? false,
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
