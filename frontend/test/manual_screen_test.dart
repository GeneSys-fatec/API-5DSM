import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/manual/models/manual_content.dart';
import 'package:frontend/features/manual/presentation/screens/manual_screen.dart';
import 'package:frontend/features/manual/presentation/widgets/contextual_help_dialog.dart';

Widget createTestApp({Widget? child, RouteFactory? onGenerateRoute}) {
  return MaterialApp(
    home: child,
    onGenerateRoute: onGenerateRoute,
    routes: {
      '/manual': (_) => const ManualScreen(),
      '/scenario': (_) => const Scaffold(body: Text('Tela Cenário')),
      '/bdgd-import': (_) => const Scaffold(body: Text('Tela BDGD')),
    },
  );
}

void main() {
  group('ManualContent Domain Tests', () {
    test('Contém as 6 seções obrigatórias no catálogo', () {
      expect(kManualSections.length, 6);
      expect(kManualSections.any((s) => s.id == 'auth'), isTrue);
      expect(kManualSections.any((s) => s.id == 'bdgd-import'), isTrue);
      expect(kManualSections.any((s) => s.id == 'area-delimitation'), isTrue);
      expect(kManualSections.any((s) => s.id == 'rf-config'), isTrue);
      expect(kManualSections.any((s) => s.id == 'results-kpis'), isTrue);
      expect(kManualSections.any((s) => s.id == 'save-export'), isTrue);
    });

    test('Mapeia rotas para as seções contextuais corretas', () {
      expect(getManualSectionForRoute('/login').id, 'auth');
      expect(getManualSectionForRoute('/bdgd-import').id, 'bdgd-import');
      expect(getManualSectionForRoute('/scenario').id, 'area-delimitation');
      expect(getManualSectionForRoute('/scenario/rf').id, 'rf-config');
      expect(getManualSectionForRoute('/results').id, 'results-kpis');
      expect(getManualSectionForRoute('/history').id, 'save-export');
    });

    test('Localiza seções por ID', () {
      final section = findManualSectionById('rf-config');
      expect(section, isNotNull);
      expect(section!.title, 'Parâmetros de RF (Etapa 2)');
      expect(findManualSectionById('id-inexistente'), isNull);
    });
  });

  group('ManualScreen Widget Tests', () {
    testWidgets('Renderiza banner de cabeçalho, campo de busca e seções', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ManualScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Manual do Usuário & Guia de Operação'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('SEÇÕES DO MANUAL'), findsOneWidget);
      expect(find.text('Cadastro e Login'), findsWidgets);
    });

    testWidgets('Alterna de seção ao clicar na barra lateral', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ManualScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Importação de BDGD').first);
      await tester.pumpAndSettle();

      expect(find.text('Carga e ingestão de ativos elétricos e bases geoespaciais'), findsOneWidget);
      expect(find.text('Selecionar o Arquivo da Concessionária'), findsOneWidget);
    });

    testWidgets('Filtra seções ao digitar no campo de busca', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ManualScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Okumura');
      await tester.pumpAndSettle();

      expect(find.text('Parâmetros de RF (Etapa 2)'), findsWidgets);
    });

    testWidgets('Avança e retrocede entre seções pelos botões de paginação', (tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ManualScreen()));
      await tester.pumpAndSettle();

      final scrollableFinder = find.byType(Scrollable).first;
      final nextButton = find.widgetWithText(ElevatedButton, 'Importação de BDGD');
      await tester.scrollUntilVisible(nextButton, 200, scrollable: scrollableFinder);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      expect(find.text('Carga e ingestão de ativos elétricos e bases geoespaciais'), findsOneWidget);

      final prevButton = find.widgetWithText(OutlinedButton, 'Cadastro e Login');
      await tester.scrollUntilVisible(prevButton, -200, scrollable: scrollableFinder);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      expect(find.text('Acesso seguro à plataforma e gerenciamento de perfil'), findsOneWidget);
    });

    testWidgets('Renderiza em layout mobile com chips horizontais', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(child: const ManualScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(FilterChip), findsWidgets);
    });
  });

  group('ContextualHelpDialog Widget Tests', () {
    testWidgets('Abre o pop-up contextual com abas e fecha no botão Entendi', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final section = getManualSectionForRoute('/scenario');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => showContextualHelpDialog(ctx, route: '/scenario'),
                child: const Text('Abrir Ajuda'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abrir Ajuda'));
      await tester.pumpAndSettle();

      expect(find.text('TUTORIAL CONTEXTUAL'), findsOneWidget);
      expect(find.text(section.title), findsOneWidget);
      expect(find.text('Passo a Passo'), findsOneWidget);
      expect(find.text('Campos & Controles'), findsOneWidget);
      expect(find.text('Dicas & Regras'), findsOneWidget);

      await tester.tap(find.text('Campos & Controles'));
      await tester.pumpAndSettle();

      expect(find.text('Latitude Central'), findsOneWidget);

      await tester.tap(find.text('Dicas & Regras'));
      await tester.pumpAndSettle();

      expect(find.text('Dicas de Utilização'), findsOneWidget);

      await tester.tap(find.text('Entendi'));
      await tester.pumpAndSettle();

      expect(find.text('TUTORIAL CONTEXTUAL'), findsNothing);
    });

    testWidgets('ContextualHelpButton dispara o modal da tela', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContextualHelpButton(sectionId: 'bdgd-import'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('Importação de BDGD'), findsOneWidget);
      expect(find.text('TUTORIAL CONTEXTUAL'), findsOneWidget);
    });
  });
}
