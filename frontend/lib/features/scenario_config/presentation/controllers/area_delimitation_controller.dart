import 'package:flutter/foundation.dart';
import '../../data/services/area_delimitation_service.dart';
import '../../domain/models/area_delimitation_model.dart';

class AreaDelimitationController extends ChangeNotifier {
  final AreaDelimitationService _service;

  AreaDelimitationConfig _config;
  AreaDelimitationResult? _result;
  bool _isLoading = false;
  CandidateAsset? _selectedCandidate;
  String _activeMapLayer = 'vetor';

  AreaDelimitationController({
    AreaDelimitationService? service,
    AreaDelimitationConfig? initialConfig,
  })  : _service = service ?? AreaDelimitationService(),
        _config = initialConfig ?? const AreaDelimitationConfig();

  AreaDelimitationConfig get config => _config;
  AreaDelimitationResult? get result => _result;
  bool get isLoading => _isLoading;
  CandidateAsset? get selectedCandidate => _selectedCandidate;
  String get activeMapLayer => _activeMapLayer;

  double get radiusKm => _config.radiusKm;
  bool get isUnitKm => _config.isUnitKm;
  bool get defineClickingOnMap => _config.defineClickingOnMap;
  Set<CandidateAssetType> get selectedAssetTypes => _config.selectedAssetTypes;

  bool get isRadiusExceeded => _result?.isRadiusExceeded ?? (_config.radiusKm > 8.0);
  bool get intersectsBoundary => _result?.intersectsBoundary ?? false;
  double get boundaryOverlapPct => _result?.boundaryOverlapPct ?? 0.0;

  List<CandidateAsset> get allCandidates => _result?.candidates ?? const [];

  List<CandidateAsset> get filteredCandidates {
    final list = _result?.candidates ?? const [];
    return list.where((c) => _config.selectedAssetTypes.contains(c.type)).toList();
  }

  int get totalCandidatesCount => 454;

  int countForType(CandidateAssetType type) => _result?.countFor(type) ?? 0;

  bool get canAdvance {
    if (_result == null) return false;
    return _result!.isValid && filteredCandidates.isNotEmpty;
  }

  Future<void> init() async {
    await evaluateArea();
  }

  Future<void> evaluateArea() async {
    _isLoading = true;
    notifyListeners();

    try {
      _result = await _service.evaluateArea(_config);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCenterCoordinates(double lat, double lng) {
    _config = _config.copyWith(
      centerLatitude: lat,
      centerLongitude: lng,
    );
    _selectedCandidate = null;
    evaluateArea();
  }

  void onMapTap(double lat, double lng) {
    if (_config.defineClickingOnMap) {
      setCenterCoordinates(lat, lng);
    } else {
      _selectedCandidate = null;
      notifyListeners();
    }
  }

  void setAddressQuery(String query) {
    _config = _config.copyWith(address: query);
    notifyListeners();
  }

  void clearAddress() {
    _config = _config.copyWith(address: '');
    notifyListeners();
  }

  void setRadius(double radius, {bool? isUnitKm}) {
    final updatedUnit = isUnitKm ?? _config.isUnitKm;
    final normalizedRadius = updatedUnit ? radius : radius / 1000.0;

    _config = _config.copyWith(
      radiusKm: normalizedRadius,
      isUnitKm: updatedUnit,
    );
    evaluateArea();
  }

  void toggleUnit(bool toKm) {
    if (_config.isUnitKm == toKm) return;
    _config = _config.copyWith(isUnitKm: toKm);
    notifyListeners();
  }

  void setDefineClickingOnMap(bool value) {
    _config = _config.copyWith(defineClickingOnMap: value);
    notifyListeners();
  }

  void toggleAssetType(CandidateAssetType type) {
    final current = Set<CandidateAssetType>.from(_config.selectedAssetTypes);
    if (current.contains(type)) {
      current.remove(type);
    } else {
      current.add(type);
    }
    _config = _config.copyWith(selectedAssetTypes: current);
    if (_selectedCandidate != null && !current.contains(_selectedCandidate!.type)) {
      _selectedCandidate = null;
    }
    notifyListeners();
  }

  void selectCandidate(CandidateAsset? candidate) {
    _selectedCandidate = candidate;
    notifyListeners();
  }

  void setMapLayer(String layer) {
    _activeMapLayer = layer;
    notifyListeners();
  }
}
