import 'dart:convert';

enum CandidateAssetType {
  poste,
  trafo,
  religador,
  subestacao,
}

extension CandidateAssetTypeExt on CandidateAssetType {
  String get label {
    switch (this) {
      case CandidateAssetType.poste:
        return 'Postes de Média Tensão';
      case CandidateAssetType.trafo:
        return 'Transformadores MT/BT';
      case CandidateAssetType.religador:
        return 'Religadores e Chaves';
      case CandidateAssetType.subestacao:
        return 'Subestações Elétricas';
    }
  }

  String get code {
    switch (this) {
      case CandidateAssetType.poste:
        return 'PONNOT';
      case CandidateAssetType.trafo:
        return 'UNTRMT';
      case CandidateAssetType.religador:
        return 'UNREMT';
      case CandidateAssetType.subestacao:
        return 'SUB';
    }
  }
}

class CandidateAsset {
  final String id;
  final String assetKey;
  final CandidateAssetType type;
  final double latitude;
  final double longitude;
  final double voltageKv;
  final double distanceMeters;
  final double poleHeightM;
  final String losVisada;
  final String bdgdId;

  const CandidateAsset({
    required this.id,
    required this.assetKey,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.voltageKv = 13.8,
    this.distanceMeters = 0.0,
    this.poleHeightM = 12.0,
    this.losVisada = '360° Livre',
    this.bdgdId = '#448910',
  });

  CandidateAsset copyWith({
    String? id,
    String? assetKey,
    CandidateAssetType? type,
    double? latitude,
    double? longitude,
    double? voltageKv,
    double? distanceMeters,
    double? poleHeightM,
    String? losVisada,
    String? bdgdId,
  }) {
    return CandidateAsset(
      id: id ?? this.id,
      assetKey: assetKey ?? this.assetKey,
      type: type ?? this.type,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      voltageKv: voltageKv ?? this.voltageKv,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      poleHeightM: poleHeightM ?? this.poleHeightM,
      losVisada: losVisada ?? this.losVisada,
      bdgdId: bdgdId ?? this.bdgdId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assetKey': assetKey,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'voltageKv': voltageKv,
      'distanceMeters': distanceMeters,
      'poleHeightM': poleHeightM,
      'losVisada': losVisada,
      'bdgdId': bdgdId,
    };
  }

  factory CandidateAsset.fromMap(Map<String, dynamic> map) {
    CandidateAssetType parsedType = CandidateAssetType.poste;
    final typeStr = map['type'] as String? ?? '';
    for (final t in CandidateAssetType.values) {
      if (t.name == typeStr) {
        parsedType = t;
        break;
      }
    }
    return CandidateAsset(
      id: map['id'] as String? ?? '',
      assetKey: map['assetKey'] as String? ?? '',
      type: parsedType,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      voltageKv: (map['voltageKv'] as num?)?.toDouble() ?? 13.8,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      poleHeightM: (map['poleHeightM'] as num?)?.toDouble() ?? 12.0,
      losVisada: map['losVisada'] as String? ?? '360° Livre',
      bdgdId: map['bdgdId'] as String? ?? '',
    );
  }
}

class AreaDelimitationConfig {
  final double centerLatitude;
  final double centerLongitude;
  final String address;
  final double radiusKm;
  final bool isUnitKm;
  final bool defineClickingOnMap;
  final Set<CandidateAssetType> selectedAssetTypes;
  final String baseName;

  const AreaDelimitationConfig({
    this.centerLatitude = -22.9068,
    this.centerLongitude = -47.0616,
    this.address = 'Av. Pres. Kennedy, Campinas - SP',
    this.radiusKm = 3.5,
    this.isUnitKm = true,
    this.defineClickingOnMap = false,
    this.selectedAssetTypes = const {
      CandidateAssetType.poste,
      CandidateAssetType.trafo,
      CandidateAssetType.religador,
      CandidateAssetType.subestacao,
    },
    this.baseName = 'ENERGISA (SUL / SE)',
  });

  double get radiusMeters => radiusKm * 1000.0;

  AreaDelimitationConfig copyWith({
    double? centerLatitude,
    double? centerLongitude,
    String? address,
    double? radiusKm,
    bool? isUnitKm,
    bool? defineClickingOnMap,
    Set<CandidateAssetType>? selectedAssetTypes,
    String? baseName,
  }) {
    return AreaDelimitationConfig(
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      address: address ?? this.address,
      radiusKm: radiusKm ?? this.radiusKm,
      isUnitKm: isUnitKm ?? this.isUnitKm,
      defineClickingOnMap: defineClickingOnMap ?? this.defineClickingOnMap,
      selectedAssetTypes: selectedAssetTypes ?? this.selectedAssetTypes,
      baseName: baseName ?? this.baseName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centerLatitude': centerLatitude,
      'centerLongitude': centerLongitude,
      'address': address,
      'radiusKm': radiusKm,
      'isUnitKm': isUnitKm,
      'defineClickingOnMap': defineClickingOnMap,
      'selectedAssetTypes': selectedAssetTypes.map((t) => t.name).toList(),
      'baseName': baseName,
    };
  }

  String toJson() => json.encode(toMap());

  factory AreaDelimitationConfig.fromMap(Map<String, dynamic> map) {
    final rawTypes = map['selectedAssetTypes'] as List<dynamic>? ?? [];
    final types = <CandidateAssetType>{};
    for (final raw in rawTypes) {
      for (final t in CandidateAssetType.values) {
        if (t.name == raw) {
          types.add(t);
          break;
        }
      }
    }
    if (types.isEmpty) {
      types.addAll(CandidateAssetType.values);
    }
    return AreaDelimitationConfig(
      centerLatitude: (map['centerLatitude'] as num?)?.toDouble() ?? -22.9068,
      centerLongitude: (map['centerLongitude'] as num?)?.toDouble() ?? -47.0616,
      address: map['address'] as String? ?? 'Av. Pres. Kennedy, Campinas - SP',
      radiusKm: (map['radiusKm'] as num?)?.toDouble() ?? 3.5,
      isUnitKm: map['isUnitKm'] as bool? ?? true,
      defineClickingOnMap: map['defineClickingOnMap'] as bool? ?? false,
      selectedAssetTypes: types,
      baseName: map['baseName'] as String? ?? 'ENERGISA (SUL / SE)',
    );
  }

  factory AreaDelimitationConfig.fromJson(String source) =>
      AreaDelimitationConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

class AreaDelimitationResult {
  final bool isValid;
  final double maxAllowedRadiusKm;
  final bool isRadiusExceeded;
  final bool intersectsBoundary;
  final double boundaryOverlapPct;
  final List<CandidateAsset> candidates;
  final Map<CandidateAssetType, int> countsByType;

  const AreaDelimitationResult({
    required this.isValid,
    this.maxAllowedRadiusKm = 8.0,
    required this.isRadiusExceeded,
    required this.intersectsBoundary,
    required this.boundaryOverlapPct,
    required this.candidates,
    required this.countsByType,
  });

  int get totalCandidates => candidates.length;

  int countFor(CandidateAssetType type) => countsByType[type] ?? 0;

  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'maxAllowedRadiusKm': maxAllowedRadiusKm,
      'isRadiusExceeded': isRadiusExceeded,
      'intersectsBoundary': intersectsBoundary,
      'boundaryOverlapPct': boundaryOverlapPct,
      'candidates': candidates.map((c) => c.toMap()).toList(),
      'countsByType': countsByType.map((k, v) => MapEntry(k.name, v)),
    };
  }

  String toJson() => json.encode(toMap());

  factory AreaDelimitationResult.fromMap(Map<String, dynamic> map) {
    final rawCandidates = map['candidates'] as List<dynamic>? ?? [];
    final candidatesList = rawCandidates
        .map((c) => CandidateAsset.fromMap(c as Map<String, dynamic>))
        .toList();

    final rawCounts = map['countsByType'] as Map<String, dynamic>? ?? {};
    final counts = <CandidateAssetType, int>{};
    for (final t in CandidateAssetType.values) {
      counts[t] = (rawCounts[t.name] as num?)?.toInt() ?? 0;
    }

    return AreaDelimitationResult(
      isValid: map['isValid'] as bool? ?? true,
      maxAllowedRadiusKm: (map['maxAllowedRadiusKm'] as num?)?.toDouble() ?? 8.0,
      isRadiusExceeded: map['isRadiusExceeded'] as bool? ?? false,
      intersectsBoundary: map['intersectsBoundary'] as bool? ?? false,
      boundaryOverlapPct: (map['boundaryOverlapPct'] as num?)?.toDouble() ?? 0.0,
      candidates: candidatesList,
      countsByType: counts,
    );
  }

  factory AreaDelimitationResult.fromJson(String source) =>
      AreaDelimitationResult.fromMap(json.decode(source) as Map<String, dynamic>);
}
