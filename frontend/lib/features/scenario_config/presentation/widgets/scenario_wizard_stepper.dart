import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ScenarioWizardStepper extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onStep1Tap;
  final VoidCallback? onStep2Tap;
  final bool showSystemPills;

  const ScenarioWizardStepper({
    super.key,
    required this.currentStep,
    this.onStep1Tap,
    this.onStep2Tap,
    this.showSystemPills = true,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StepBadge(
                    stepNumber: 1,
                    totalSteps: 2,
                    title: 'Delimitação de Área',
                    subtitle: currentStep == 1 ? 'ETAPA 1 DE 2' : 'ETAPA 1 (CONCLUÍDA)',
                    isActive: currentStep == 1,
                    isCompleted: currentStep > 1,
                    onTap: onStep1Tap,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ),
                Expanded(
                  child: _StepBadge(
                    stepNumber: 2,
                    totalSteps: 2,
                    title: 'Parâmetros de RF',
                    subtitle: currentStep == 2 ? 'ETAPA 2 DE 2' : 'ETAPA 2 (PRÓXIMA)',
                    isActive: currentStep == 2,
                    isCompleted: false,
                    onTap: onStep2Tap,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

        return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _StepBadge(
            stepNumber: 1,
            totalSteps: 2,
            title: 'Delimitação de Área & Candidatos',
            subtitle: currentStep == 1 ? 'ETAPA 1 DE 2' : 'ETAPA 1 (CONCLUÍDA)',
            isActive: currentStep == 1,
            isCompleted: currentStep > 1,
            onTap: onStep1Tap,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ),
          _StepBadge(
            stepNumber: 2,
            totalSteps: 2,
            title: 'Parâmetros de RF e Otimização',
            subtitle: currentStep == 2 ? 'ETAPA 2 DE 2' : 'ETAPA 2 (PRÓXIMA)',
            isActive: currentStep == 2,
            isCompleted: false,
            onTap: onStep2Tap,
          ),
          if (showSystemPills) ...[
            const SizedBox(width: 16),
            const Spacer(),
            const _SystemContextPills(),
          ],
        ],
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int stepNumber;
  final int totalSteps;
  final String title;
  final String subtitle;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  const _StepBadge({
    required this.stepNumber,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive
        ? AppColors.primaryPurple
        : isCompleted
            ? AppColors.primaryPurpleLight
            : AppColors.backgroundLight;

    final textColor = isActive
        ? Colors.white
        : isCompleted
            ? AppColors.primaryDark
            : AppColors.textSecondary;

    final subTextColor = isActive
        ? Colors.white.withValues(alpha: 0.85)
        : isCompleted
            ? AppColors.primaryPurple
            : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCompleted ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.primaryPurple
                  : isCompleted
                      ? AppColors.primaryPurpleLight
                      : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.2)
                      : isCompleted
                          ? AppColors.primaryPurple
                          : Colors.grey.shade300,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_rounded
                      : isActive
                          ? Icons.adjust_rounded
                          : Icons.cell_tower_rounded,
                  size: 16,
                  color: isActive
                      ? Colors.white
                      : isCompleted
                          ? Colors.white
                          : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: subTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemContextPills extends StatelessWidget {
  const _SystemContextPills();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.layers_rounded, color: AppColors.primaryPurple, size: 16),
            const SizedBox(width: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Base: ', style: TextStyle(color: AppColors.textSecondary)),
                  TextSpan(text: 'CPFL Paulista 2024 (v2023.Q4)', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.explore_outlined, color: AppColors.warning, size: 16),
            const SizedBox(width: 6),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                children: [
                  TextSpan(text: 'Datum: ', style: TextStyle(color: AppColors.textSecondary)),
                  TextSpan(text: 'SIRGAS 2000 / UTM 23S', style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
