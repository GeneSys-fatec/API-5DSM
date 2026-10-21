import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/scenario_config/presentation/widgets/scenario_wizard_stepper.dart';

void main() {
  testWidgets('ScenarioWizardStepper does not display Datum but keeps Base and Motor GIS', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScenarioWizardStepper(
            currentStep: 1,
            baseName: 'CHESP (GOIAS)',
          ),
        ),
      ),
    );

    // Deve conter Base e Motor GIS Ativo
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Base: CHESP (GOIAS)'),
      ),
      findsOneWidget,
    );
    expect(find.text('Motor GIS Ativo'), findsOneWidget);

    // NÃO deve conter o campo Datum ou menções ao SIRGAS no cabeçalho
    expect(
      find.byWidgetPredicate(
        (widget) => widget is RichText && widget.text.toPlainText().contains('Datum'),
      ),
      findsNothing,
    );
    expect(find.textContaining('SIRGAS 2000'), findsNothing);
  });

  testWidgets('ScenarioWizardStepper is responsive on mobile', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ScenarioWizardStepper(
            currentStep: 1,
            baseName: 'CHESP (GOIAS)',
          ),
        ),
      ),
    );

    // No mobile, renderiza as etapas sem overflow
    expect(find.text('1. Delimitação de Área'), findsOneWidget);
    expect(find.text('2. Parâmetros de RF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
