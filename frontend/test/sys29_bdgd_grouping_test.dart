import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/features/bdgd_import/models/bdgd_base.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/bases_section.dart';
import 'package:frontend/features/bdgd_import/presentation/widgets/bases_table.dart';

BdgdBase _base(String distribuidora, String? regiao, {String? id, int ativos = 100}) {
  return BdgdBase(
    id: id,
    distribuidora: distribuidora,
    regiao: regiao,
    versaoBase: '2024.Q1 (Módulo 8)',
    ativosMapeados: ativos,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.success,
    status: 'concluido',
    fileName: 'base.zip',
  );
}

void main() {
  group('groupBasesByRegionAndDistributor', () {
    test('agrupa por região e distribuidora em ordem alfabética', () {
      final groups = groupBasesByRegionAndDistributor([
        _base('Zeta Energia', 'Sul'),
        _base('Alfa Energia', 'Norte'),
        _base('Beta Energia', 'Norte'),
      ]);

      expect(groups.map((g) => g.region).toList(), ['Norte', 'Sul']);
      expect(
        groups.first.distributors.map((d) => d.distributor).toList(),
        ['Alfa Energia', 'Beta Energia'],
      );
      expect(groups.first.distributors.first.bases.single.distribuidora, 'Alfa Energia');
    });

    test('usa rótulo padrão quando a região não é informada', () {
      final groups = groupBasesByRegionAndDistributor([_base('Sem Regiao', null)]);

      expect(groups.single.region, 'Região não informada');
    });

    test('agrupa múltiplas bases da mesma distribuidora', () {
      final groups = groupBasesByRegionAndDistributor([
        _base('Alfa Energia', 'Norte', id: '1'),
        _base('Alfa Energia', 'Norte', id: '2'),
      ]);

      expect(groups.single.distributors.single.bases, hasLength(2));
    });

    test('retorna lista vazia quando não há bases', () {
      expect(groupBasesByRegionAndDistributor(const []), isEmpty);
    });
  });

  testWidgets('BasesSection exibe cabeçalhos de região e distribuidora', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BasesSection(
              bases: [
                BdgdBase(
                  distribuidora: 'Alfa Energia',
                  regiao: 'Norte',
                  versaoBase: '2024.Q1',
                  ativosMapeados: 100,
                  projecao: 'SIRGAS 2000 / UTM 23S',
                  tagColor: AppColors.success,
                  status: 'concluido',
                ),
                BdgdBase(
                  distribuidora: 'Beta Energia',
                  regiao: 'Sul',
                  versaoBase: '2024.Q1',
                  ativosMapeados: 50,
                  projecao: 'SIRGAS 2000 / UTM 23S',
                  tagColor: AppColors.info,
                  status: 'concluido',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Norte'), findsOneWidget);
    expect(find.text('Sul'), findsOneWidget);
    expect(find.textContaining('Alfa Energia'), findsWidgets);
    expect(find.textContaining('Beta Energia'), findsWidgets);
  });

  testWidgets('BasesSection exibe mensagem específica quando filtros não retornam bases', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BasesSection(
            bases: [],
            emptyMessage: 'Nenhuma base encontrada para os filtros selecionados.',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Nenhuma base encontrada para os filtros selecionados.'),
      findsOneWidget,
    );
  });

  testWidgets('BasesSection dispara onEditBase ao acionar edição de grupo', (tester) async {
    BdgdBase? edited;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BasesSection(
            bases: [
              _base('Alfa Energia', 'Norte', id: 'base-1'),
            ],
            onEditBase: (base) => edited = base,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Editar grupo'));
    await tester.pump();

    expect(edited?.id, 'base-1');
    expect(edited?.regiao, 'Norte');
  });

  testWidgets('BasesTable exibe ação de edição no layout de tabela', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    BdgdBase? edited;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BasesTable(
            bases: [_base('Alfa Energia', 'Norte', id: 'base-1')],
            onEditBase: (base) => edited = base,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pump();

    expect(edited?.id, 'base-1');
  });
}
