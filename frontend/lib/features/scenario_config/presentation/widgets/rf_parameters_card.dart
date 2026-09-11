import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
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
                  detail: 'Brasil Anatel\nRes. 680',
                  preset: '915 MHz',
                  frequency: 915.0,
                  hasIndicator: true,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: '433 MHz',
                  subtitle: 'VHF / Banda Estreita',
                  detail: 'Penetração\nSevera',
                  preset: '433 MHz',
                  frequency: 433.0,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: '2.4 GHz',
                  subtitle: 'Wi-SUN Mesh',
                  detail: 'Alta Vazão /\nCurto Alcance',
                  preset: '2.4 GHz',
                  frequency: 2400.0,
                  width: isWide ? (constraints.maxWidth - 36) / 4 : (constraints.maxWidth - 12) / 2,
                ),
                _buildFrequencyCard(
                  title: 'ZigBee / 920M',
                  subtitle: 'IEEE 802.15.4g',
                  detail: 'Smart Grid FAN\n ',
                  preset: 'ZigBee / 920M',
                  frequency: 920.0,
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
    required double width,
    bool hasIndicator = false,
  }) {
    final isSelected = controller.selectedFrequencyPreset == preset;

    return InkWell(
      onTap: () => controller.setFrequencyPreset(preset, frequency),
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
            const SizedBox(height: 6),
            Text(
              detail,
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
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildModelCard(
                  title: 'Okumura-Hata Suburbano',
                  description:
                      'Perfeito para cidades médias do interior paulista com média atenuação por árvores.',
                  modelName: 'Okumura-Hata Suburbano',
                  width: isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                ),
                _buildModelCard(
                  title: '3GPP TR 38.901 Rural Macro',
                  description:
                      'Ideal para ramais rurais longos e grandes distâncias inter-postes (>200m).',
                  modelName: '3GPP TR 38.901 Rural Macro',
                  width: isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                ),
                _buildModelCard(
                  title: 'ITM (Longley-Rice Relevo)',
                  description:
                      'Considera difração do terreno SRTM e clutter de vegetação densa.',
                  modelName: 'ITM (Longley-Rice Relevo)',
                  width: isWide ? (constraints.maxWidth - 24) / 3 : constraints.maxWidth,
                ),
              ],
            );
          },
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
