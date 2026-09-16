import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/bdgd_import/presentation/screens/bdgd_import_screen.dart';

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
        '/bdgd-import': (_) => const BdgdImportScreen(),
        // '/scenario': (_) => const ScenarioScreen(),
        // '/results': (_) => const ResultsScreen(),
        // '/history': (_) => const HistoryScreen(),
        // '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}

typedef MyApp = TecsysApp;