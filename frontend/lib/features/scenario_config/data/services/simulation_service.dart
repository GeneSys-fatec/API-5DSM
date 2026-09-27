import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../models/api_models.dart';

class SimulationService {
  Future<SimulationResponse> runSimulation({
    required SimulationRequest request,
    required String token,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/simulations');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
      body: request.toJson(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200 || response.statusCode == 201) {
      return SimulationResponse.fromMap(
        json.decode(response.body) as Map<String, dynamic>,
      );
    }

    var message = 'Erro HTTP ${response.statusCode}';
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      message = body['error'] as String? ?? body['message'] as String? ?? message;
    } catch (_) {
      message += ' - ${response.body.isNotEmpty ? response.body : "Sem resposta do servidor"}';
    }

    throw SimulationException(message);
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

  Future<SimulationResponse> runSimulationWithAuth(SimulationRequest request) async {
    var token = await _getToken();
    if (token == null) {
      token = await _attemptAutoLogin();
    }
    if (token == null) {
      throw SimulationException('Sessão expirada. Faça login novamente.');
    }
    try {
      return await runSimulation(request: request, token: token);
    } catch (e) {
      if (e is SimulationException && e.message.contains('401')) {
        token = await _attemptAutoLogin();
        if (token != null) {
          return await runSimulation(request: request, token: token);
        }
      }
      rethrow;
    }
  }
}

class SimulationException implements Exception {
  final String message;
  const SimulationException(this.message);

  @override
  String toString() => message;
}