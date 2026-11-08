import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import 'auth_models.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _refreshTokenKey = 'auth_refresh_token';

  static final ValueNotifier<UserData?> currentUserNotifier = ValueNotifier<UserData?>(null);

  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/auth/login');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
    } catch (_) {
      throw const AuthException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final result = LoginResult.fromJson(data);

      await _saveToken(result.token);
      if (result.refreshToken != null) {
        await _saveRefreshToken(result.refreshToken!);
      }
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

  Future<UserData> register(RegisterRequest request) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/users');

    final http.Response response;
    try {
      response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );
    } catch (_) {
      throw const AuthException(
        'Não foi possível conectar ao servidor. Verifique sua conexão.',
      );
    }

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserData.fromJson(data);
    }

    String errorMessage = 'Erro ao realizar cadastro.';
    try {
      final errorData = jsonDecode(response.body) as Map<String, dynamic>;
      if (errorData.containsKey('error')) {
        errorMessage = errorData['error'] as String;
      } else if (errorData.containsKey('message')) {
        errorMessage = errorData['message'] as String;
      } else if (errorData.containsKey('fields')) {
        final fields = errorData['fields'] as Map<String, dynamic>;
        if (fields.isNotEmpty) {
          errorMessage = fields.values.first.toString();
        }
      }
    } catch (_) {}

    throw AuthException(errorMessage);
  }

  Future<UserData> getMe() async {
    final token = await getToken();
    if (token == null) {
      throw const AuthException('Sessão expirada. Faça login novamente.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/users/me');

    final http.Response response;
    try {
      response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (_) {
      throw const AuthException('Não foi possível conectar ao servidor.');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final user = UserData.fromJson(data);
      await _saveUser(user);
      return user;
    }

    if (response.statusCode == 401) {
      await clearSession();
      throw const AuthException('Sessão expirada. Faça login novamente.');
    }

    throw const AuthException('Erro ao buscar dados do usuário.');
  }

  Future<UserData> updateProfile({required String name, String? avatarUrl}) async {
    final token = await getToken();
    if (token == null) {
      throw const AuthException('Sessão expirada. Faça login novamente.');
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nome': name,
        'avatarUrl': avatarUrl ?? '',
      }),
    );

    if (response.statusCode == 200) {
      final user = UserData.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      await _saveUser(user);
      return user;
    }

    String errorMessage = 'Erro ao atualizar o perfil.';
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = (data['error'] ?? data['message'] ?? errorMessage) as String;
    } catch (_) {}
    throw AuthException(errorMessage);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<UserData?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    final user = UserData.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    if (currentUserNotifier.value == null) {
      currentUserNotifier.value = user;
    }
    return user;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  Future<void> clearSession() async {
    currentUserNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUser(UserData user) async {
    currentUserNotifier.value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<void> _saveRefreshToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_refreshTokenKey, token);
  }

  Future<void> logout() async {
    final token = await getToken();
    final refreshToken = await getRefreshToken();

    try {
      if (token != null) {
        await http
            .post(
              Uri.parse('${ApiConfig.baseUrl}/auth/logout'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'refreshToken': refreshToken}),
            )
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
    } finally {
      await clearSession();
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
