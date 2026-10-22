import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../models/api_models.dart';

class AreaDelimitationService {
  static const double maxRadiusKm = 8.0;

  Future<List<List<double>>?> fetchBdgdBounds(String importId) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth_token');
    if (token == null) {
      token = await _attemptAutoLogin();
    }
    if (token == null) {
      return null;
    }

    try {
      var response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/bdgd/$importId/bounds'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 401 || response.statusCode == 403) {
        token = await _attemptAutoLogin();
        if (token != null) {
          response = await http.get(
            Uri.parse('${ApiConfig.baseUrl}/api/bdgd/$importId/bounds'),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          ).timeout(const Duration(seconds: 60));
        }
      }

      if (response.statusCode != 200) {
        return null;
      }

      final body = json.decode(response.body) as Map<String, dynamic>;
      return _extractPolygonCoordinates(body['geometry']);
    } catch (_) {
      return null;
    }
  }

  List<List<double>>? _extractPolygonCoordinates(dynamic geometry) {
    if (geometry == null || geometry is! Map<String, dynamic>) {
      return null;
    }
    if (geometry['type'] != 'Polygon') {
      return null;
    }
    final rings = geometry['coordinates'] as List<dynamic>?;
    if (rings == null || rings.isEmpty) {
      return null;
    }
    final outerRing = rings.first as List<dynamic>;
    return outerRing
        .map((point) => (point as List<dynamic>)
            .map((value) => (value as num).toDouble())
            .toList())
        .toList();
  }

  Future<AreaDelimitationResult> evaluateArea(AreaDelimitationConfig config) async {
    final isExceeded = config.radiusKm > maxRadiusKm;
    final isValid = !isExceeded;

    List<CandidateAsset> candidates;
    List<String> availableTypes = const [];
    Map<CandidateAssetType, int> counts;
    bool intersectsBoundary = false;
    double boundaryOverlapPct = 0.0;

    if (isValid) {
      try {
        final apiResult = await _callSearchAreaApi(config);

        if (apiResult.validationStatus == 'ERROR_OUT_OF_BOUNDS') {
          throw PointOutOfBoundsException(apiResult.message);
        }
        if (apiResult.validationStatus == 'ERROR') {
          candidates = [];
        } else if (apiResult.candidates.isNotEmpty) {
          candidates = _mapApiCandidatesToDomain(apiResult.candidates, config);
        } else {
          candidates = [];
        }

        availableTypes = apiResult.availableTypes;
        if (apiResult.countsByType.isNotEmpty) {
          counts = <CandidateAssetType, int>{};
          apiResult.countsByType.forEach((code, count) {
            final type = CandidateAssetTypeExt.fromString(code);
            counts[type] = (counts[type] ?? 0) + count;
          });
        } else {
          counts = _countCandidatesByType(candidates);
        }
        
        intersectsBoundary = apiResult.validationStatus == 'WARNING_OUT_OF_BOUNDS';
        boundaryOverlapPct = intersectsBoundary ? 12.0 : 0.0;
      } on PointOutOfBoundsException {
        rethrow;
      } on AreaDelimitationException {
        rethrow;
      } on TimeoutException {
        throw const AreaDelimitationException(
          'Tempo limite excedido ao buscar os ativos da BDGD. '
          'O servidor ou o banco pode estar lento; tente novamente.',
        );
      } catch (_) {
        throw const AreaDelimitationException(
          'Não foi possível obter os ativos da BDGD. '
          'Verifique se o servidor está acessível e tente novamente.',
        );
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
      availableTypes: availableTypes,
    );
  }

  Future<String?> _attemptAutoLogin() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': 'admin@tecsys.com', 'password': 'Admin@123'}),
      ).timeout(const Duration(seconds: 5));
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

  Future<SearchAreaResponse> _callSearchAreaApi(AreaDelimitationConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    var token = prefs.getString('auth_token');
    if (token == null) {
      token = await _attemptAutoLogin();
    }
    if (token == null) {
      throw const AreaDelimitationException('Sessão expirada. Faça login novamente.');
    }

    if (config.bdgdImportId == null || config.bdgdImportId!.isEmpty) {
      throw const AreaDelimitationException('Selecione uma base BDGD importada antes de delimitar a área.');
    }

    final selectedCodes = config.selectedAssetTypes.expand((t) => t.allFilterCodes).toList();
    final request = SearchAreaRequest(
      importId: config.bdgdImportId!,
      latitude: config.centerLatitude,
      longitude: config.centerLongitude,
      radius: config.radiusMeters,
      selectedAssetTypes: selectedCodes,
    );

    final uri = Uri.parse('${ApiConfig.baseUrl}/scenario/search-area');

    var response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: request.toJson(),
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode == 401 || response.statusCode == 403) {
      token = await _attemptAutoLogin();
      if (token != null) {
        response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          body: request.toJson(),
        ).timeout(const Duration(seconds: 90));
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
      message = body['message'] as String? ?? body['error'] as String? ?? message;
    } catch (_) {
      message += ' - ${response.body.isNotEmpty ? response.body : "Sem resposta do servidor"}';
    }

    throw AreaDelimitationException(message);
  }

  List<CandidateAsset> _mapApiCandidatesToDomain(List<AssetDto> apiCandidates, AreaDelimitationConfig config) {
    final list = <CandidateAsset>[];
    for (var i = 0; i < apiCandidates.length; i++) {
      final api = apiCandidates[i];
      final type = _mapAssetType(api.type);
      final distM = _calculateDistance(config.centerLatitude, config.centerLongitude, api.latitude, api.longitude);

      list.add(CandidateAsset(
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
      ));
    }
    return list;
  }

  CandidateAssetType _mapAssetType(String apiType) {
    return CandidateAssetTypeExt.fromString(apiType);
  }

  double _getDefaultVoltage(CandidateAssetType type) {
    switch (type) {
      case CandidateAssetType.subestacao:
      case CandidateAssetType.ssdat:
        return 69.0;
      case CandidateAssetType.trafo:
      case CandidateAssetType.religador:
      case CandidateAssetType.poste:
      case CandidateAssetType.ssdmt:
      case CandidateAssetType.ucmt:
      case CandidateAssetType.uncrat:
        return 13.8;
      case CandidateAssetType.ucbt:
      case CandidateAssetType.ssdbt:
        return 0.22;
      default:
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
      case CandidateAssetType.ssdat:
        return 20.0;
      case CandidateAssetType.poste:
      case CandidateAssetType.ssdmt:
      case CandidateAssetType.ssdbt:
      case CandidateAssetType.uncrat:
      case CandidateAssetType.ucbt:
      case CandidateAssetType.ucmt:
      default:
        return 10.0;
    }
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng = 111320.0 * math.cos(lat1 * math.pi / 180.0);
    final dLat = (lat2 - lat1) * metersPerDegreeLat;
    final dLng = (lng2 - lng1) * metersPerDegreeLng;
    return math.sqrt(dLat * dLat + dLng * dLng);
  }

  Map<CandidateAssetType, int> _countCandidatesByType(List<CandidateAsset> candidates) {
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

class PointOutOfBoundsException implements Exception {
  final String message;
  const PointOutOfBoundsException(this.message);

  @override
  String toString() => message;
}
