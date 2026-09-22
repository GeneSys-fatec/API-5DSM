import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../models/scenario_history_models.dart';

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
        value: '${results.coveragePercent}%',
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

    final isMobile = Responsive.isMobile(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 1 : cards.length,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: isMobile ? 3.2 : 1.8,
      children: cards,
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

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.suffix,
    this.footer,
    this.footerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      height: 1.25,
                    ),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primaryDark),
                ),
              ],
            ),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    suffix!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            if (footer != null)
              Text(
                footer!,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: footerColor ?? Colors.grey.shade600,
                ),
              ),
          ],
        ),
      ),
    );
  }
}