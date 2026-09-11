import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../models/bdgd_base.dart';
import 'base_cards_list.dart';
import 'bases_table.dart';

class BasesSection extends StatelessWidget {
  final List<BdgdBase> bases;
  const BasesSection({super.key, required this.bases});

  int get totalAtivos => bases.fold(0, (sum, b) => sum + b.ativosMapeados);

  @override
  Widget build(BuildContext context) {
    final useTable = Responsive.isDesktop(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storage_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Bases de Dados Geográficas em Memória',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${formatThousands(totalAtivos)} Ativos de Rede',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            useTable ? BasesTable(bases: bases) : BaseCardsList(bases: bases),
          ],
        ),
      ),
    );
  }
}