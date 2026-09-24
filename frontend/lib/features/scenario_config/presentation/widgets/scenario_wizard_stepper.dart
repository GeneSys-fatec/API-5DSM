import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';

class ScenarioWizardStepper extends StatelessWidget {
  final int currentStep;
  final VoidCallback? onStep1Tap;
  final VoidCallback? onStep2Tap;

  const ScenarioWizardStepper({
    super.key,
    required this.currentStep,
    this.onStep1Tap,
    this.onStep2Tap,
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
                    title: '1. Delimitação de Área',
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
                    title: '2. Parâmetros de RF',
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showPills = constraints.maxWidth >= 1050;
          return Row(
            children: [
              Flexible(
                child: _StepBadge(
                  stepNumber: 1,
                  totalSteps: 2,
                  title: '1. Delimitação de Área & Candidatos',
                  subtitle: currentStep == 1 ? 'ETAPA 1 DE 2' : 'ETAPA 1 (CONCLUÍDA)',
                  isActive: currentStep == 1,
                  isCompleted: currentStep > 1,
                  onTap: onStep1Tap,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ),
              Flexible(
                child: _StepBadge(
                  stepNumber: 2,
                  totalSteps: 2,
                  title: '2. Parâmetros de RF e Otimização',
                  subtitle: currentStep == 2 ? 'ETAPA 2 DE 2' : 'ETAPA 2 (PRÓXIMA)',
                  isActive: currentStep == 2,
                  isCompleted: false,
                  onTap: onStep2Tap,
                ),
              ),
              if (showPills) ...[
                const SizedBox(width: 16),
                const Spacer(),
                const _SystemContextPills(),
              ],
            ],
          );
        },
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
                      maxLines: 1,
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
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.statusGreenLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: AppColors.statusGreen, size: 8),
              SizedBox(width: 6),
              Text(
                'Motor GIS Ativo',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.statusGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
