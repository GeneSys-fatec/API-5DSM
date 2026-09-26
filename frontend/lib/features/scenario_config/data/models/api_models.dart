import 'dart:convert';
import 'package:frontend/features/scenario_history/models/scenario_history_models.dart';

class SearchAreaRequest {
  final double latitude;
  final double longitude;
  final double radius;

  const SearchAreaRequest({
    required this.latitude,
    required this.longitude,
    required this.radius,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  String toJson() => json.encode(toMap());

  factory SearchAreaRequest.fromMap(Map<String, dynamic> map) {
    return SearchAreaRequest(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      radius: (map['radius'] as num).toDouble(),
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

  const SearchAreaResponse({
    required this.candidates,
    required this.validationStatus,
    required this.message,
  });

  factory SearchAreaResponse.fromMap(Map<String, dynamic> map) {
    final candidatesList = map['candidates'] as List<dynamic>? ?? [];
    return SearchAreaResponse(
      candidates: candidatesList
          .map((e) => AssetDto.fromMap(e as Map<String, dynamic>))
          .toList(),
      validationStatus: map['validationStatus'] as String? ?? '',
      message: map['message'] as String? ?? '',
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
  final String name;
  final String regionName;
  final double coverageTargetPct;
  final int maxGateways;
  final List<GatewayCandidateRequest> gatewayCandidates;
  final String propagationModel;
  final double? gatewayUnitCost;
  final RfParameterRequest rfParameter;

  const SimulationRequest({
    required this.name,
    required this.regionName,
    required this.coverageTargetPct,
    required this.maxGateways,
    required this.gatewayCandidates,
    required this.propagationModel,
    this.gatewayUnitCost,
    required this.rfParameter,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'regionName': regionName,
      'coverageTargetPct': coverageTargetPct,
      'maxGateways': maxGateways,
      'gatewayCandidates': gatewayCandidates.map((e) => e.toMap()).toList(),
      'propagationModel': propagationModel,
      if (gatewayUnitCost != null) 'gatewayUnitCost': gatewayUnitCost,
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

  const SelectedGatewayResponse({
    required this.candidateId,
    required this.latitude,
    required this.longitude,
    required this.coverageRadiusMeters,
  });

  factory SelectedGatewayResponse.fromMap(Map<String, dynamic> map) {
    return SelectedGatewayResponse(
      candidateId: (map['candidateId'] as num).toInt(),
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      coverageRadiusMeters: (map['coverageRadiusMeters'] as num).toDouble(),
    );
  }
}

class SimulationResponse {
  final int scenarioId;
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

  const SimulationResponse({
    required this.scenarioId,
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
  });

  factory SimulationResponse.fromMap(Map<String, dynamic> map) {
    final gatewaysList = map['selectedGateways'] as List<dynamic>? ?? [];
    return SimulationResponse(
      scenarioId: (map['scenarioId'] as num).toInt(),
      status: map['status'] as String,
      propagationModel: map['propagationModel'] as String,
      rfParameter: Map<String, dynamic>.from(map['rfParameter'] as Map),
      selectedGateways: gatewaysList
          .map((e) => SelectedGatewayResponse.fromMap(e as Map<String, dynamic>))
          .toList(),
      totalCoveragePct: (map['totalCoveragePct'] as num).toDouble(),
      coveragePctByAssetType:
          Map<String, double>.from(map['coveragePctByAssetType'] as Map),
      coveredAssetKeys:
          List<String>.from(map['coveredAssetKeys'] as List? ?? []),
      uncoveredAssetKeys:
          List<String>.from(map['uncoveredAssetKeys'] as List? ?? []),
      usedGatewayCount: (map['usedGatewayCount'] as num).toInt(),
      totalEstimatedCost: (map['totalEstimatedCost'] as num).toDouble(),
      processingTimeMs: (map['processingTimeMs'] as num).toInt(),
      targetReached: map['targetReached'] as bool,
    );
  }

  factory SimulationResponse.fromJson(String source) =>
      SimulationResponse.fromMap(json.decode(source) as Map<String, dynamic>);

  SimulationScenario toSimulationScenario({
    required String centerLat,
    required String centerLng,
    required String regionName,
  }) {
    final gateways = selectedGateways.map((gw) {
      final candidateIndex = gw.candidateId - 1;
      final assetKey = candidateIndex >= 0 && candidateIndex < coveredAssetKeys.length
          ? coveredAssetKeys[candidateIndex]
          : 'GW-${gw.candidateId}';
      
      return GatewayPoint(
        id: 'GW-${gw.candidateId}',
        posteId: assetKey,
        lat: gw.latitude,
        lng: gw.longitude,
        antennaHeight: rfParameter['antennaHeightM'] as double? ?? 6.0,
        txPowerDbm: rfParameter['transmitPowerDbm'] as double? ?? 21.0,
        linkedAssets: (coveredAssetKeys.length / selectedGateways.length).round(),
        avgFadeMarginDb: rfParameter['systemLossDb'] as double? ?? 14.0,
        coverageRadiusMeters: gw.coverageRadiusMeters,
      );
    }).toList();

    final totalAssets = coveredAssetKeys.length + uncoveredAssetKeys.length;
    
    return SimulationScenario(
      id: scenarioId.toString(),
      code: 'SIM-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      region: regionName,
      centerLat: double.tryParse(centerLat) ?? -23.298,
      centerLng: double.tryParse(centerLng) ?? -45.952,
      executedAt: DateTime.now(),
      parameters: ScenarioParameters(
        feederName: regionName,
        gatewayCount: usedGatewayCount,
        txPowerDbm: rfParameter['transmitPowerDbm'] as double? ?? 21.0,
        propagationModel: propagationModel,
      ),
      results: ScenarioResults(
        coveragePercent: totalCoveragePct,
        connectedAssets: coveredAssetKeys.length,
        totalAssets: totalAssets,
        implementationCost: totalEstimatedCost,
        avgRssiDbm: (rfParameter['receiverSensitivityDbm'] as double? ?? -120.0).roundToDouble(),
        gateways: gateways,
      ),
    );
  }
}