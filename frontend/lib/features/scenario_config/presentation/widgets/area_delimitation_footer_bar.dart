import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/area_delimitation_controller.dart';

class AreaDelimitationFooterBar extends StatelessWidget {
  final AreaDelimitationController controller;
  final VoidCallback onBackToBdgd;
  final VoidCallback onAdvanceToStep2;

  const AreaDelimitationFooterBar({
    super.key,
    required this.controller,
    required this.onBackToBdgd,
    required this.onAdvanceToStep2,
  });

  @override
  Widget build(BuildContext context) {
    final canAdvance = controller.canAdvance;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final backBtn = TextButton.icon(
            onPressed: onBackToBdgd,
            icon: const Icon(Icons.arrow_back_rounded, size: 18, color: AppColors.textPrimary),
            label: const Text(
              'Voltar para Importação BDGD',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          );

          final advanceBtn = ElevatedButton(
            onPressed: canAdvance ? onAdvanceToStep2 : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFE2E8F0),
              disabledForegroundColor: const Color(0xFF94A3B8),
              elevation: canAdvance ? 2 : 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    'Avançar para Etapa 2: Parâmetros de RF e Otimização',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          );

          if (constraints.maxWidth < 1100) {
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 10,
              children: [
                backBtn,
                advanceBtn,
              ],
            );
          }

          return Row(
            children: [
              backBtn,
              const Spacer(),
              advanceBtn,
            ],
          );
        },
      ),
    );
  }
}