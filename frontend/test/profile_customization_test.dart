import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/core/widgets/app_header.dart';
import 'package:frontend/core/widgets/app_navbar.dart';
import 'package:frontend/features/auth/data/auth_models.dart';
import 'package:frontend/features/auth/data/auth_service.dart';
import 'package:frontend/features/settings/presentation/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'mock-token',
      'auth_user': '{"id":1,"nome":"Maria Silva","email":"maria@tecsys.com","role":"USUARIO","avatarUrl":null}',
    });
    AuthService.currentUserNotifier.value = const UserData(
      id: 1,
      name: 'Maria Silva',
      email: 'maria@tecsys.com',
      role: 'USUARIO',
      avatarUrl: null,
    );
  });

  group('Personalização de Perfil e Navegação', () {
    testWidgets('AppHeader exibe nome e iniciais do usuário logado sem botão de sair no topo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: AppHeader(
              title: 'Teste',
              userName: 'Carlos Silva',
              userEmail: 'carlos@tecsys.com',
            ),
          ),
        ),
      );

      expect(find.text('Carlos Silva'), findsOneWidget);
      expect(find.text('carlos@tecsys.com'), findsOneWidget);
      expect(find.text('CS'), findsOneWidget);
      expect(find.text('Usuário'), findsNothing);
      expect(find.text('Sair'), findsNothing);
    });

    testWidgets('AppNavbar exibe opção de Sair da conta embaixo', (tester) async {
      bool logoutCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppNavbar(
              currentRoute: '/settings',
              onSelect: (_) {},
              onLogout: () {
                logoutCalled = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Sair da conta'), findsOneWidget);
      await tester.tap(find.text('Sair da conta'));
      expect(logoutCalled, isTrue);
    });

    testWidgets('SettingsScreen exibe perfil com avatar dinâmico de iniciais e preserva informações do sistema', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Perfil do Usuário'), findsOneWidget);
      expect(find.text('MS'), findsNWidgets(2));
      expect(find.text('Nome de exibição'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(find.text('Sair da Conta'), findsOneWidget);

      expect(find.text('URL da foto / avatar'), findsNothing);
      expect(find.text('Informações do Sistema'), findsOneWidget);
      expect(find.text('Servidor de API'), findsOneWidget);
    });
  });
}
