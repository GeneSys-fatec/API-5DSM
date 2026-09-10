import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('Renderiza a tela de cadastro e o banner institucional', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TecsysApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Planejamento Inteligente'), findsOneWidget);
    expect(find.textContaining('Integração Direta BDGD'), findsOneWidget);
    expect(find.textContaining('Otimização Heurística'), findsOneWidget);

    expect(find.text('Crie sua Conta'), findsOneWidget);
    expect(find.text('Nome Completo'), findsOneWidget);
    expect(find.text('E-mail'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Confirmar Senha'), findsOneWidget);
    expect(find.text('Cadastrar'), findsOneWidget);
    expect(find.text('Já tenho uma conta'), findsOneWidget);
  });

  testWidgets('Valida campos obrigatorios e senhas diferentes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TecsysApp());

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu nome completo'), findsOneWidget);
    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);

    final camposTexto = find.byType(TextFormField);
    await tester.enterText(camposTexto.at(0), 'Roberto Caldas');
    await tester.enterText(camposTexto.at(1), 'roberto@distribuidora.com.br');
    await tester.enterText(camposTexto.at(2), 'Senha123!');
    await tester.enterText(camposTexto.at(3), 'SenhaDiferente!');

    await tester.tap(find.text('Cadastrar'));
    await tester.pumpAndSettle();

    expect(find.text('As senhas não coincidem'), findsOneWidget);
  });

  testWidgets('Alterna entre as abas de entrar e criar conta', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TecsysApp());

    expect(find.text('Crie sua Conta'), findsOneWidget);

    await tester.tap(find.text('Entrar no Sistema'));
    await tester.pumpAndSettle();

    expect(find.text('Tela de Login em desenvolvimento'), findsOneWidget);

    await tester.tap(find.text('Criar Nova Conta'));
    await tester.pumpAndSettle();

    expect(find.text('Crie sua Conta'), findsOneWidget);
  });

  testWidgets('Alterna a visibilidade da senha pelo icone de olho', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TecsysApp());

    final iconesOlho = find.byTooltip('Ver senha');
    expect(iconesOlho, findsNWidgets(2));

    await tester.tap(iconesOlho.first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
    expect(find.byTooltip('Ver senha'), findsOneWidget);
  });
}
