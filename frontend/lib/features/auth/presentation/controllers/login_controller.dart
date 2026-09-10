import 'package:flutter/material.dart';
import '../../data/auth_service.dart';
import '../../data/auth_models.dart';

class LoginController extends ChangeNotifier {
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  LoginResult? _loginResult;

  final AuthService _authService = AuthService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool get isLoginMode => _isLoginMode;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  LoginResult? get loginResult => _loginResult;

  void setLoginMode(bool value) {
    if (_isLoginMode != value) {
      _isLoginMode = value;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  Future<bool> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      _errorMessage = 'Por favor, informe seu e-mail.';
      notifyListeners();
      return false;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _errorMessage = 'Formato de e-mail inválido.';
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Por favor, informe sua senha.';
      notifyListeners();
      return false;
    }

    if (password.length < 6) {
      _errorMessage = 'A senha deve ter pelo menos 6 caracteres.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loginResult = await _authService.login(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Erro inesperado. Tente novamente.';
      notifyListeners();
      return false;
    }
  }

  /// Verifica se já existe uma sessão ativa.
  Future<bool> checkExistingSession() async {
    return _authService.isLoggedIn();
  }

  /// Faz logout limpando a sessão.
  Future<void> logout() async {
    await _authService.clearSession();
    _loginResult = null;
    notifyListeners();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
