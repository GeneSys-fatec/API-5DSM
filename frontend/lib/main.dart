import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/scenario_config/presentation/screens/area_delimitation_screen.dart';
import 'features/scenario_config/presentation/screens/scenario_config_screen.dart';
import 'features/bdgd_import/presentation/screens/bdgd_import_screen.dart';
import 'features/scenario_history/presentation/screens/scenario_history_screen.dart';
import 'features/scenario_history/models/scenario_history_models.dart';

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
      initialRoute: '/',
      routes: {
        '/': (_) => LoginScreen(initialLoginMode: initialLoginMode),
        '/login': (_) => LoginScreen(initialLoginMode: initialLoginMode),
        '/register': (_) => const LoginScreen(initialLoginMode: false),
        '/bdgd-import': (_) => const BdgdImportScreen(),
        '/scenario': (_) => const AreaDelimitationScreen(),
        '/scenario/rf': (_) => const ScenarioConfigScreen(),
        '/results': (_) =>
            ScenarioHistoryScreen(scenario: kMockScenarios.first),
      },
    );
  }
}

typedef MyApp = TecsysApp;
