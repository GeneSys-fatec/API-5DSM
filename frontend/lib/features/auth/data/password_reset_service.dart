import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_config.dart';

class PasswordResetService {
  /// Solicita o link de recuperação de senha.
  /// Nunca lança exceção por e-mail não encontrado (backend é genérico).
  Future<void> requestReset(String email) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/password-reset/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );
    } catch (_) {
      // Conexão falhou — lança para o controller tratar
      throw const PasswordResetException(
          'Não foi possível conectar ao servidor. Verifique sua conexão.');
    }
  }

  /// Verifica se o token recebido por e-mail ainda é válido.
  /// Lança [PasswordResetException] com code='INVALID_RESET_TOKEN' quando inválido.
  Future<void> validateToken(String token) async {
    final http.Response response;
    try {
      response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/auth/password-reset/validate?token=${Uri.encodeQueryComponent(token)}'),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (_) {
      throw const PasswordResetException(
          'Não foi possível conectar ao servidor.');
    }

    if (response.statusCode == 200) return;

    String errorMessage = 'Token inválido ou expirado.';
    String? errorCode;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = (data['error'] ?? data['message'] ?? errorMessage) as String;
      errorCode = data['code'] as String?;
    } catch (_) {}
    throw PasswordResetException(errorMessage, code: errorCode);
  }

  /// Confirma a nova senha usando o token recebido por e-mail.
  Future<void> confirmReset({
    required String token,
    required String novaSenha,
    required String confirmarNovaSenha,
  }) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/password-reset/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'novaSenha': novaSenha,
          'confirmarNovaSenha': confirmarNovaSenha,
        }),
      );
    } catch (_) {
      throw const PasswordResetException(
          'Não foi possível conectar ao servidor.');
    }

    if (response.statusCode == 200) return;

    String errorMessage = 'Não foi possível redefinir a senha.';
    String? errorCode;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = (data['error'] ?? data['message'] ?? errorMessage) as String;
      errorCode = data['code'] as String?;
    } catch (_) {}
    throw PasswordResetException(errorMessage, code: errorCode);
  }
}

class PasswordResetException implements Exception {
  final String message;
  final String? code;
  const PasswordResetException(this.message, {this.code});

  @override
  String toString() => message;
}
