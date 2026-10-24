import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/scenario_models.dart';

class ScenarioComparisonDialog extends StatelessWidget {
  final List<ScenarioSummary> scenarios;
  final ValueChanged<ScenarioSummary>? onViewResult;

  const ScenarioComparisonDialog({
    super.key,
    required this.scenarios,
    this.onViewResult,
  });

  static Future<void> show(
    BuildContext context, {
    required List<ScenarioSummary> scenarios,
    ValueChanged<ScenarioSummary>? onViewResult,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black54,
      builder: (_) => ScenarioComparisonDialog(
        scenarios: scenarios,
        onViewResult: onViewResult,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isMobile = screenSize.width < 700;

    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 32,
        vertical: isMobile ? 16 : 32,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 1100,
          maxHeight: screenSize.height * 0.90,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryPurpleUltraLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.compare_arrows_rounded,
                      color: AppColors.primaryPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Comparação Lado a Lado',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '${scenarios.length} cenários selecionados para comparação de indicadores.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: scenarios.map((scenario) {
                      final coverage = scenario.totalCoveragePct;
                      final target = scenario.coverageTargetPct ?? 90.0;
                      final targetReached = coverage != null && coverage >= target;

                      return Container(
                        width: isMobile ? 260 : 300,
                        margin: const EdgeInsets.only(right: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: targetReached
                                ? AppColors.verdeSucesso.withValues(alpha: 0.4)
                                : AppColors.cardBorder,
                            width: targetReached ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    scenario.name.isEmpty
                                        ? 'Cenário ${scenario.id}'
                                        : scenario.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    scenario.regionName.isEmpty
                                        ? 'Região não informada'
                                        : scenario.regionName,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(height: 1),
                            const SizedBox(height: 14),
                            _ComparisonMetric(
                              label: 'Cobertura Alcançada',
                              value: coverage != null
                                  ? '${coverage.toStringAsFixed(1)}%'
                                  : 'N/A',
                              valueColor: targetReached
                                  ? AppColors.verdeSucesso
                                  : AppColors.primaryPurple,
                              badge: targetReached
                                  ? 'Meta atingida'
                                  : 'Abaixo da meta',
                              badgeColor: targetReached
                                  ? AppColors.verdeSucesso
                                  : AppColors.badgeYellow,
                            ),
                            const SizedBox(height: 12),
                            _ComparisonMetric(
                              label: 'Gateways Utilizados',
                              value: '${scenario.usedGatewayCount ?? 0} GWs',
                              subtext: scenario.maxGateways != null
                                  ? 'Máx. configurado: ${scenario.maxGateways}'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _ComparisonMetric(
                              label: 'Custo Total Estimado',
                              value: scenario.totalEstimatedCost != null
                                  ? currencyFormat.format(scenario.totalEstimatedCost)
                                  : 'N/A',
                            ),
                            const SizedBox(height: 12),
                            _ComparisonMetric(
                              label: 'Meta de Cobertura',
                              value: '${target.toStringAsFixed(0)}%',
                            ),
                            const SizedBox(height: 12),
                            _ComparisonMetric(
                              label: 'Modelo de Propagação',
                              value: scenario.propagationModel ?? 'Padrão RF',
                            ),
                            const SizedBox(height: 12),
                            _ComparisonMetric(
                              label: 'Data da Simulação',
                              value: scenario.processedAt != null
                                  ? dateFormat.format(scenario.processedAt!.toLocal())
                                  : 'N/A',
                            ),
                            const SizedBox(height: 20),
                            if (onViewResult != null)
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  onViewResult!(scenario);
                                },
                                icon: const Icon(Icons.bar_chart_rounded, size: 16),
                                label: const Text('Ver Resultado'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPurple,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subtext;
  final String? badge;
  final Color? badgeColor;

  const _ComparisonMetric({
    required this.label,
    required this.value,
    this.valueColor,
    this.subtext,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? AppColors.textPrimary,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.primaryPurple).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: badgeColor ?? AppColors.primaryPurple,
                  ),
                ),
              ),
          ],
        ),
        if (subtext != null) ...[
          const SizedBox(height: 2),
          Text(
            subtext!,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
