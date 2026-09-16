import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('TecsysApp renders login screen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TecsysApp());
    expect(find.text('Acesse a Plataforma'), findsOneWidget);
    expect(find.text('Entrar no Sistema'), findsOneWidget);
  });
}
