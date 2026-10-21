import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/scenario_config_controller.dart';

class RfParametersCard extends StatelessWidget {
  final ScenarioConfigController controller;

  const RfParametersCard({super.key, required this.controller});

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
          _buildFrequencySection(),
          const SizedBox(height: 24),
          _buildNumericInputsGrid(),
          const SizedBox(height: 20),
          _buildLinkBudgetTerrainSection(),
          const SizedBox(height: 24),
          _buildPropagationModelsSection(),
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
            color: AppColors.primaryPurpleUltraLight,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE9D5FF)),
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: AppColors.primaryPurple,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Parâmetros de Tecnologia & Radiofrequência',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Configuração da camada física e características dos transceptores dos nós BDG',
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

  Widget _buildFrequencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PADRÃO & FREQUÊNCIA OPERACIONAL',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildFrequencyCard(
                  title: '915 MHz',
                  subtitle: 'ISM / LoRaWAN',
                  detail: 'Brasil Anatel Res. 680',
                  preset: '915 MHz',
                  frequency: 915.0,
                  txPowerDbm: 21.0,
                  rxSensitivityDbm: -120.0,
                  gatewayHeightM: 6.0,
                  deviceHeightM: 5.0,
                  hasIndicator: true,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: '433 MHz',
                  subtitle: 'VHF / Banda Estreita',
                  detail: 'Penetração Severa',
                  preset: '433 MHz',
                  frequency: 433.0,
                  txPowerDbm: 27.0,
                  rxSensitivityDbm: -118.0,
                  gatewayHeightM: 8.0,
                  deviceHeightM: 4.0,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: '2.4 GHz',
                  subtitle: 'Wi-SUN Mesh',
                  detail: 'Alta Vazão / Curto Alcance',
                  preset: '2.4 GHz',
                  frequency: 2400.0,
                  txPowerDbm: 20.0,
                  rxSensitivityDbm: -95.0,
                  gatewayHeightM: 6.0,
                  deviceHeightM: 3.0,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: 'ZigBee / 920M',
                  subtitle: 'IEEE 802.15.4g',
                  detail: 'Smart Grid FAN',
                  preset: 'ZigBee / 920M',
                  frequency: 920.0,
                  txPowerDbm: 14.0,
                  rxSensitivityDbm: -100.0,
                  gatewayHeightM: 6.0,
                  deviceHeightM: 3.0,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFrequencyCard({
    required String title,
    required String subtitle,
    required String detail,
    required String preset,
    required double frequency,
    required double txPowerDbm,
    required double rxSensitivityDbm,
    required double gatewayHeightM,
    required double deviceHeightM,
    required double width,
    bool hasIndicator = false,
  }) {
    final isSelected = controller.selectedFrequencyPreset == preset;
    final pathLossBudget = txPowerDbm - rxSensitivityDbm;

    return InkWell(
      onTap: () => controller.setFrequencyPreset(
        preset,
        frequency,
        defaultTxPower: txPowerDbm,
        defaultRxSensitivity: rxSensitivityDbm,
        defaultGatewayHeight: gatewayHeightM,
        defaultDeviceHeight: deviceHeightM,
      ),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? Colors.white : AppColors.textDark,
                  ),
                ),
                if (hasIndicator)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFBBF24),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TX ${txPowerDbm.toStringAsFixed(0)} dBm',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.primaryPurple,
                    ),
                  ),
                  Text(
                    ' • ',
                    style: TextStyle(
                      fontSize: 9.5,
                      color: isSelected ? Colors.white70 : AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'RX ${rxSensitivityDbm.toStringAsFixed(0)} dBm',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$detail • Margem: ${pathLossBudget.toStringAsFixed(0)} dB',
              style: TextStyle(
                fontSize: 10,
                height: 1.3,
                color: isSelected ? Colors.white.withValues(alpha: 0.75) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericInputsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildParameterBox(
              label: 'POTÊNCIA TX GATEWAY',
              controller: controller.txPowerController,
              unit: 'dBm',
              subtitle: 'Potência do amplificador de mastro',
              errorText: controller.txPowerError,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            _buildParameterBox(
              label: 'SENSIBILIDADE RX',
              controller: controller.rxSensitivityController,
              unit: 'dBm',
              subtitle: 'Limiar térmico dos medidores',
              errorText: controller.rxSensitivityError,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            _buildParameterBox(
              label: 'ALTURA DO GATEWAY',
              controller: controller.gatewayHeightController,
              unit: 'metros',
              subtitle: 'Instalação em poste/torre',
              errorText: controller.gatewayHeightError,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
            _buildParameterBox(
              label: 'ALTURA DO RECEPTOR',
              controller: controller.deviceHeightController,
              unit: 'metros',
              subtitle: 'Cruzeta superior / medidor',
              errorText: controller.deviceHeightError,
              width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
            ),
          ],
        );
      },
    );
  }

  Widget _buildParameterBox({
    required String label,
    required TextEditingController controller,
    required String unit,
    required String subtitle,
    required double width,
    String? errorText,
  }) {
    final hasError = errorText != null;

    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasError ? AppColors.vermelhoErro : AppColors.cardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      fillColor: const Color(0xFFF8FAFC),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: hasError ? AppColors.vermelhoErro : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: hasError ? AppColors.vermelhoErro : const Color(0xFFCBD5E1),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: const BorderSide(color: AppColors.primaryPurple, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hasError ? errorText : subtitle,
            style: TextStyle(
              fontSize: 10,
              color: hasError ? AppColors.vermelhoErro : AppColors.textLight,
              fontWeight: hasError ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkBudgetTerrainSection() {
    final txPower = controller.currentTxPowerDbm;
    final rxSens = controller.currentRxSensitivityDbm;
    final margin = controller.fadeMarginDb;
    final maxLoss = controller.maxPermissiblePathLossDb;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  color: AppColors.primaryPurple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'ORÇAMENTO DE POTÊNCIA & COBERTURA COM RELEVO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: maxLoss > 100 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: maxLoss > 100 ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
                  ),
                ),
                child: Text(
                  'Perda Máx. Tolerada: ${maxLoss.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: maxLoss > 100 ? const Color(0xFF166534) : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'A área de abrangência de cada gateway é calculada combinando a potência de transmissão configurada ($txPower dBm) com a sensibilidade dos medidores ($rxSens dBm) e a margem de desvanecimento (-$margin dB). O orçamento resultante (${maxLoss.toStringAsFixed(1)} dB) é confrontado com as perdas por espaço livre e atenuação de relevo (ITM Longley-Rice / SRTM 30m) para determinar o raio de alcance útil de cada nó.',
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.45,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildFormulaBadge(label: 'Potência TX', value: '+${txPower.toStringAsFixed(0)} dBm', color: AppColors.primaryPurple),
              const Text('-', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              _buildFormulaBadge(label: 'Margem Desvanecimento', value: '${margin.toStringAsFixed(0)} dB', color: const Color(0xFF64748B)),
              const Text('-', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              _buildFormulaBadge(label: 'Sensibilidade RX', value: '${rxSens.toStringAsFixed(0)} dBm', color: AppColors.primaryPurple),
              const Text('=', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              _buildFormulaBadge(label: 'Orçamento Relevo', value: '${maxLoss.toStringAsFixed(1)} dB', color: const Color(0xFF0F766E), isHighlighted: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaBadge({
    required String label,
    required String value,
    required Color color,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isHighlighted ? color : const Color(0xFFCBD5E1),
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPropagationModelsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MODELO MATEMÁTICO DE PROPAGAÇÃO ELETROMAGNÉTICA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 12),
        _buildModelCard(
          title: 'ITM (Longley-Rice Relevo)',
          description:
              'Modelo padrão adotado: considera relevo topográfico SRTM 30m, difração de gume de faca, obstruções de terreno e clutter.',
          modelName: 'ITM (Longley-Rice Relevo)',
          width: double.infinity,
        ),
      ],
    );
  }

  Widget _buildModelCard({
    required String title,
    required String description,
    required String modelName,
    required double width,
  }) {
    final isSelected = controller.selectedPropagationModel == modelName;

    return InkWell(
      onTap: () => controller.setPropagationModel(modelName),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryPurple : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryPurple.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryPurple : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isSelected ? AppColors.primaryPurple : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
