import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controllers/scenario_config_controller.dart';

class OptimizationCriteriaCard extends StatelessWidget {
  final ScenarioConfigController controller;

  const OptimizationCriteriaCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSlidersRow(),
          const SizedBox(height: 24),
          _buildBottomRow(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.badgeYellowLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: const Icon(
            Icons.radar_rounded,
            color: AppColors.badgeYellow,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Metas de Cobertura e Restrições de Orçamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Definição dos requisitos mínimos de SLA e orçamento de estações base',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSlidersRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Container(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'META DE COBERTURA\nMÍNIMA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                          height: 1.25,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.badgeYellowLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${controller.minCoveragePercent.toStringAsFixed(1)}% ativos',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFCBD5E1),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: AppColors.primaryPurple,
                      overlayColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: controller.minCoveragePercent.clamp(1.0, 100.0),
                      min: 1.0,
                      max: 100.0,
                      onChanged: controller.setMinCoverage,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickLabel('80.0%\n(Mínimo)', () => controller.setMinCoverage(80.0)),
                      _buildQuickLabel(
                        '95.0% (Padrão\nAneel)',
                        () => controller.setMinCoverage(95.0),
                        isBold: true,
                      ),
                      _buildQuickLabel(
                        '99.5%\n(Crítico)',
                        () => controller.setMinCoverage(99.5),
                        align: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'MARGEM DE DESVANECIMENTO\n(FADE)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                          height: 1.25,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurpleLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${controller.fadeMarginDb.toStringAsFixed(0)} dB',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFFCBD5E1),
                      inactiveTrackColor: const Color(0xFFF1F5F9),
                      thumbColor: AppColors.primaryPurple,
                      overlayColor: AppColors.primaryPurple.withValues(alpha: 0.15),
                      trackHeight: 6,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    ),
                    child: Slider(
                      value: controller.fadeMarginDb.clamp(0.0, 30.0),
                      min: 0.0,
                      max: 30.0,
                      onChanged: controller.setFadeMargin,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildQuickLabel('8 dB\n(Urbano Aberto)', () => controller.setFadeMargin(8.0)),
                      _buildQuickLabel(
                        '14 dB\n(Recomendado)',
                        () => controller.setFadeMargin(14.0),
                        isBold: true,
                      ),
                      _buildQuickLabel(
                        '24 dB\n(Chuva/Mata)',
                        () => controller.setFadeMargin(24.0),
                        align: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickLabel(String text, VoidCallback onTap, {bool isBold = false, TextAlign align = TextAlign.left}) {
    return InkWell(
      onTap: onTap,
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 10,
          color: isBold ? AppColors.textDark : AppColors.textMuted,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          height: 1.25,
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 780;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            Container(
              width: isWide ? (constraints.maxWidth - 16) * 0.40 : constraints.maxWidth,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: controller.gatewaysError != null
                      ? AppColors.vermelhoErro
                      : const Color(0xFFFCD34D),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'CAPEX / RESTRIÇÃO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF92400E),
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ORÇAMENTO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Limite de Gateways',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quantidade máxima de pontos autorizados para ativação',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cell_tower_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller.maxGatewaysController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        const Text(
                          'UNIDADES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF94A3B8),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (controller.gatewaysError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      controller.gatewaysError!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.vermelhoErro,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: isWide ? (constraints.maxWidth - 16) * 0.58 : constraints.maxWidth,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'PRIORIDADE DE COBERTURA POR\nTIPO DE ATIVO BDGD',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                            height: 1.25,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Pesos no\nFitness',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryPurple,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildAssetPriorityItem(
                    title: 'Religadores & Chaves\nTelecomandadas',
                    subtitle: 'Equipamento Crítico de Manobra',
                    badgeText: '100%\nObrigatório',
                    badgeBg: const Color(0xFFFEE2E2),
                    badgeTextColor: const Color(0xFFDC2626),
                    checked: controller.religadoresChecked,
                    onChanged: controller.toggleReligadores,
                  ),
                  const SizedBox(height: 8),
                  _buildAssetPriorityItem(
                    title: 'Transformadores de\nDistribuição (MT/BT)',
                    subtitle: 'Sensoriamento Térmico e Carga',
                    badgeText: 'Peso\n95%',
                    badgeBg: const Color(0xFFFEF3C7),
                    badgeTextColor: const Color(0xFFD97706),
                    checked: controller.transformadoresChecked,
                    onChanged: controller.toggleTransformadores,
                  ),
                  const SizedBox(height: 8),
                  _buildAssetPriorityItem(
                    title: 'Medidores de\nConsumidores (AMI / BT)',
                    subtitle: 'Telemetria de Faturamento',
                    badgeText: 'Peso\n85%',
                    badgeBg: const Color(0xFFF1F5F9),
                    badgeTextColor: const Color(0xFF475569),
                    checked: controller.medidoresChecked,
                    onChanged: controller.toggleMedidores,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetPriorityItem({
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required bool checked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: onChanged,
            activeColor: AppColors.primaryPurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              badgeText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: badgeTextColor,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
