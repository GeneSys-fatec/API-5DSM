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
}

class AreaDelimitationConfig {
  final double centerLatitude;
  final double centerLongitude;
  final String address;
  final double radiusKm;
  final bool isUnitKm;
  final bool defineClickingOnMap;
  final Set<CandidateAssetType> selectedAssetTypes;

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
  }) {
    return AreaDelimitationConfig(
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      address: address ?? this.address,
      radiusKm: radiusKm ?? this.radiusKm,
      isUnitKm: isUnitKm ?? this.isUnitKm,
      defineClickingOnMap: defineClickingOnMap ?? this.defineClickingOnMap,
      selectedAssetTypes: selectedAssetTypes ?? this.selectedAssetTypes,
    );
  }
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
}
