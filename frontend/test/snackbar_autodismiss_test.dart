import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _showSnackBar(WidgetTester tester, {required bool persist}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Cenário salvo'),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                persist: persist,
                action: SnackBarAction(label: 'Ver Histórico', onPressed: () {}),
              ),
            ),
            child: const Text('salvar'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('salvar'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  testWidgets('snackbar com acao e persist:false some sozinho apos a duracao', (tester) async {
    await _showSnackBar(tester, persist: false);
    expect(find.text('Cenário salvo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(find.text('Cenário salvo'), findsNothing);
  });

  testWidgets('snackbar com acao sem persist:false continua na tela (causa do bug)', (tester) async {
    await _showSnackBar(tester, persist: true);

    await tester.pump(const Duration(seconds: 30));
    await tester.pumpAndSettle();

    expect(find.text('Cenário salvo'), findsOneWidget);
  });
}
