import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/scenario_config/presentation/screens/scenario_config_screen.dart';
import 'screens/bdgd_import/bdgd_import_screen.dart';

void main() {
  runApp(const TecsysApp());
}

class TecsysApp extends StatelessWidget {
  final bool initialLoginMode;
  const TecsysApp({super.key, this.initialLoginMode = true});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tecsys - Planejamento Inteligente de RF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: LoginScreen(initialLoginMode: initialLoginMode),
      routes: {
        '/login': (_) => LoginScreen(initialLoginMode: initialLoginMode),
        '/bdgd-import': (_) => const BdgdImportScreen(),
        '/scenario': (_) => const ScenarioConfigScreen(),
      },
    );
  }
}

typedef MyApp = TecsysApp;
