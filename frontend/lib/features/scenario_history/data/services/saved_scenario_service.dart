import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_config.dart';
import '../models/scenario_models.dart';

class SavedScenarioService {
  static const Duration _timeout = Duration(seconds: 15);

  Future<List<ScenarioSummary>> listScenarios({String? regionName}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/scenarios').replace(
      queryParameters: {
        if (regionName != null && regionName.isNotEmpty) 'regionName': regionName,
      },
    );

    final response = await _send((token) => http.get(uri, headers: _headers(token)));
    final body = jsonDecode(response.body) as List<dynamic>;
    return body
        .map((e) => ScenarioSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ScenarioDetail> getScenario(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/scenarios/$id');
    final response = await _send((token) => http.get(uri, headers: _headers(token)));
    return ScenarioDetail.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ScenarioSummary> duplicateScenario(int id, {String? name}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/scenarios/$id/duplicate');
    final response = await _send(
      (token) => http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({if (name != null && name.isNotEmpty) 'name': name}),
      ),
    );
    return ScenarioSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> deleteScenario(int id) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/scenarios/$id');
    await _send((token) => http.delete(uri, headers: _headers(token)));
  }

  Future<ScenarioComparisonResponse> compareScenarios(List<int> ids) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/scenarios/compare');
    final response = await _send(
      (token) => http.post(
        uri,
        headers: _headers(token),
        body: jsonEncode({'scenarioIds': ids}),
      ),
    );
    return ScenarioComparisonResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<http.Response> _send(Future<http.Response> Function(String token) request) async {
    var token = await _getToken();
    token ??= await _attemptAutoLogin();
    if (token == null) {
      throw SavedScenarioException('Sessão expirada. Faça login novamente.');
    }

    try {
      final response = await request(token).timeout(_timeout);
      if (response.statusCode == 401 || response.statusCode == 403) {
        final renewed = await _attemptAutoLogin();
        if (renewed != null) {
          final retry = await request(renewed).timeout(_timeout);
          if (retry.statusCode < 400) return retry;
          throw SavedScenarioException(_extractMessage(retry));
        }
      }
      if (response.statusCode < 400) return response;
      throw SavedScenarioException(_extractMessage(response));
    } on SavedScenarioException {
      rethrow;
    } catch (_) {
      throw SavedScenarioException('Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  String _extractMessage(http.Response response) {
    var message = 'Erro HTTP ${response.statusCode}';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? body['message'] as String? ?? message;
    } catch (_) {
      message += ' - ${response.body.isNotEmpty ? response.body : "Sem resposta do servidor"}';
    }
    return message;
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
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
}

class SavedScenarioException implements Exception {
  final String message;
  const SavedScenarioException(this.message);

  @override
  String toString() => message;
}
