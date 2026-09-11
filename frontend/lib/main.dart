import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/bdgd_import/bdgd_import_screen.dart';

void main() {
  runApp(const TecsysApp());
}

class TecsysApp extends StatelessWidget {
  const TecsysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TECSYS · BDGD',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: '/bdgd-import',
      routes: {
        '/bdgd-import': (_) => const BdgdImportScreen(),
        // '/scenario': (_) => const ScenarioScreen(),
        // '/results': (_) => const ResultsScreen(),
        // '/history': (_) => const HistoryScreen(),
        // '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}