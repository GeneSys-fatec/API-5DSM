import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const TecsysApp());
}

class TecsysApp extends StatelessWidget {
  const TecsysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tecsys - Planejamento Inteligente de RF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
