import 'package:flutter/material.dart';

import 'auth/auth.dart';
import 'shared/colors.dart';

void main() {
  runApp(const TecsysApp());
}

class TecsysApp extends StatelessWidget {
  const TecsysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tecsys',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Cores.roxoPrincipal),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}

typedef MyApp = TecsysApp;
