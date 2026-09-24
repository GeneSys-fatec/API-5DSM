import 'dart:math' as math;
import '../../domain/models/area_delimitation_model.dart';

class AreaDelimitationService {
  static const double maxRadiusKm = 8.0;

  Future<AreaDelimitationResult> evaluateArea(AreaDelimitationConfig config) async {
    final isExceeded = config.radiusKm > maxRadiusKm;
    final isValid = !isExceeded;
    final intersectsBoundary = config.radiusKm >= 3.0;
    final boundaryOverlapPct = intersectsBoundary ? 12.0 : 0.0;

    final candidates = _generateCandidates(config);

    final counts = <CandidateAssetType, int>{
      CandidateAssetType.poste: 342,
      CandidateAssetType.trafo: 88,
      CandidateAssetType.religador: 24,
      CandidateAssetType.subestacao: 2,
    };

    return AreaDelimitationResult(
      isValid: isValid,
      maxAllowedRadiusKm: maxRadiusKm,
      isRadiusExceeded: isExceeded,
      intersectsBoundary: intersectsBoundary,
      boundaryOverlapPct: boundaryOverlapPct,
      candidates: candidates,
      countsByType: counts,
    );
  }

  List<CandidateAsset> _generateCandidates(AreaDelimitationConfig config) {
    final list = <CandidateAsset>[];
    final centerLat = config.centerLatitude;
    final centerLng = config.centerLongitude;
    final radiusM = config.radiusMeters;

    final baseOffsets = [
      _CandidateSpec(CandidateAssetType.subestacao, 'SUB-01', '#10001', 0.18, 0.25, 69.0, '360° Livre', 25.0),
      _CandidateSpec(CandidateAssetType.subestacao, 'SUB-02', '#10002', -0.22, 0.40, 138.0, '360° Livre', 28.0),

      _CandidateSpec(CandidateAssetType.trafo, 'TR-01', '#448910', 0.28, 0.35, 13.8, '360° Livre', 12.0),
      _CandidateSpec(CandidateAssetType.trafo, 'TR-02', '#448911', -0.35, -0.20, 13.8, '180° Parcial', 12.0),
      _CandidateSpec(CandidateAssetType.trafo, 'TR-03', '#448912', 0.45, -0.40, 13.8, '360° Livre', 11.5),
      _CandidateSpec(CandidateAssetType.trafo, 'TR-04', '#448913', -0.15, 0.55, 13.8, '360° Livre', 12.0),

      _CandidateSpec(CandidateAssetType.religador, 'REL-01', '#330101', 0.30, -0.15, 13.8, '360° Livre', 13.0),
      _CandidateSpec(CandidateAssetType.religador, 'REL-02', '#330102', -0.40, 0.30, 13.8, '360° Livre', 13.0),
      _CandidateSpec(CandidateAssetType.religador, 'REL-03', '#330103', 0.10, -0.50, 13.8, '270° Livre', 13.5),

      _CandidateSpec(CandidateAssetType.poste, 'PST-01', '#550101', -0.55, -0.10, 13.8, '360° Livre', 10.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-02', '#550102', -0.20, -0.45, 13.8, '360° Livre', 10.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-03', '#550103', 0.05, -0.60, 13.8, '360° Livre', 10.5),
      _CandidateSpec(CandidateAssetType.poste, 'PST-04', '#550104', -0.05, 0.65, 13.8, '360° Livre', 10.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-05', '#550105', 0.60, 0.20, 13.8, '360° Livre', 10.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-06', '#550106', 0.35, 0.50, 13.8, '360° Livre', 11.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-07', '#550107', -0.45, 0.50, 13.8, '360° Livre', 10.0),
      _CandidateSpec(CandidateAssetType.poste, 'PST-08', '#550108', -0.60, 0.15, 13.8, '360° Livre', 10.0),
    ];

    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = 111320.0 * math.cos(centerLat * math.pi / 180.0);

    for (var i = 0; i < baseOffsets.length; i++) {
      final spec = baseOffsets[i];
      final offsetMetersLat = spec.latFactor * radiusM;
      final offsetMetersLng = spec.lngFactor * radiusM;
      final distM = math.sqrt(offsetMetersLat * offsetMetersLat + offsetMetersLng * offsetMetersLng);

      final lat = centerLat + (offsetMetersLat / metersPerDegreeLat);
      final lng = centerLng + (offsetMetersLng / metersPerDegreeLng);

      list.add(CandidateAsset(
        id: 'cand-$i',
        assetKey: spec.key,
        type: spec.type,
        latitude: lat,
        longitude: lng,
        voltageKv: spec.voltageKv,
        distanceMeters: distM,
        poleHeightM: spec.poleHeightM,
        losVisada: spec.los,
        bdgdId: spec.bdgdId,
      ));
    }

    return list;
  }
}

class _CandidateSpec {
  final CandidateAssetType type;
  final String key;
  final String bdgdId;
  final double latFactor;
  final double lngFactor;
  final double voltageKv;
  final String los;
  final double poleHeightM;

  const _CandidateSpec(
    this.type,
    this.key,
    this.bdgdId,
    this.latFactor,
    this.lngFactor,
    this.voltageKv,
    this.los,
    this.poleHeightM,
  );
}
