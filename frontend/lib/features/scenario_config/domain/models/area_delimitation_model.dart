import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

bool isPointInsidePolygon(double latitude, double longitude, List<LatLng> polygon) {
  if (polygon.length < 3) {
    return true;
  }
  bool inside = false;
  for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
    final latI = polygon[i].latitude;
    final lngI = polygon[i].longitude;
    final latJ = polygon[j].latitude;
    final lngJ = polygon[j].longitude;

    final intersects = (lngI > longitude) != (lngJ > longitude) &&
        (latitude < (latJ - latI) * (longitude - lngI) / (lngJ - lngI) + latI);
    if (intersects) {
      inside = !inside;
    }
  }
  return inside;
}

LatLng resolvePolygonCenter(List<LatLng> polygon) {
  assert(polygon.length >= 3);

  double signedArea = 0.0;
  double centroidLat = 0.0;
  double centroidLng = 0.0;
  for (var i = 0; i < polygon.length; i++) {
    final p0 = polygon[i];
    final p1 = polygon[(i + 1) % polygon.length];
    final cross = p0.longitude * p1.latitude - p1.longitude * p0.latitude;
    signedArea += cross;
    centroidLng += (p0.longitude + p1.longitude) * cross;
    centroidLat += (p0.latitude + p1.latitude) * cross;
  }
  signedArea *= 0.5;

  if (signedArea.abs() > 1e-12) {
    final centroid = LatLng(centroidLat / (6 * signedArea), centroidLng / (6 * signedArea));
    if (isPointInsidePolygon(centroid.latitude, centroid.longitude, polygon)) {
      return centroid;
    }
  }

  final avgLat = polygon.map((p) => p.latitude).reduce((a, b) => a + b) / polygon.length;
  final avgLng = polygon.map((p) => p.longitude).reduce((a, b) => a + b) / polygon.length;
  if (isPointInsidePolygon(avgLat, avgLng, polygon)) {
    return LatLng(avgLat, avgLng);
  }

  return polygon.first;
}

enum CandidateAssetType {
  poste,
  trafo,
  religador,
  subestacao,
  ucbt,
  ucmt,
  ssdbt,
  ssdmt,
  ssdat,
  uncrat,
  outros,
}

extension CandidateAssetTypeExt on CandidateAssetType {
  String get label {
    switch (this) {
      case CandidateAssetType.poste:
        return 'Postes de Média Tensão (PONNOT)';
      case CandidateAssetType.trafo:
        return 'Transformadores MT/BT (UNTRMT)';
      case CandidateAssetType.religador:
        return 'Religadores e Chaves (UNREMT)';
      case CandidateAssetType.subestacao:
        return 'Subestações Elétricas (SUB)';
      case CandidateAssetType.ucbt:
        return 'Consumidores BT (UCBT)';
      case CandidateAssetType.ucmt:
        return 'Consumidores MT (UCMT)';
      case CandidateAssetType.ssdmt:
        return 'Segmentos de Rede MT (SSDMT)';
      case CandidateAssetType.ssdbt:
        return 'Segmentos de Rede BT (SSDBT)';
      case CandidateAssetType.ssdat:
        return 'Segmentos de Rede AT (SSDAT)';
      case CandidateAssetType.uncrat:
        return 'Chaves e Religadores AT (UNCRAT)';
      case CandidateAssetType.outros:
        return 'Outros Ativos BDGD';
    }
  }

  String get shortLabel {
    switch (this) {
      case CandidateAssetType.poste:
        return 'Poste MT';
      case CandidateAssetType.trafo:
        return 'Trafo MT/BT';
      case CandidateAssetType.religador:
        return 'Religador';
      case CandidateAssetType.subestacao:
        return 'Subestação';
      case CandidateAssetType.ucbt:
        return 'Consumidor BT';
      case CandidateAssetType.ucmt:
        return 'Consumidor MT';
      case CandidateAssetType.ssdmt:
        return 'Segmento MT';
      case CandidateAssetType.ssdbt:
        return 'Segmento BT';
      case CandidateAssetType.ssdat:
        return 'Segmento AT';
      case CandidateAssetType.uncrat:
        return 'Chave AT';
      case CandidateAssetType.outros:
        return 'Outros';
    }
  }

  Color get color {
    switch (this) {
      case CandidateAssetType.poste:
        return const Color(0xFF7C3AED); // Primary purple
      case CandidateAssetType.trafo:
        return const Color(0xFFF59E0B); // Amber
      case CandidateAssetType.religador:
        return const Color(0xFF4F46E5); // Indigo
      case CandidateAssetType.subestacao:
        return const Color(0xFFDC2626); // Red
      case CandidateAssetType.ssdmt:
        return const Color(0xFF8B5CF6); // Purple / Violet
      case CandidateAssetType.ssdbt:
        return const Color(0xFF06B6D4); // Cyan
      case CandidateAssetType.ssdat:
        return const Color(0xFFEC4899); // Pink / Rose
      case CandidateAssetType.ucbt:
        return const Color(0xFF3B82F6); // Blue
      case CandidateAssetType.ucmt:
        return const Color(0xFFF97316); // Orange
      case CandidateAssetType.uncrat:
        return const Color(0xFF10B981); // Emerald
      case CandidateAssetType.outros:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData get icon {
    switch (this) {
      case CandidateAssetType.poste:
        return Icons.circle;
      case CandidateAssetType.trafo:
        return Icons.crop_square_rounded;
      case CandidateAssetType.religador:
        return Icons.crop_square_rounded;
      case CandidateAssetType.subestacao:
        return Icons.bolt_rounded;
      case CandidateAssetType.ssdmt:
        return Icons.show_chart_rounded;
      case CandidateAssetType.ssdbt:
        return Icons.timeline_rounded;
      case CandidateAssetType.ssdat:
        return Icons.electric_bolt_rounded;
      case CandidateAssetType.ucbt:
        return Icons.home_rounded;
      case CandidateAssetType.ucmt:
        return Icons.factory_rounded;
      case CandidateAssetType.uncrat:
        return Icons.tune_rounded;
      case CandidateAssetType.outros:
        return Icons.circle;
    }
  }

  String get code {
    switch (this) {
      case CandidateAssetType.poste:
        return 'POSTE';
      case CandidateAssetType.trafo:
        return 'TRAFO';
      case CandidateAssetType.religador:
        return 'RELIGADOR';
      case CandidateAssetType.subestacao:
        return 'SUB';
      case CandidateAssetType.ucbt:
        return 'UCBT';
      case CandidateAssetType.ucmt:
        return 'UCMT';
      case CandidateAssetType.ssdmt:
        return 'SSDMT';
      case CandidateAssetType.ssdbt:
        return 'SSDBT';
      case CandidateAssetType.ssdat:
        return 'SSDAT';
      case CandidateAssetType.uncrat:
        return 'UNCRAT';
      case CandidateAssetType.outros:
        return 'OUTROS';
    }
  }

  List<String> get allFilterCodes {
    switch (this) {
      case CandidateAssetType.poste:
        return const ['POSTE', 'PONNOT', 'POST'];
      case CandidateAssetType.trafo:
        return const ['TRAFO', 'UNTRMT', 'TRANSFORMADOR'];
      case CandidateAssetType.religador:
        return const ['RELIGADOR', 'UNREMT', 'RECLOSER'];
      case CandidateAssetType.subestacao:
        return const ['SUB', 'SUBESTACAO', 'SUBSTATION'];
      case CandidateAssetType.ucbt:
        return const ['UCBT'];
      case CandidateAssetType.ucmt:
        return const ['UCMT'];
      case CandidateAssetType.ssdmt:
        return const ['SSDMT'];
      case CandidateAssetType.ssdbt:
        return const ['SSDBT'];
      case CandidateAssetType.ssdat:
        return const ['SSDAT'];
      case CandidateAssetType.uncrat:
        return const ['UNCRAT'];
      case CandidateAssetType.outros:
        return const ['OUTROS'];
    }
  }

  static CandidateAssetType fromString(String raw) {
    final s = raw.trim().toUpperCase();
    if (s == 'PONNOT' || s == 'POSTE' || s == 'POST') return CandidateAssetType.poste;
    if (s == 'UNTRMT' || s == 'TRAFO' || s == 'TRANSFORMADOR') return CandidateAssetType.trafo;
    if (s == 'UNREMT' || s == 'RELIGADOR' || s == 'RECLOSER') return CandidateAssetType.religador;
    if (s == 'SUB' || s == 'SUBESTACAO' || s == 'SUBSTATION') return CandidateAssetType.subestacao;
    if (s == 'UCBT') return CandidateAssetType.ucbt;
    if (s == 'UCMT') return CandidateAssetType.ucmt;
    if (s == 'SSDMT') return CandidateAssetType.ssdmt;
    if (s == 'SSDBT') return CandidateAssetType.ssdbt;
    if (s == 'SSDAT') return CandidateAssetType.ssdat;
    if (s == 'UNCRAT') return CandidateAssetType.uncrat;
    for (final t in CandidateAssetType.values) {
      if (t.name.toUpperCase() == s) return t;
    }
    return CandidateAssetType.outros;
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
    final typeStr = map['type'] as String? ?? '';
    final parsedType = CandidateAssetTypeExt.fromString(typeStr);
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
  final String? bdgdImportId;
  final bool useDrawnPolygon;
  final List<List<double>> drawnPolygonPoints;

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
    this.bdgdImportId,
    this.useDrawnPolygon = false,
    this.drawnPolygonPoints = const [],
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
    String? bdgdImportId,
    bool? useDrawnPolygon,
    List<List<double>>? drawnPolygonPoints,
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
      bdgdImportId: bdgdImportId ?? this.bdgdImportId,
      useDrawnPolygon: useDrawnPolygon ?? this.useDrawnPolygon,
      drawnPolygonPoints: drawnPolygonPoints ?? this.drawnPolygonPoints,
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
      'bdgdImportId': bdgdImportId,
      'useDrawnPolygon': useDrawnPolygon,
      'drawnPolygonPoints': drawnPolygonPoints,
    };
  }

  String toJson() => json.encode(toMap());

  factory AreaDelimitationConfig.fromMap(Map<String, dynamic> map) {
    final rawTypes = map['selectedAssetTypes'] as List<dynamic>? ?? [];
    final types = <CandidateAssetType>{};
    for (final raw in rawTypes) {
      types.add(CandidateAssetTypeExt.fromString(raw.toString()));
    }
    if (types.isEmpty) {
      types.addAll(const {
        CandidateAssetType.poste,
        CandidateAssetType.trafo,
        CandidateAssetType.religador,
        CandidateAssetType.subestacao,
      });
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
      bdgdImportId: map['bdgdImportId'] as String?,
      useDrawnPolygon: map['useDrawnPolygon'] as bool? ?? false,
      drawnPolygonPoints: (map['drawnPolygonPoints'] as List<dynamic>? ?? [])
          .map((pair) => (pair as List<dynamic>).map((v) => (v as num).toDouble()).toList())
          .toList(),
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
  final List<String> availableTypes;

  const AreaDelimitationResult({
    required this.isValid,
    this.maxAllowedRadiusKm = 8.0,
    required this.isRadiusExceeded,
    required this.intersectsBoundary,
    required this.boundaryOverlapPct,
    required this.candidates,
    required this.countsByType,
    this.availableTypes = const [],
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
      'availableTypes': availableTypes,
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
      availableTypes: List<String>.from(map['availableTypes'] as List? ?? const []),
    );
  }

  factory AreaDelimitationResult.fromJson(String source) =>
      AreaDelimitationResult.fromMap(json.decode(source) as Map<String, dynamic>);
}
