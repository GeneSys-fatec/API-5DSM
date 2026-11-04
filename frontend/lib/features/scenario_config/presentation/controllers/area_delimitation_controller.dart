import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../data/services/area_delimitation_service.dart';
import '../../data/services/scenario_storage_service.dart';
import '../../domain/models/area_delimitation_model.dart';

class AreaDelimitationController extends ChangeNotifier {
  static AreaDelimitationConfig? _sharedConfig;
  static AreaDelimitationResult? _sharedResult;
  static double? _sharedMaxRadiusKm;

  static AreaDelimitationConfig? get sharedConfig => _sharedConfig;
  static AreaDelimitationResult? get sharedResult => _sharedResult;
  static double? get sharedMaxRadiusKm => _sharedMaxRadiusKm;

  static void setSharedConfig(AreaDelimitationConfig config) {
    _sharedConfig = config;
    _sharedResult = null;
  }

  static void resetSharedState() {
    _sharedConfig = null;
    _sharedResult = null;
  }

  static Future<AreaDelimitationResult?> restoreSharedStateFromStorage({
    ScenarioStorageService? storageService,
  }) async {
    if (_sharedResult != null && _sharedConfig != null) {
      return _sharedResult;
    }
    final storage = storageService ?? ScenarioStorageService();
    final cachedConfig = await storage.loadAreaConfig();
    final cachedResult = await storage.loadAreaResult();
    if (cachedConfig != null) {
      _sharedConfig = cachedConfig;
    }
    if (cachedResult != null) {
      _sharedResult = cachedResult;
    }
    return _sharedResult;
  }

  final AreaDelimitationService _service;
  final ScenarioStorageService _storageService;

  AreaDelimitationConfig _config;
  AreaDelimitationResult? _result;
  bool _isLoading = false;
  CandidateAsset? _selectedCandidate;
  String _activeMapLayer = 'vetor';
  List<LatLng>? _boundaryPolygon;
  String? _lastBoundaryImportId;
  bool _pointOutOfBounds = false;
  String? _areaDelimitationError;
  bool _polygonPointOutOfBounds = false;
  Timer? _polygonDebounceTimer;
  int _evaluationGeneration = 0;

  AreaDelimitationController({
    AreaDelimitationService? service,
    ScenarioStorageService? storageService,
    AreaDelimitationConfig? initialConfig,
  }) : _service = service ?? AreaDelimitationService(),
       _storageService = storageService ?? ScenarioStorageService(),
       _config =
           initialConfig ?? _sharedConfig ?? const AreaDelimitationConfig(),
       _result = _sharedResult;

  AreaDelimitationConfig get config => _config;
  AreaDelimitationResult? get result => _result;
  bool get isLoading => _isLoading;
  CandidateAsset? get selectedCandidate => _selectedCandidate;
  String get activeMapLayer => _activeMapLayer;
  List<LatLng>? get boundaryPolygon => _boundaryPolygon;
  bool get pointOutOfBounds => _pointOutOfBounds;
  String? get areaDelimitationError => _areaDelimitationError;
  bool get useDrawnPolygon => _config.useDrawnPolygon;
  bool get polygonPointOutOfBounds => _polygonPointOutOfBounds;
  List<LatLng> get drawnPolygonPoints => _config.drawnPolygonPoints
      .map((pair) => LatLng(pair[0], pair[1]))
      .toList();

  double get radiusKm => _config.radiusKm;
  bool get isUnitKm => _config.isUnitKm;

  double get maxRadiusKm => _sharedMaxRadiusKm ?? AreaDelimitationService.maxRadiusKm;
  bool get defineClickingOnMap => _config.defineClickingOnMap;
  Set<CandidateAssetType> get selectedAssetTypes => _config.selectedAssetTypes;

  bool get isRadiusExceeded =>
      _result?.isRadiusExceeded ?? (_config.radiusKm > maxRadiusKm);
  bool get intersectsBoundary => _result?.intersectsBoundary ?? false;
  double get boundaryOverlapPct => _result?.boundaryOverlapPct ?? 0.0;

  List<CandidateAsset> get allCandidates => _result?.candidates ?? const [];

  List<CandidateAsset> get filteredCandidates {
    final list = _result?.candidates ?? const [];
    return list
        .where((c) => _config.selectedAssetTypes.contains(c.type))
        .toList();
  }

  int get totalCandidatesCount {
    if (_result != null) {
      return _result!.totalCandidates;
    }
    return filteredCandidates.length;
  }

  int countForType(CandidateAssetType type) => _result?.countFor(type) ?? 0;

  bool get canAdvance {
    if (_result == null) return false;
    return _result!.isValid &&
        _config.selectedAssetTypes.isNotEmpty &&
        filteredCandidates.isNotEmpty;
  }

  Future<void> init() async {
    unawaited(_loadRadiusCeiling()); 
    if (_sharedResult != null) {
      _result = _sharedResult;
      _config = _sharedConfig ?? _config;
      _enforceRadiusCeiling(); 
      await _refreshBoundaryIfNeeded();
      notifyListeners();
      await evaluateArea();
      return;
    }
    final cachedConfig = await _storageService.loadAreaConfig();
    final cachedResult = await _storageService.loadAreaResult();
    if (cachedConfig != null &&
        cachedResult != null &&
        !_containsLegacyMockCandidates(cachedResult)) {
      _config = cachedConfig;
      _result = cachedResult;
      _sharedConfig = cachedConfig;
      _sharedResult = cachedResult;
      _enforceRadiusCeiling();
      await _refreshBoundaryIfNeeded();
      notifyListeners();
      await evaluateArea();
      return;
    }
    if (cachedConfig != null) {
      _config = cachedConfig;
      _sharedConfig = cachedConfig;
      _enforceRadiusCeiling(); 
    }
    await evaluateArea();
  }

  Future<void> _loadRadiusCeiling() async {
    if (_sharedMaxRadiusKm != null) return; 
    final fetched = await _service.fetchMaxRadiusKm();
    if (fetched == null) return;
    _sharedMaxRadiusKm = fetched;
    if (_enforceRadiusCeiling()) {
      await evaluateArea();
    } else {
      notifyListeners(); 
    }
  }

  bool _enforceRadiusCeiling() {
    if (_config.radiusKm <= maxRadiusKm) return false;
    _config = _config.copyWith(radiusKm: maxRadiusKm);
    _sharedConfig = _config;
    _storageService.saveAreaConfig(_config);
    return true;
  }

  static final RegExp _legacyMockId = RegExp(r'^(sub|trafo|rel|poste)-\d+$');

  bool _containsLegacyMockCandidates(AreaDelimitationResult result) {
    return result.candidates.any((c) => _legacyMockId.hasMatch(c.id));
  }

  Future<void> _refreshBoundaryIfNeeded() async {
    final importId = _config.bdgdImportId;
    if (importId == null || importId.isEmpty) {
      _boundaryPolygon = null;
      _lastBoundaryImportId = null;
      return;
    }
    if (importId == _lastBoundaryImportId) {
      return;
    }
    final rawCoordinates = await _service.fetchBdgdBounds(importId);
    _lastBoundaryImportId = importId;
    _boundaryPolygon = rawCoordinates
        ?.map((pair) => LatLng(pair[1], pair[0]))
        .toList();
  }

  LatLngBounds? get boundaryLatLngBounds {
    if (_boundaryPolygon == null || _boundaryPolygon!.isEmpty) {
      return null;
    }
    return LatLngBounds.fromPoints(_boundaryPolygon!);
  }

  void _recenterIfOutsideKnownBoundary() {
    final boundary = _boundaryPolygon;
    if (boundary == null || boundary.length < 3) return;
    if (isPointInsidePolygon(_config.centerLatitude, _config.centerLongitude, boundary)) {
      return;
    }
    final resolved = resolvePolygonCenter(boundary);
    _config = _config.copyWith(
      centerLatitude: resolved.latitude,
      centerLongitude: resolved.longitude,
    );
    _sharedConfig = _config;
    _pointOutOfBounds = false;
  }

  /// Descarta o resultado atual e invalida qualquer avaliação em andamento ou agendada,
  /// para que uma busca antiga (ex.: a circular) não volte a preencher a tela depois.
  void _discardCurrentResult() {
    _polygonDebounceTimer?.cancel();
    _evaluationGeneration++;
    _isLoading = false;
    _result = null;
    _sharedResult = null;
    _selectedCandidate = null;
    _areaDelimitationError = null;
    notifyListeners();
  }

  Future<void> evaluateArea() async {
    // Modo polígono sem os 3 pontos mínimos: não há área para buscar. Sem este guard o serviço
    // caía na busca circular e trazia de volta os candidatos do ponto central.
    if (_config.useDrawnPolygon && _config.drawnPolygonPoints.length < 3) {
      _discardCurrentResult();
      return;
    }
    final myGeneration = ++_evaluationGeneration;
    _isLoading = true;
    _areaDelimitationError = null;
    notifyListeners();

    try {
      await _refreshBoundaryIfNeeded();
      _recenterIfOutsideKnownBoundary();
      final result = await _service.evaluateArea(_config);
      if (myGeneration != _evaluationGeneration) return;
      _result = result;
      _pointOutOfBounds = false;
      _sharedConfig = _config;
      _sharedResult = _result;
      _storageService.saveAreaConfig(_config);
      if (_result != null) {
        _storageService.saveAreaResult(_result!);
      }
    } on PointOutOfBoundsException {
      if (myGeneration != _evaluationGeneration) return;
      _pointOutOfBounds = true;
      _result = null;
    } on AreaDelimitationException catch (e) {
      if (myGeneration != _evaluationGeneration) return;
      _areaDelimitationError = e.message;
      _result = null;
    } finally {
      if (myGeneration == _evaluationGeneration) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  static const Duration _polygonDebounceDuration = Duration(milliseconds: 400);

  void _scheduleEvaluateArea() {
    _polygonDebounceTimer?.cancel();
    _polygonDebounceTimer = Timer(_polygonDebounceDuration, () {
      evaluateArea();
    });
  }
  bool setCenterCoordinates(double lat, double lng) {
    if (_boundaryPolygon != null &&
        !isPointInsidePolygon(lat, lng, _boundaryPolygon!)) {
      _pointOutOfBounds = true;
      notifyListeners();
      return false;
    }

    _pointOutOfBounds = false;
    _config = _config.copyWith(centerLatitude: lat, centerLongitude: lng);
    _sharedConfig = _config;
    _selectedCandidate = null;
    evaluateArea();
    return true;
  }

  void applyConfig(AreaDelimitationConfig newConfig) {
    _config = newConfig;
    _sharedConfig = _config;
    _selectedCandidate = null;
    evaluateArea();
  }

  void onMapTap(double lat, double lng) {
    if (_config.useDrawnPolygon) {
      addPolygonPoint(lat, lng);
    } else if (_config.defineClickingOnMap) {
      setCenterCoordinates(lat, lng);
    } else {
      _selectedCandidate = null;
      notifyListeners();
    }
  }

  void setUseDrawnPolygon(bool value) {
    if (_config.useDrawnPolygon == value) return;
    _config = _config.copyWith(useDrawnPolygon: value);
    _sharedConfig = _config;
    _polygonPointOutOfBounds = false;
    if (!value || _config.drawnPolygonPoints.length >= 3) {
      evaluateArea();
    } else {
      _discardCurrentResult();
    }
  }

  bool addPolygonPoint(double lat, double lng) {
    if (_boundaryPolygon != null &&
        !isPointInsidePolygon(lat, lng, _boundaryPolygon!)) {
      _polygonPointOutOfBounds = true;
      notifyListeners();
      return false;
    }

    _polygonPointOutOfBounds = false;
    final updatedPoints = List<List<double>>.from(_config.drawnPolygonPoints)
      ..add([lat, lng]);
    _config = _config.copyWith(drawnPolygonPoints: updatedPoints);
    _sharedConfig = _config;
    if (updatedPoints.length >= 3) {
      _scheduleEvaluateArea();
    } else {
      notifyListeners();
    }
    return true;
  }

  bool movePolygonPoint(int index, double lat, double lng) {
    if (index < 0 || index >= _config.drawnPolygonPoints.length) {
      return false;
    }
    if (_boundaryPolygon != null &&
        !isPointInsidePolygon(lat, lng, _boundaryPolygon!)) {
      _polygonPointOutOfBounds = true;
      notifyListeners();
      return false;
    }

    _polygonPointOutOfBounds = false;
    final updatedPoints = List<List<double>>.from(_config.drawnPolygonPoints);
    updatedPoints[index] = [lat, lng];
    _config = _config.copyWith(drawnPolygonPoints: updatedPoints);
    _sharedConfig = _config;
    if (updatedPoints.length >= 3) {
      _scheduleEvaluateArea();
    } else {
      notifyListeners();
    }
    return true;
  }

  void removePolygonPoint(int index) {
    if (index < 0 || index >= _config.drawnPolygonPoints.length) {
      return;
    }
    final updatedPoints = List<List<double>>.from(_config.drawnPolygonPoints)
      ..removeAt(index);
    _config = _config.copyWith(drawnPolygonPoints: updatedPoints);
    _sharedConfig = _config;
    _polygonPointOutOfBounds = false;
    if (updatedPoints.length >= 3) {
      _scheduleEvaluateArea();
    } else {
      _discardCurrentResult();
    }
  }

  void clearDrawnPolygon() {
    _config = _config.copyWith(drawnPolygonPoints: const []);
    _sharedConfig = _config;
    _polygonPointOutOfBounds = false;
    _discardCurrentResult();
  }

  void setAddressQuery(String query) {
    _config = _config.copyWith(address: query);
    _sharedConfig = _config;
    notifyListeners();
  }

  void clearAddress() {
    _config = _config.copyWith(address: '');
    _sharedConfig = _config;
    notifyListeners();
  }

  void setRadius(double radius, {bool? isUnitKm}) {
    final updatedUnit = isUnitKm ?? _config.isUnitKm;
    final normalizedRadius = updatedUnit ? radius : radius / 1000.0;

    _config = _config.copyWith(
      radiusKm: normalizedRadius,
      isUnitKm: updatedUnit,
    );
    _sharedConfig = _config;
    evaluateArea();
  }

  void toggleUnit(bool toKm) {
    if (_config.isUnitKm == toKm) return;
    _config = _config.copyWith(isUnitKm: toKm);
    _sharedConfig = _config;
    notifyListeners();
  }

  void setDefineClickingOnMap(bool value) {
    _config = _config.copyWith(defineClickingOnMap: value);
    _sharedConfig = _config;
    notifyListeners();
  }

  void selectAllAssetTypes(Iterable<CandidateAssetType> types) {
    _config = _config.copyWith(selectedAssetTypes: types.toSet());
    _sharedConfig = _config;
    notifyListeners();
  }

  void deselectAllAssetTypes() {
    _config = _config.copyWith(selectedAssetTypes: <CandidateAssetType>{});
    _sharedConfig = _config;
    _selectedCandidate = null;
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
    _sharedConfig = _config;
    if (_selectedCandidate != null &&
        !current.contains(_selectedCandidate!.type)) {
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

  @override
  void dispose() {
    _polygonDebounceTimer?.cancel();
    super.dispose();
  }
}
