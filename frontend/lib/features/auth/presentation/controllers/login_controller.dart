import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool get isLoginMode => _isLoginMode;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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

    await Future.delayed(const Duration(milliseconds: 1200));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }
}
