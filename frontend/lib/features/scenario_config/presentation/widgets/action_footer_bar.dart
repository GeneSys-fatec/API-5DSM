import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../controllers/scenario_config_controller.dart';

class ActionFooterBar extends StatelessWidget {
  final ScenarioConfigController controller;
  final VoidCallback? onBackToStep1;

  const ActionFooterBar({
    super.key,
    required this.controller,
    this.onBackToStep1,
  });

  @override
  Widget build(BuildContext context) {
    final isValid = controller.isValid;
    final isCalculating = controller.isCalculating;
    final isMobile = Responsive.isMobile(context);

    final calculateBtn = ElevatedButton(
      onPressed: (isValid && !isCalculating)
          ? () async {
              final success = await controller.calculateScenario();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cenário salvo! Simulação de cobertura iniciada.',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        disabledForegroundColor: const Color(0xFF94A3B8),
        elevation: isValid ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
      child: isCalculating
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 20),
                SizedBox(width: 6),
                Text(
                  'Calcular Cenário',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
    );

    if (onBackToStep1 == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Align(alignment: Alignment.centerRight, child: calculateBtn),
      );
    }

    final backButton = TextButton.icon(
      onPressed: onBackToStep1,
      icon: const Icon(
        Icons.arrow_back_rounded,
        size: 18,
        color: AppColors.textPrimary,
      ),
      label: const Text(
        'Voltar para Etapa 1: Delimitação de Área',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: calculateBtn,
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: backButton),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                backButton,
                calculateBtn,
              ],
            ),
    );
  }
}
