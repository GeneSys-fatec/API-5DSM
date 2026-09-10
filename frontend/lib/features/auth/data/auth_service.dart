import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import 'auth_models.dart';

/// Serviço isolado de autenticação.
///
/// Toda comunicação com a API de auth passa por esta classe.
/// O componente de tela (LoginScreen) e o controller nunca chamam
/// [http.post] diretamente.
///
/// Quando o backend mudar, a única alteração aqui é o [ApiConfig.baseUrl].
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Autentica o usuário com email e senha.
  ///
  /// Retorna [LoginResult] em caso de sucesso.
  /// Lança [AuthException] com mensagem amigável em caso de erro.
  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (e) {
      throw AuthException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = LoginResult.fromJson(data);

      // Persiste token e dados do usuário
      await _saveToken(result.token);
      await _saveUser(result.user);

      return result;
    }

    // Extrai mensagem de erro do backend
    String errorMessage = 'Erro ao realizar login.';
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      if (errorData.containsKey('error')) {
        errorMessage = errorData['error'] as String;
      }
    } catch (_) {
      // Usa mensagem padrão
    }

    throw AuthException(errorMessage);
  }

  /// Busca os dados do usuário autenticado.
  Future<UserData> getMe() async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Sessão expirada. Faça login novamente.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/me');

    final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw AuthException(
        'Não foi possível conectar ao servidor.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserData.fromJson(data);
    }

    if (response.statusCode == 401) {
      await clearSession();
      throw AuthException('Sessão expirada. Faça login novamente.');
    }

    throw AuthException('Erro ao buscar dados do usuário.');
  }

  /// Retorna o token salvo, ou null se não houver sessão.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Retorna os dados do usuário salvos localmente.
  Future<UserData?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return UserData.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  /// Verifica se há uma sessão ativa (token salvo).
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  /// Limpa a sessão (logout).
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // --- Métodos privados ---

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}

/// Exceção de autenticação com mensagem amigável para exibir na UI.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
