import 'dart:convert';

class ScenarioConfigModel {
  final double frequencyMhz;
  final String frequencyPreset;
  final double txPowerDbm;
  final double rxSensitivityDbm;
  final double gatewayHeightM;
  final double deviceHeightM;
  final String propagationModel;

  final double minCoveragePercent;
  final double fadeMarginDb;
  final int maxGateways;

  final bool religadoresChecked;
  final bool transformadoresChecked;
  final bool medidoresChecked;

  const ScenarioConfigModel({
    this.frequencyMhz = 915.0,
    this.frequencyPreset = '915 MHz',
    this.txPowerDbm = 21.0,
    this.rxSensitivityDbm = -120.0,
    this.gatewayHeightM = 6.0,
    this.deviceHeightM = 5.0,
    this.propagationModel = 'Okumura-Hata Suburbano',
    this.minCoveragePercent = 95.0,
    this.fadeMarginDb = 14.0,
    this.maxGateways = 12,
    this.religadoresChecked = true,
    this.transformadoresChecked = true,
    this.medidoresChecked = true,
  });

  ScenarioConfigModel copyWith({
    double? frequencyMhz,
    String? frequencyPreset,
    double? txPowerDbm,
    double? rxSensitivityDbm,
    double? gatewayHeightM,
    double? deviceHeightM,
    String? propagationModel,
    double? minCoveragePercent,
    double? fadeMarginDb,
    int? maxGateways,
    bool? religadoresChecked,
    bool? transformadoresChecked,
    bool? medidoresChecked,
  }) {
    return ScenarioConfigModel(
      frequencyMhz: frequencyMhz ?? this.frequencyMhz,
      frequencyPreset: frequencyPreset ?? this.frequencyPreset,
      txPowerDbm: txPowerDbm ?? this.txPowerDbm,
      rxSensitivityDbm: rxSensitivityDbm ?? this.rxSensitivityDbm,
      gatewayHeightM: gatewayHeightM ?? this.gatewayHeightM,
      deviceHeightM: deviceHeightM ?? this.deviceHeightM,
      propagationModel: propagationModel ?? this.propagationModel,
      minCoveragePercent: minCoveragePercent ?? this.minCoveragePercent,
      fadeMarginDb: fadeMarginDb ?? this.fadeMarginDb,
      maxGateways: maxGateways ?? this.maxGateways,
      religadoresChecked: religadoresChecked ?? this.religadoresChecked,
      transformadoresChecked: transformadoresChecked ?? this.transformadoresChecked,
      medidoresChecked: medidoresChecked ?? this.medidoresChecked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'frequencyMhz': frequencyMhz,
      'frequencyPreset': frequencyPreset,
      'txPowerDbm': txPowerDbm,
      'rxSensitivityDbm': rxSensitivityDbm,
      'gatewayHeightM': gatewayHeightM,
      'deviceHeightM': deviceHeightM,
      'propagationModel': propagationModel,
      'minCoveragePercent': minCoveragePercent,
      'fadeMarginDb': fadeMarginDb,
      'maxGateways': maxGateways,
      'religadoresChecked': religadoresChecked,
      'transformadoresChecked': transformadoresChecked,
      'medidoresChecked': medidoresChecked,
    };
  }

  factory ScenarioConfigModel.fromMap(Map<String, dynamic> map) {
    return ScenarioConfigModel(
      frequencyMhz: (map['frequencyMhz'] as num?)?.toDouble() ?? 915.0,
      frequencyPreset: map['frequencyPreset'] as String? ?? '915 MHz',
      txPowerDbm: (map['txPowerDbm'] as num?)?.toDouble() ?? 21.0,
      rxSensitivityDbm: (map['rxSensitivityDbm'] as num?)?.toDouble() ?? -120.0,
      gatewayHeightM: (map['gatewayHeightM'] as num?)?.toDouble() ?? 6.0,
      deviceHeightM: (map['deviceHeightM'] as num?)?.toDouble() ?? 5.0,
      propagationModel: map['propagationModel'] as String? ?? 'Okumura-Hata Suburbano',
      minCoveragePercent: (map['minCoveragePercent'] as num?)?.toDouble() ?? 95.0,
      fadeMarginDb: (map['fadeMarginDb'] as num?)?.toDouble() ?? 14.0,
      maxGateways: (map['maxGateways'] as num?)?.toInt() ?? 12,
      religadoresChecked: map['religadoresChecked'] as bool? ?? true,
      transformadoresChecked: map['transformadoresChecked'] as bool? ?? true,
      medidoresChecked: map['medidoresChecked'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory ScenarioConfigModel.fromJson(String source) =>
      ScenarioConfigModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
