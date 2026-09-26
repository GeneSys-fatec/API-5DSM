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
    );

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

  Future<SimulationResponse> runSimulationWithAuth(SimulationRequest request) async {
    final token = await _getToken();
    if (token == null) {
      throw SimulationException('Sessão expirada. Faça login novamente.');
    }
    return runSimulation(request: request, token: token);
  }
}

class SimulationException implements Exception {
  final String message;
  const SimulationException(this.message);

  @override
  String toString() => message;
}