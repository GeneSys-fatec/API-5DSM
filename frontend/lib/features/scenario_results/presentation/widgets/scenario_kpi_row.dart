import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../models/scenario_results_models.dart';

class ScenarioKpiRow extends StatelessWidget {
  final SimulationScenario scenario;

  const ScenarioKpiRow({super.key, required this.scenario});

  @override
  Widget build(BuildContext context) {
    final results = scenario.results;

    final cards = [
      _KpiCard(
        icon: Icons.donut_large,
        label: 'Cobertura Total',
        value: '${results.coveragePercent.toStringAsFixed(1)}%',
        progress: results.coveragePercent / 100,
      ),
      _KpiCard(
        icon: Icons.wifi_tethering,
        label: 'Gateways Ótimos',
        value: '${scenario.parameters.gatewayCount}',
        suffix: 'unidades',
      ),
      _KpiCard(
        icon: Icons.settings_input_antenna,
        label: 'Ativos Conectados',
        value: '${results.connectedAssets} / ${results.totalAssets}',
        footer: results.assetsInShadow > 0
            ? '${results.assetsInShadow} em sombra'
            : null,
        footerColor: Colors.red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 560 ? 1 : cards.length;
        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 116,
          ),
          children: cards,
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? suffix;
  final String? footer;
  final Color? footerColor;
  final double? progress;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.footer,
    this.footerColor,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: AppColors.primaryDark),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        suffix!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0).toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.primaryLight,
                      color: AppColors.primaryPurple,
                    ),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    footer!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: footerColor ?? Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}