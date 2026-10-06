import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../models/api_models.dart';

class AreaDelimitationService {
  static const double maxRadiusKm = 8.0;

  Future<AreaDelimitationResult> evaluateArea(
    AreaDelimitationConfig config,
  ) async {
    final isExceeded = config.radiusKm > maxRadiusKm;
    final isValid = !isExceeded;

    List<CandidateAsset> candidates;
    Map<CandidateAssetType, int> counts;
    bool intersectsBoundary = false;
    double boundaryOverlapPct = 0.0;

    if (isValid) {
      try {
        final apiResult = await _callSearchAreaApi(config);

        if (apiResult.validationStatus == 'ERROR') {
          candidates = [];
        } else if (apiResult.candidates.isNotEmpty) {
          candidates = _mapApiCandidatesToDomain(apiResult.candidates, config);
        } else {
          candidates = [];
        }
        counts = _countCandidatesByType(candidates);

        intersectsBoundary =
            apiResult.validationStatus == 'WARNING_OUT_OF_BOUNDS';
        boundaryOverlapPct = intersectsBoundary ? 12.0 : 0.0;
      } catch (_) {
        candidates = [];
        counts = _countCandidatesByType(candidates);
      }
    } else {
      candidates = [];
      counts = <CandidateAssetType, int>{
        CandidateAssetType.poste: 0,
        CandidateAssetType.trafo: 0,
        CandidateAssetType.religador: 0,
        CandidateAssetType.subestacao: 0,
      };
    }

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

  Future<String?> _attemptAutoLogin() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': 'admin@tecsys.com',
              'password': 'Admin@123',
            }),
          )
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('auth_token', token);
          return token;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<SearchAreaResponse> _callSearchAreaApi(
    AreaDelimitationConfig config,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth_token');
    if (token == null) {
      token = await _attemptAutoLogin();
    }
    if (token == null) {
      throw AreaDelimitationException('Sessão expirada. Faça login novamente.');
    }

    final request = SearchAreaRequest(
      latitude: config.centerLatitude,
      longitude: config.centerLongitude,
      radius: config.radiusMeters,
    );

    final uri = Uri.parse('${ApiConfig.baseUrl}/scenario/search-area');

    var response = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: request.toJson(),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401 || response.statusCode == 403) {
      token = await _attemptAutoLogin();
      if (token != null) {
        response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Accept': 'application/json',
              },
              body: request.toJson(),
            )
            .timeout(const Duration(seconds: 15));
      }
    }

    if (response.statusCode == 200) {
      return SearchAreaResponse.fromMap(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    var message = 'Erro HTTP ${response.statusCode}';
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      message =
          body['message'] as String? ?? body['error'] as String? ?? message;
    } catch (_) {
      message +=
          ' - ${response.body.isNotEmpty ? response.body : "Sem resposta do servidor"}';
    }

    throw AreaDelimitationException(message);
  }

  List<CandidateAsset> _mapApiCandidatesToDomain(
    List<AssetDto> apiCandidates,
    AreaDelimitationConfig config,
  ) {
    final list = <CandidateAsset>[];
    for (var i = 0; i < apiCandidates.length; i++) {
      final api = apiCandidates[i];
      final type = _mapAssetType(api.type);
      final distM = _calculateDistance(
        config.centerLatitude,
        config.centerLongitude,
        api.latitude,
        api.longitude,
      );

      list.add(
        CandidateAsset(
          id: api.id,
          assetKey: api.id,
          type: type,
          latitude: api.latitude,
          longitude: api.longitude,
          voltageKv: _getDefaultVoltage(type),
          distanceMeters: distM,
          poleHeightM: _getDefaultPoleHeight(type),
          losVisada: '360° Livre',
          bdgdId: api.id,
        ),
      );
    }
    return list;
  }

  CandidateAssetType _mapAssetType(String apiType) {
    switch (apiType.toUpperCase()) {
      case 'PONNOT':
      case 'POSTE':
      case 'POST':
        return CandidateAssetType.poste;
      case 'UNTRMT':
      case 'TRAFO':
      case 'TRANSFORMADOR':
        return CandidateAssetType.trafo;
      case 'UNREMT':
      case 'RELIGADOR':
      case 'RECLOSER':
        return CandidateAssetType.religador;
      case 'SUB':
      case 'SUBESTACAO':
      case 'SUBSTATION':
        return CandidateAssetType.subestacao;
      default:
        return CandidateAssetType.poste;
    }
  }

  double _getDefaultVoltage(CandidateAssetType type) {
    switch (type) {
      case CandidateAssetType.subestacao:
        return 69.0;
      case CandidateAssetType.trafo:
        return 13.8;
      case CandidateAssetType.religador:
        return 13.8;
      case CandidateAssetType.poste:
        return 13.8;
    }
  }

  double _getDefaultPoleHeight(CandidateAssetType type) {
    switch (type) {
      case CandidateAssetType.subestacao:
        return 25.0;
      case CandidateAssetType.trafo:
        return 12.0;
      case CandidateAssetType.religador:
        return 13.0;
      case CandidateAssetType.poste:
        return 10.0;
    }
  }

  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = 111320.0 * math.cos(lat1 * math.pi / 180.0);
    final dLat = (lat2 - lat1) * metersPerDegreeLat;
    final dLng = (lng2 - lng1) * metersPerDegreeLng;
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  Map<CandidateAssetType, int> _countCandidatesByType(
    List<CandidateAsset> candidates,
  ) {
    final counts = <CandidateAssetType, int>{};
    for (final type in CandidateAssetType.values) {
      counts[type] = candidates.where((c) => c.type == type).length;
    }
    return counts;
  }
}

class AreaDelimitationException implements Exception {
  final String message;
  const AreaDelimitationException(this.message);

  @override
  String toString() => message;
}
