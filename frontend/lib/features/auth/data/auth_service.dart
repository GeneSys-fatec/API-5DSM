import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import 'auth_models.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

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

      await _saveToken(result.token);
      await _saveUser(result.user);

      return result;
    }

    String errorMessage = 'Erro ao realizar login.';
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      if (errorData.containsKey('error')) {
        errorMessage = errorData['error'] as String;
      }
    } catch (_) {}

    throw AuthException(errorMessage);
  }

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

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserData?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return UserData.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(UserData user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
