import 'package:flutter/material.dart';

class LoginController extends ChangeNotifier {
  bool _isLoginMode = true;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _showSuccessMessage = false;
  String? _errorMessage;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool get isLoginMode => _isLoginMode;
  bool get isPasswordVisible => _isPasswordVisible;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  bool get isLoading => _isLoading;
  bool get showSuccessMessage => _showSuccessMessage;
  String? get errorMessage => _errorMessage;

  void setLoginMode(bool value) {
    if (_isLoginMode != value) {
      _isLoginMode = value;
      _errorMessage = null;
      _showSuccessMessage = false;
      notifyListeners();
    }
  }

  void togglePasswordVisibility() {
    _isPasswordVisible = !_isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    notifyListeners();
  }

  void setErrorMessage(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void setShowSuccessMessage(bool show) {
    _showSuccessMessage = show;
    notifyListeners();
  }

  Future<bool> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (_isLoginMode) {
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
    } else {
      final nome = nameController.text.trim();
      final confirmarSenha = confirmPasswordController.text;

      if (nome.isEmpty) {
        _errorMessage = 'Informe seu nome completo';
        notifyListeners();
        return false;
      }

      if (nome.split(' ').length < 2) {
        _errorMessage = 'Informe seu nome e sobrenome';
        notifyListeners();
        return false;
      }

      if (email.isEmpty) {
        _errorMessage = 'Informe seu e-mail';
        notifyListeners();
        return false;
      }

      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        _errorMessage = 'Informe um e-mail válido';
        notifyListeners();
        return false;
      }

      if (password.isEmpty) {
        _errorMessage = 'Informe sua senha';
        notifyListeners();
        return false;
      }

      if (password.length < 6) {
        _errorMessage = 'A senha deve conter no mínimo 6 caracteres';
        notifyListeners();
        return false;
      }

      if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d).+$').hasMatch(password)) {
        _errorMessage = 'Use letras e números';
        notifyListeners();
        return false;
      }

      if (confirmarSenha.isEmpty) {
        _errorMessage = 'Confirme sua senha';
        notifyListeners();
        return false;
      }

      if (confirmarSenha != password) {
        _errorMessage = 'As senhas não coincidem';
        notifyListeners();
        return false;
      }
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    _isLoading = false;
    if (!_isLoginMode) {
      _showSuccessMessage = true;
    }
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
