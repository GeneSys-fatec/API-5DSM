import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/bdgd_import/presentation/screens/bdgd_import_screen.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/file_upload_dropzone.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'auth_token': 'dummy-token'});
  });

  group('SYS-28 Frontend Widget Tests', () {
    testWidgets('FileUploadDropzone exibe os formatos suportados (.csv, .xls, .xlsx, .json) e layout mínimo',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FileUploadDropzone(
              selectedFile: null,
              isPicking: false,
              errorMessage: null,
              onPick: () {},
              onClear: () {},
            ),
          ),
        ),
      );

      expect(
        find.textContaining('Formatos suportados: BDGD (.zip), Planilhas (.csv, .xls, .xlsx) e JSON (.json).'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Layout mínimo: identificador, tipo_ativo, latitude e longitude.'),
        findsOneWidget,
      );
    });

    testWidgets('BdgdImportScreen renderiza secao de Modelos de Arquivo (Templates) com CSV, Excel e JSON',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: BdgdImportScreen(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Modelos de Arquivo (Templates):'), findsOneWidget);
      expect(find.text('Modelo CSV'), findsOneWidget);
      expect(find.text('Modelo Excel (.xlsx)'), findsOneWidget);
      expect(find.text('Modelo JSON'), findsOneWidget);
    });

    testWidgets('Ao clicar em Modelo CSV, exibe modal com instrucoes e exemplo de campos minimos',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: BdgdImportScreen(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Modelo CSV'));
      await tester.pumpAndSettle();

      expect(find.text('Modelo de Exemplo (CSV)'), findsOneWidget);
      expect(find.textContaining('Campos obrigatórios: identificador, tipo_ativo, latitude, longitude.'), findsOneWidget);
      expect(find.textContaining('POS-001,POSTE,-23.550520,-46.633308'), findsOneWidget);
      expect(find.text('Copiar Exemplo'), findsOneWidget);
    });
  });
}
