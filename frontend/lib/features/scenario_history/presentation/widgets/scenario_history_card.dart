import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/scenario_models.dart';

const double _kInlineActionsMinWidth = 1050;

const double _kFullWidthActionsMaxWidth = 430;

const double _kShowIconMinWidth = 360;

class ScenarioHistoryCard extends StatelessWidget {
  final ScenarioSummary scenario;
  final bool isMutating;
  final bool isSelected;
  final VoidCallback? onToggleSelect;
  final VoidCallback onViewDetails;
  final VoidCallback? onViewResult;
  final VoidCallback? onReuseConfig;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const ScenarioHistoryCard({
    super.key,
    required this.scenario,
    required this.isMutating,
    this.isSelected = false,
    this.onToggleSelect,
    required this.onViewDetails,
    this.onViewResult,
    this.onReuseConfig,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showIcon = width >= _kShowIconMinWidth;
        final inlineActions = width >= _kInlineActionsMinWidth;
        final fullWidthActions = width < _kFullWidthActionsMaxWidth;

        final details = _ScenarioDetails(scenario: scenario, compact: fullWidthActions);

        final Widget contentWithSelection = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onToggleSelect != null)
              Padding(
                padding: const EdgeInsets.only(right: 8, top: 4),
                child: InkWell(
                  onTap: onToggleSelect,
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(
                    isSelected
                        ? Icons.check_box_rounded
                        : Icons.check_box_outline_blank_rounded,
                    color: isSelected
                        ? AppColors.primaryPurple
                        : AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
            if (showIcon) ...[
              const _ScenarioIcon(),
              const SizedBox(width: 14),
            ],
            Expanded(child: details),
          ],
        );

        final actions = _CardActions(
          isMutating: isMutating,
          fullWidth: fullWidthActions,
          onViewDetails: onViewDetails,
          onViewResult: onViewResult,
          onReuseConfig: onReuseConfig,
          onDuplicate: onDuplicate,
          onDelete: onDelete,
        );

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryPurple.withValues(alpha: 0.7)
                  : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: inlineActions
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: contentWithSelection),
                    const SizedBox(width: 16),
                    Flexible(child: actions),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    contentWithSelection,
                    const SizedBox(height: 12),
                    actions,
                  ],
                ),
        );
      },
    );
  }
}

class _ScenarioDetails extends StatelessWidget {
  final ScenarioSummary scenario;
  final bool compact;

  const _ScenarioDetails({required this.scenario, required this.compact});

  @override
  Widget build(BuildContext context) {
    final coverage = scenario.totalCoveragePct;
    final isHighCoverage = coverage != null && coverage >= 90.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                scenario.name.isEmpty ? 'Cenário ${scenario.id}' : scenario.name,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: compact ? 14 : 15,
                  height: 1.25,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (coverage != null) ...[
              const SizedBox(width: 8),
              _CoverageBadge(coverage: coverage, isHighCoverage: isHighCoverage),
            ],
          ],
        ),
        const SizedBox(height: 6),
        _MetaRow(
          icon: Icons.location_on_outlined,
          text: scenario.regionName.isEmpty ? 'Região não informada' : scenario.regionName,
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _MetaRow(
              icon: Icons.router_outlined,
              text: '${scenario.usedGatewayCount ?? 0} Gateways',
            ),
            if (scenario.totalEstimatedCost != null)
              _MetaRow(
                icon: Icons.payments_outlined,
                text: _formatAmount(scenario.totalEstimatedCost!),
              ),
            if (scenario.coverageTargetPct != null)
              _MetaRow(
                icon: Icons.flag_outlined,
                text: 'Meta ${scenario.coverageTargetPct!.toStringAsFixed(1)}%',
              ),
            if (scenario.processedAt != null)
              _MetaRow(
                icon: Icons.schedule_rounded,
                text: DateFormat('dd/MM/yyyy HH:mm').format(scenario.processedAt!.toLocal()),
              ),
          ],
        ),
      ],
    );
  }

  String _formatAmount(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}

class _CardActions extends StatelessWidget {
  final bool isMutating;
  final bool fullWidth;
  final VoidCallback onViewDetails;
  final VoidCallback? onViewResult;
  final VoidCallback? onReuseConfig;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _CardActions({
    required this.isMutating,
    required this.fullWidth,
    required this.onViewDetails,
    this.onViewResult,
    this.onReuseConfig,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final viewResult = onViewResult != null
        ? ElevatedButton.icon(
            onPressed: isMutating ? null : onViewResult,
            icon: const Icon(Icons.bar_chart_rounded, size: 16),
            label: const Text('Ver Resultado'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              minimumSize: Size(0, fullWidth ? 44 : 40),
              padding: EdgeInsets.symmetric(horizontal: fullWidth ? 12 : 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        : null;

    final details = _action(
      context,
      icon: Icons.visibility_outlined,
      label: 'Ver Detalhes',
      color: AppColors.primaryPurple,
      onPressed: isMutating ? null : onViewDetails,
    );

    final reuse = onReuseConfig != null
        ? _action(
            context,
            icon: Icons.tune_rounded,
            label: 'Reaproveitar',
            color: AppColors.textSecondary,
            borderColor: AppColors.cardBorder,
            onPressed: isMutating ? null : onReuseConfig,
          )
        : null;

    final duplicate = _action(
      context,
      icon: Icons.copy_all_outlined,
      label: 'Duplicar',
      color: AppColors.textSecondary,
      borderColor: AppColors.cardBorder,
      onPressed: isMutating ? null : onDuplicate,
    );

    final remove = _action(
      context,
      icon: Icons.delete_outline_rounded,
      label: 'Excluir',
      color: AppColors.vermelhoErro,
      borderColor: AppColors.vermelhoErro,
      onPressed: isMutating ? null : onDelete,
    );

    if (fullWidth) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (viewResult != null) ...[
            viewResult,
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Expanded(child: details),
              if (reuse != null) ...[
                const SizedBox(width: 8),
                Expanded(child: reuse),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: duplicate),
              const SizedBox(width: 8),
              Expanded(child: remove),
            ],
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (viewResult != null) viewResult,
        details,
        if (reuse != null) reuse,
        duplicate,
        remove,
      ],
    );
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    Color? borderColor,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.4),
        side: BorderSide(color: borderColor ?? color),
        minimumSize: Size(0, fullWidth ? 44 : 40),
        padding: EdgeInsets.symmetric(horizontal: fullWidth ? 12 : 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _ScenarioIcon extends StatelessWidget {
  const _ScenarioIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleUltraLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primaryPurple, size: 24),
    );
  }
}

class _CoverageBadge extends StatelessWidget {
  final double coverage;
  final bool isHighCoverage;

  const _CoverageBadge({required this.coverage, required this.isHighCoverage});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isHighCoverage ? AppColors.statusGreenLight : AppColors.badgeYellowLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${coverage.toStringAsFixed(1)}% Cobertura',
        maxLines: 1,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isHighCoverage ? AppColors.statusGreen : AppColors.badgeYellow,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
