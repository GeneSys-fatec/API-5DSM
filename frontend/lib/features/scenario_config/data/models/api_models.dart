import 'dart:convert';
import 'package:frontend/features/scenario_results/models/scenario_results_models.dart';

class SearchAreaRequest {
  final String importId;
  final double latitude;
  final double longitude;
  final double? radius;
  final List<List<double>>? polygonPoints;

  const SearchAreaRequest({
    required this.importId,
    required this.latitude,
    required this.longitude,
    this.radius,
    this.polygonPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'importId': importId,
      'latitude': latitude,
      'longitude': longitude,
      if (radius != null) 'radius': radius,
      if (polygonPoints != null)
        'polygonPoints': polygonPoints!
            .map((pair) => {'latitude': pair[0], 'longitude': pair[1]})
            .toList(),
    };
  }

  String toJson() => json.encode(toMap());

  factory SearchAreaRequest.fromMap(Map<String, dynamic> map) {
    return SearchAreaRequest(
      importId: map['importId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radius: (map['radius'] as num?)?.toDouble(),
      polygonPoints: (map['polygonPoints'] as List<dynamic>?)
          ?.map((p) => [
                ((p as Map<String, dynamic>)['latitude'] as num).toDouble(),
                (p['longitude'] as num).toDouble(),
              ])
          .toList(),
    );
  }

  factory SearchAreaRequest.fromJson(String source) =>
      SearchAreaRequest.fromMap(json.decode(source) as Map<String, dynamic>);
}
class AssetDto {
  final String id;
  final String type;
  final double latitude;
  final double longitude;

  const AssetDto({
    required this.id,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  factory AssetDto.fromMap(Map<String, dynamic> map) {
    return AssetDto(
      id: map['id'] as String,
      type: map['type'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }

  factory AssetDto.fromJson(String source) =>
      AssetDto.fromMap(json.decode(source) as Map<String, dynamic>);
}

class SearchAreaResponse {
  final List<AssetDto> candidates;
  final String validationStatus;
  final String message;
  final Map<String, dynamic>? boundaryGeometry;

  const SearchAreaResponse({
    required this.candidates,
    required this.validationStatus,
    required this.message,
    this.boundaryGeometry,
  });

  factory SearchAreaResponse.fromMap(Map<String, dynamic> map) {
    final candidatesList = map['candidates'] as List<dynamic>? ?? [];
    return SearchAreaResponse(
      candidates: candidatesList
          .map((e) => AssetDto.fromMap(e as Map<String, dynamic>))
          .toList(),
      validationStatus: map['validationStatus'] as String? ?? '',
      message: map['message'] as String? ?? '',
      boundaryGeometry: map['boundaryGeometry'] as Map<String, dynamic>?,
    );
  }

  factory SearchAreaResponse.fromJson(String source) =>
      SearchAreaResponse.fromMap(json.decode(source) as Map<String, dynamic>);
}

class GatewayCandidateRequest {
  final int id;
  final String? source;
  final String? assetKey;
  final double latitude;
  final double longitude;
  final double? estimatedCost;

  const GatewayCandidateRequest({
    required this.id,
    this.source,
    this.assetKey,
    required this.latitude,
    required this.longitude,
    this.estimatedCost,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (source != null) 'source': source,
      if (assetKey != null) 'assetKey': assetKey,
      'latitude': latitude,
      'longitude': longitude,
      if (estimatedCost != null) 'estimatedCost': estimatedCost,
    };
  }

  String toJson() => json.encode(toMap());
}

class RfParameterRequest {
  final double frequencyMhz;
  final double transmitPowerDbm;
  final double receiverSensitivityDbm;
  final double antennaHeightM;
  final double deviceHeightM;
  final double antennaGainDbi;
  final double systemLossDb;

  const RfParameterRequest({
    required this.frequencyMhz,
    required this.transmitPowerDbm,
    required this.receiverSensitivityDbm,
    required this.antennaHeightM,
    required this.deviceHeightM,
    required this.antennaGainDbi,
    required this.systemLossDb,
  });

  Map<String, dynamic> toMap() {
    return {
      'frequencyMhz': frequencyMhz,
      'transmitPowerDbm': transmitPowerDbm,
      'receiverSensitivityDbm': receiverSensitivityDbm,
      'antennaHeightM': antennaHeightM,
      'deviceHeightM': deviceHeightM,
      'antennaGainDbi': antennaGainDbi,
      'systemLossDb': systemLossDb,
    };
  }

  String toJson() => json.encode(toMap());
}

class SimulationRequest {
  final String importId;
  final String name;
  final String regionName;
  final double coverageTargetPct;
  final int maxGateways;
  final List<GatewayCandidateRequest> gatewayCandidates;
  final String propagationModel;
  final double? gatewayUnitCost;
  final double? searchCenterLatitude;
  final double? searchCenterLongitude;
  final double? searchRadiusMeters;
  final List<List<double>>? searchPolygonPoints;
  final RfParameterRequest rfParameter;

  const SimulationRequest({
    required this.importId,
    required this.name,
    required this.regionName,
    required this.coverageTargetPct,
    required this.maxGateways,
    required this.gatewayCandidates,
    required this.propagationModel,
    this.gatewayUnitCost,
    this.searchCenterLatitude,
    this.searchCenterLongitude,
    this.searchRadiusMeters,
    this.searchPolygonPoints,
    required this.rfParameter,
  });

  Map<String, dynamic> toMap() {
    return {
      'importId': importId,
      'name': name,
      'regionName': regionName,
      'coverageTargetPct': coverageTargetPct,
      'maxGateways': maxGateways,
      'gatewayCandidates': gatewayCandidates.map((e) => e.toMap()).toList(),
      'propagationModel': propagationModel,
      if (gatewayUnitCost != null) 'gatewayUnitCost': gatewayUnitCost,
      if (searchCenterLatitude != null &&
          searchCenterLongitude != null &&
          searchRadiusMeters != null) ...{
        'searchCenterLatitude': searchCenterLatitude,
        'searchCenterLongitude': searchCenterLongitude,
        'searchRadiusMeters': searchRadiusMeters,
      },
      if (searchPolygonPoints != null && searchPolygonPoints!.length >= 3)
        'searchPolygonPoints': searchPolygonPoints!
            .map((pair) => {'latitude': pair[0], 'longitude': pair[1]})
            .toList(),
      'frequencyMhz': rfParameter.frequencyMhz,
      'transmitPowerDbm': rfParameter.transmitPowerDbm,
      'receiverSensitivityDbm': rfParameter.receiverSensitivityDbm,
      'antennaHeightM': rfParameter.antennaHeightM,
      'deviceHeightM': rfParameter.deviceHeightM,
      'antennaGainDbi': rfParameter.antennaGainDbi,
      'systemLossDb': rfParameter.systemLossDb,
    };
  }

  String toJson() => json.encode(toMap());
}

class SelectedGatewayResponse {
  final int candidateId;
  final double latitude;
  final double longitude;
  final double coverageRadiusMeters;
  final String? address;
  final String? municipio;
  final String? coverageGeometryGeoJson;
  final List<String> shadowedAssetKeys;

  const SelectedGatewayResponse({
    required this.candidateId,
    required this.latitude,
    required this.longitude,
    required this.coverageRadiusMeters,
    this.address,
    this.municipio,
    this.coverageGeometryGeoJson,
    this.shadowedAssetKeys = const [],
  });

  factory SelectedGatewayResponse.fromMap(Map<String, dynamic> map) {
    return SelectedGatewayResponse(
      candidateId: (map['candidateId'] as num).toInt(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      coverageRadiusMeters: (map['coverageRadiusMeters'] as num).toDouble(),
      address: map['address'] as String? ?? map['endereco'] as String?,
      municipio: map['municipio'] as String? ?? map['cidade'] as String?,
      coverageGeometryGeoJson: map['coverageGeometryGeoJson'] as String?,
      shadowedAssetKeys: List<String>.from(
        map['shadowedAssetKeys'] as List? ?? const [],
      ),
    );
  }
}

class AssetLocationResponse {
  final String assetKey;
  final double latitude;
  final double longitude;
  final bool covered;

  const AssetLocationResponse({
    required this.assetKey,
    required this.latitude,
    required this.longitude,
    required this.covered,
  });

  factory AssetLocationResponse.fromMap(Map<String, dynamic> map) =>
      AssetLocationResponse(
        assetKey: map['assetKey'] as String? ?? '',
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        covered: map['covered'] as bool? ?? false,
      );
}

class SimulationResponse {
  final int scenarioId;
  final String? scenarioName;
  final String status;
  final String propagationModel;
  final Map<String, dynamic> rfParameter;
  final List<SelectedGatewayResponse> selectedGateways;
  final double totalCoveragePct;
  final Map<String, double> coveragePctByAssetType;
  final List<String> coveredAssetKeys;
  final List<String> uncoveredAssetKeys;
  final int usedGatewayCount;
  final double totalEstimatedCost;
  final int processingTimeMs;
  final bool targetReached;
  final double? averageRssiDbm;
  final double? gatewayUnitCost;
  final double? coverageTargetPct;
  final int? maxGateways;
  final List<AssetLocationResponse> assets;

  const SimulationResponse({
    required this.scenarioId,
    this.scenarioName,
    required this.status,
    required this.propagationModel,
    required this.rfParameter,
    required this.selectedGateways,
    required this.totalCoveragePct,
    required this.coveragePctByAssetType,
    required this.coveredAssetKeys,
    required this.uncoveredAssetKeys,
    required this.usedGatewayCount,
    required this.totalEstimatedCost,
    required this.processingTimeMs,
    required this.targetReached,
    this.averageRssiDbm,
    this.gatewayUnitCost,
    this.coverageTargetPct,
    this.maxGateways,
    this.assets = const [],
  });

  factory SimulationResponse.fromMap(Map<String, dynamic> map) {
    final gatewaysList = map['selectedGateways'] as List<dynamic>? ?? [];
    final assetsList = map['assets'] as List<dynamic>? ?? [];
    final coverageByType = map['coveragePctByAssetType'] as Map? ?? const {};
    return SimulationResponse(
      scenarioId: (map['scenarioId'] as num).toInt(),
      scenarioName: map['scenarioName'] as String?,
      status: map['status'] as String,
      propagationModel: map['propagationModel'] as String,
      rfParameter: Map<String, dynamic>.from(map['rfParameter'] as Map),
      selectedGateways: gatewaysList
          .map(
            (e) => SelectedGatewayResponse.fromMap(e as Map<String, dynamic>),
          )
          .toList(),
      totalCoveragePct: (map['totalCoveragePct'] as num).toDouble(),
      coveragePctByAssetType: coverageByType.map(
        (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
      ),
      coveredAssetKeys: List<String>.from(
        map['coveredAssetKeys'] as List? ?? [],
      ),
      uncoveredAssetKeys: List<String>.from(
        map['uncoveredAssetKeys'] as List? ?? [],
      ),
      usedGatewayCount: (map['usedGatewayCount'] as num).toInt(),
      totalEstimatedCost: (map['totalEstimatedCost'] as num).toDouble(),
      processingTimeMs: (map['processingTimeMs'] as num).toInt(),
      targetReached: map['targetReached'] as bool,
      averageRssiDbm: (map['averageRssiDbm'] as num?)?.toDouble(),
      gatewayUnitCost: (map['gatewayUnitCost'] as num?)?.toDouble(),
      coverageTargetPct: (map['coverageTargetPct'] as num?)?.toDouble(),
      maxGateways: (map['maxGateways'] as num?)?.toInt(),
      assets: assetsList
          .map(
            (asset) =>
                AssetLocationResponse.fromMap(asset as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  factory SimulationResponse.fromJson(String source) =>
      SimulationResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  SimulationScenario toSimulationScenario({
    required String centerLat,
    required String centerLng,
    required String regionName,
    double searchRadiusMeters = 0.0,
  }) {
    double rfNumber(String key, double fallback) {
      final value = rfParameter[key];
      return value is num ? value.toDouble() : fallback;
    }

    final gateways = selectedGateways.map((gw) {
      final candidateIndex = gw.candidateId - 1;
      final assetKey =
          candidateIndex >= 0 && candidateIndex < coveredAssetKeys.length
          ? coveredAssetKeys[candidateIndex]
          : 'GW-${gw.candidateId}';

      return GatewayPoint(
        id: 'GW-${gw.candidateId}',
        posteId: assetKey,
        lat: gw.latitude,
        lng: gw.longitude,
        antennaHeight: rfNumber('antennaHeightM', 6.0),
        txPowerDbm: rfNumber('transmitPowerDbm', 21.0),
        linkedAssets: selectedGateways.isEmpty
            ? 0
            : (coveredAssetKeys.length / selectedGateways.length).round(),
        avgFadeMarginDb: rfNumber('systemLossDb', 14.0),
        coverageRadiusMeters: gw.coverageRadiusMeters,
        address: gw.address,
        municipio: gw.municipio ?? (regionName.isNotEmpty ? regionName : null),
        coverageGeometryGeoJson: gw.coverageGeometryGeoJson,
        shadowedAssetKeys: gw.shadowedAssetKeys,
      );
    }).toList();

    final totalAssets = coveredAssetKeys.length + uncoveredAssetKeys.length;

    return SimulationScenario(
      id: scenarioId.toString(),
      name: scenarioName,
      code:
          'SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      region: regionName,
      centerLat:
          double.tryParse(centerLat) ??
          (selectedGateways.isNotEmpty
              ? selectedGateways.first.latitude
              : -22.9068),
      centerLng:
          double.tryParse(centerLng) ??
          (selectedGateways.isNotEmpty
              ? selectedGateways.first.longitude
              : -47.0616),
      searchRadiusMeters: searchRadiusMeters,
      executedAt: DateTime.now(),
      parameters: ScenarioParameters(
        feederName: regionName,
        gatewayCount: usedGatewayCount,
        txPowerDbm: rfNumber('transmitPowerDbm', 21.0),
        propagationModel: propagationModel,
        frequencyMhz: (rfParameter['frequencyMhz'] as num?)?.toDouble(),
        receiverSensitivityDbm: (rfParameter['receiverSensitivityDbm'] as num?)
            ?.toDouble(),
        antennaHeightM: (rfParameter['antennaHeightM'] as num?)?.toDouble(),
        deviceHeightM: (rfParameter['deviceHeightM'] as num?)?.toDouble(),
        antennaGainDbi: (rfParameter['antennaGainDbi'] as num?)?.toDouble(),
        systemLossDb: (rfParameter['systemLossDb'] as num?)?.toDouble(),
        coverageTargetPct: coverageTargetPct,
        maxGateways: maxGateways,
        gatewayUnitCost: gatewayUnitCost,
      ),
      results: ScenarioResults(
        coveragePercent: totalCoveragePct,
        connectedAssets: coveredAssetKeys.length,
        totalAssets: totalAssets,
        implementationCost: totalEstimatedCost,
        avgRssiDbm: averageRssiDbm,
        gateways: gateways,
        assets: assets
            .map(
              (asset) => AssetPoint(
                assetKey: asset.assetKey,
                lat: asset.latitude,
                lng: asset.longitude,
                covered: asset.covered,
              ),
            )
            .toList(),
      ),
    );
  }
}
