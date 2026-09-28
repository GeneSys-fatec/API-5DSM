import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive.dart';
import '../../models/bdgd_base.dart';
import 'base_cards_list.dart';
import 'bases_table.dart';

class BasesSection extends StatelessWidget {
  final List<BdgdBase> bases;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String? error;

  const BasesSection({
    super.key,
    required this.bases,
    this.isLoading = false,
    this.onRefresh,
    this.error,
  });

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
                    const Flexible(
                      child: Text(
                        'Bases de Dados Geográficas Importadas',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                    if (onRefresh != null) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 20),
                        tooltip: 'Recarregar bases',
                        onPressed: isLoading ? null : onRefresh,
                      ),
                    ],
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${formatThousands(totalAtivos)} Ativos de Rede · ${bases.length} Base(s)',
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
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Carregando bases do servidor...', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              )
            else if (error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        error!,
                        style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (onRefresh != null)
                      TextButton(
                        onPressed: onRefresh,
                        child: const Text('Tentar novamente'),
                      ),
                  ],
                ),
              )
            else if (bases.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.folder_open_rounded, size: 40, color: AppColors.textMuted),
                    SizedBox(height: 8),
                    Text(
                      'Nenhuma base importada ainda.',
                      style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Envie um arquivo .zip acima para salvar na pasta uploads e iniciar o processamento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              useTable ? BasesTable(bases: bases) : BaseCardsList(bases: bases),
          ],
        ),
      ),
    );
  }
}