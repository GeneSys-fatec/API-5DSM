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
  final ValueChanged<BdgdBase>? onSelectBase;
  final ValueChanged<BdgdBase>? onEditBase;
  final String? emptyMessage;

  const BasesSection({
    super.key,
    required this.bases,
    this.isLoading = false,
    this.onRefresh,
    this.error,
    this.onSelectBase,
    this.onEditBase,
    this.emptyMessage,
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
                child: Column(
                  children: [
                    const Icon(Icons.folder_open_rounded, size: 40, color: AppColors.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      emptyMessage ?? 'Nenhuma base importada ainda.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      emptyMessage != null
                          ? 'Ajuste ou limpe os filtros de região e distribuidora para ver mais resultados.'
                          : 'Envie um arquivo .zip acima para salvar na pasta uploads e iniciar o processamento.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              _buildGroupedBases(useTable),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedBases(bool useTable) {
    final regionGroups = groupBasesByRegionAndDistributor(bases);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final region in regionGroups) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.public_rounded, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    region.region,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final distributor in region.distributors) ...[
            Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 6),
              child: Text(
                '${distributor.distributor} · ${distributor.bases.length} base(s)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 16),
              child: useTable
                  ? BasesTable(bases: distributor.bases, onSelectBase: onSelectBase, onEditBase: onEditBase)
                  : BaseCardsList(bases: distributor.bases, onSelectBase: onSelectBase, onEditBase: onEditBase),
            ),
          ],
        ],
      ],
    );
  }
}

class BdgdRegionGroup {
  final String region;
  final List<BdgdDistributorGroup> distributors;

  const BdgdRegionGroup({required this.region, required this.distributors});
}

class BdgdDistributorGroup {
  final String distributor;
  final List<BdgdBase> bases;

  const BdgdDistributorGroup({required this.distributor, required this.bases});
}

List<BdgdRegionGroup> groupBasesByRegionAndDistributor(List<BdgdBase> bases) {
  final byRegion = <String, Map<String, List<BdgdBase>>>{};
  for (final base in bases) {
    final region = (base.regiao ?? '').trim();
    final regionKey = region.isEmpty ? 'Região não informada' : region;
    final distributorKey = base.distribuidora.trim();
    byRegion
        .putIfAbsent(regionKey, () => <String, List<BdgdBase>>{})
        .putIfAbsent(distributorKey, () => <BdgdBase>[])
        .add(base);
  }

  final regions = byRegion.keys.toList()..sort();
  return regions.map((region) {
    final distributors = byRegion[region]!.keys.toList()..sort();
    return BdgdRegionGroup(
      region: region,
      distributors: distributors
          .map(
            (distributor) => BdgdDistributorGroup(
              distributor: distributor,
              bases: byRegion[region]![distributor]!,
            ),
          )
          .toList(),
    );
  }).toList();
}