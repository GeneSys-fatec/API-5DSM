import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../scenario_results/presentation/widgets/scenario_map.dart';
import '../../data/models/scenario_models.dart';

const double _kCompactContentWidth = 520;

const double _kInfoTileWidth = 190;

const double _kMapHeight = 300;
const double _kMapHeightCompact = 220;

class ScenarioDetailSheet extends StatelessWidget {
  final ScenarioDetail detail;

  final bool enableMapTiles;

  const ScenarioDetailSheet({
    super.key,
    required this.detail,
    this.enableMapTiles = true,
  });

  static Future<void> show(
    BuildContext context,
    ScenarioDetail detail, {
    bool enableMapTiles = true,
  }) {
    return showDialog<void>(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black54,
      builder: (_) => ScenarioDetailSheet(
        detail: detail,
        enableMapTiles: enableMapTiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final isNarrowScreen = screenSize.width < 600;
    final maxHeight = screenSize.height * (isNarrowScreen ? 0.94 : 0.88);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isNarrowScreen ? 12 : 48,
        vertical: isNarrowScreen ? 12 : 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 900, maxHeight: maxHeight),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < _kCompactContentWidth;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(detail: detail, isCompact: isCompact),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isCompact ? 12 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _Section(
                          title: 'Parâmetros do Cenário',
                          isCompact: isCompact,
                          child: _InfoGrid(
                            items: [
                              _InfoItem('Meta de cobertura', _percent(detail.coverageTargetPct)),
                              _InfoItem('Máximo de gateways', '${detail.maxGateways ?? 0}'),
                              _InfoItem('Custo unitário', _currency(detail.gatewayUnitCost)),
                              _InfoItem('Tempo de processamento', _milliseconds(detail.processingTimeMs)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Parâmetros RF',
                          isCompact: isCompact,
                          child: detail.rfParameter == null
                              ? const _EmptyHint('Cenário salvo sem parâmetros RF.')
                              : _InfoGrid(
                                  items: [
                                    _InfoItem('Frequência', _mhz(detail.rfParameter!.frequencyMhz)),
                                    _InfoItem('Potência de transmissão', _dbm(detail.rfParameter!.transmitPowerDbm)),
                                    _InfoItem('Sensibilidade do receptor', _dbm(detail.rfParameter!.receiverSensitivityDbm)),
                                    _InfoItem('Altura do gateway', _meters(detail.rfParameter!.antennaHeightM)),
                                    _InfoItem('Altura do dispositivo', _meters(detail.rfParameter!.deviceHeightM)),
                                    _InfoItem('Ganho da antena', _dbi(detail.rfParameter!.antennaGainDbi)),
                                    _InfoItem('Perda de sistema', _db(detail.rfParameter!.systemLossDb)),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Resultados da Simulação',
                          isCompact: isCompact,
                          child: detail.indicator == null
                              ? const _EmptyHint('Cenário salvo ainda sem indicadores calculados.')
                              : _InfoGrid(
                                  items: [
                                    _InfoItem('Cobertura total', _percent(detail.indicator!.totalCoveragePct)),
                                    _InfoItem('Gateways utilizados', '${detail.indicator!.usedGatewayCount ?? 0}'),
                                    _InfoItem('Custo total estimado', _currency(detail.indicator!.totalEstimatedCost)),
                                    _InfoItem(
                                      'Meta atingida',
                                      detail.indicator!.targetReached ? 'Sim' : 'Não',
                                      valueColor: detail.indicator!.targetReached
                                          ? AppColors.statusGreen
                                          : AppColors.badgeYellow,
                                    ),
                                  ],
                                ),
                        ),
                        if (detail.indicator != null &&
                            detail.indicator!.coveragePctByAssetType.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Section(
                            title: 'Cobertura por Tipo de Ativo',
                            isCompact: isCompact,
                            child: _InfoGrid(
                              items: detail.indicator!.coveragePctByAssetType.entries
                                  .map((e) => _InfoItem(e.key, _percent(e.value)))
                                  .toList(),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _Section(
                          title: 'Gateways Selecionados (${detail.selectedGateways.length})',
                          isCompact: isCompact,
                          child: detail.selectedGateways.isEmpty
                              ? const _EmptyHint('Nenhum gateway selecionado neste cenário.')
                              : _GatewayList(gateways: detail.selectedGateways),
                        ),
                        if (detail.selectedGateways.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _Section(
                            title: 'Mapa de Cobertura',
                            isCompact: isCompact,
                            child: SizedBox(
                              height: isCompact ? _kMapHeightCompact : _kMapHeight,
                              child: ScenarioMap(
                                scenario: detail.toSimulationScenario(),
                                enableTiles: enableMapTiles,
                                showLayerToggleBar: false,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _currency(double? value) =>
      value == null ? '—' : _formatCurrency(value);

  static String _percent(double? value) =>
      value == null ? '—' : '${value.toStringAsFixed(1)}%';

  static String _mhz(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} MHz';

  static String _dbm(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} dBm';

  static String _dbi(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} dBi';

  static String _db(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} dB';

  static String _meters(double? value) => value == null ? '—' : '${value.toStringAsFixed(1)} m';

  static String _milliseconds(int? value) =>
      value == null ? '—' : '$value ms';

  static String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    return formatter.format(value);
  }
}

class _Header extends StatelessWidget {
  final ScenarioDetail detail;
  final bool isCompact;

  const _Header({required this.detail, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryPurpleUltraLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.wifi_tethering_rounded, color: AppColors.primaryPurple),
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.name.isEmpty ? 'Cenário ${detail.id}' : detail.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isCompact ? 15 : 17,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (detail.regionName.isNotEmpty) 'Região: ${detail.regionName}',
            if (detail.propagationModel != null) 'Modelo: ${detail.propagationModel}',
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        if (detail.processedAt != null) ...[
          const SizedBox(height: 2),
          Text(
            'Processado em ${DateFormat('dd/MM/yyyy HH:mm').format(detail.processedAt!.toLocal())}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ],
    );

    final close = IconButton(
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(Icons.close_rounded),
      tooltip: 'Fechar',
      visualDensity: isCompact ? VisualDensity.compact : VisualDensity.standard,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isCompact ? 12 : 20,
        isCompact ? 12 : 16,
        isCompact ? 4 : 8,
        isCompact ? 12 : 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(child: title),
          close,
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isCompact;

  const _Section({required this.title, required this.child, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isCompact ? 10 : 12),
          child,
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem(this.label, this.value, {this.valueColor});
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;

  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth < _kInfoTileWidth
            ? 1
            : ((maxWidth + spacing) / (_kInfoTileWidth + spacing)).floor().clamp(1, 4);
        final tileWidth =
            columns == 1 ? maxWidth : (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final item in items)
              SizedBox(
                width: tileWidth,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: item.valueColor ?? AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GatewayList extends StatelessWidget {
  final List<SelectedGateway> gateways;

  const _GatewayList({required this.gateways});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: gateways
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _GatewayTile(gateway: entry.value, index: entry.key),
            ),
          )
          .toList(),
    );
  }
}

class _GatewayTile extends StatelessWidget {
  final SelectedGateway gateway;
  final int index;

  const _GatewayTile({required this.gateway, required this.index});

  @override
  Widget build(BuildContext context) {
    final label = gateway.candidateId ?? index + 1;
    final coordinates =
        '${gateway.latitude?.toStringAsFixed(5) ?? '—'}, ${gateway.longitude?.toStringAsFixed(5) ?? '—'}';
    final radius = 'Raio ${formatThousands(gateway.coverageRadiusMeters?.round() ?? 0)} m';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isInline = constraints.maxWidth >= _kCompactContentWidth;
        final badgeOnHeader = constraints.maxWidth >= 300;

        final metas = Wrap(
          spacing: 14,
          runSpacing: 4,
          children: [
            _MetaLabel(text: coordinates),
            _MetaLabel(text: radius),
            if (gateway.manuallyAdjusted && !badgeOnHeader) const _AdjustedBadge(),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.cell_tower, size: 18, color: AppColors.primaryPurple),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Candidato $label',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (gateway.manuallyAdjusted && badgeOnHeader) ...[
                    const SizedBox(width: 8),
                    const _AdjustedBadge(),
                  ],
                ],
              ),
              if (isInline)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 28),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          coordinates,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        radius,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (gateway.manuallyAdjusted) ...[
                        const SizedBox(width: 12),
                        const _AdjustedBadge(),
                      ],
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 28),
                  child: metas,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MetaLabel extends StatelessWidget {
  final String text;

  const _MetaLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    );
  }
}

class _AdjustedBadge extends StatelessWidget {
  const _AdjustedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.badgeYellowLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Ajustado',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.badgeYellow,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String message;

  const _EmptyHint(this.message);

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
    );
  }
}
