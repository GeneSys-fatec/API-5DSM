import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/bdgd_import/models/bdgd_base.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/base_cards_list.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/bases_section.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/bases_table.dart';

void main() {
  const base1 = BdgdBase(
    id: '1',
    distribuidora: 'CPFL Paulista',
    regiao: 'Sudeste',
    versaoBase: '2024.Q1',
    ativosMapeados: 53650,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.primary,
    status: 'concluido',
  );

  const base2 = BdgdBase(
    id: '2',
    distribuidora: 'Enel SP',
    regiao: 'Sudeste',
    versaoBase: '2024.Q2',
    ativosMapeados: 12400,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.success,
    status: 'concluido',
  );

  group('SYS-39 - Simplificação da tela de importação da BDGD', () {
    testWidgets('BasesSection exibe somente a quantidade de bases no contador e não exibe Ativos de Rede', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: BasesSection(
                bases: [base1, base2],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Deve exibir apenas a quantidade de bases
      expect(find.text('2 Base(s)'), findsOneWidget);
      // Não deve exibir Ativos de Rede no contador
      expect(find.textContaining('Ativos de Rede'), findsNothing);
    });

    testWidgets('BasesSection atualiza o contador reativamente ao adicionar ou remover bases', (tester) async {
      List<BdgdBase> currentBases = [base1, base2];

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    ElevatedButton(
                      key: const Key('remove_base_btn'),
                      onPressed: () {
                        setState(() {
                          currentBases = [base1];
                        });
                      },
                      child: const Text('Remover'),
                    ),
                    Expanded(
                      child: BasesSection(bases: currentBases),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 Base(s)'), findsOneWidget);

      // Simula exclusão de uma base
      await tester.tap(find.byKey(const Key('remove_base_btn')));
      await tester.pumpAndSettle();

      expect(find.text('1 Base(s)'), findsOneWidget);
    });

    testWidgets('BasesTable não exibe coluna nem valor de Projeção / Datum', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BasesTable(
              bases: [base1],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cabeçalho da coluna removida
      expect(find.text('PROJEÇÃO / DATUM'), findsNothing);
      expect(find.text('PROJEÇÃO'), findsNothing);

      // Valor de projeção não deve estar visível na tabela
      expect(find.text('SIRGAS 2000 / UTM 23S'), findsNothing);

      // As outras colunas essenciais continuam existindo
      expect(find.text('DISTRIBUIDORA / REGIONAL'), findsOneWidget);
      expect(find.text('REFERÊNCIA / ARQUIVO'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('ATIVOS MAPEADOS'), findsOneWidget);
      expect(find.text('AÇÃO'), findsOneWidget);
    });

    testWidgets('BaseCardsList (mobile) não exibe projeção', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BaseCardsList(
              bases: [base1],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Não deve exibir texto de projeção
      expect(find.text('SIRGAS 2000 / UTM 23S'), findsNothing);
      // Deve exibir os dados essenciais da base
      expect(find.text('CPFL Paulista'), findsOneWidget);
      expect(find.textContaining('2024.Q1'), findsOneWidget);
    });
  });
}
