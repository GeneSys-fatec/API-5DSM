import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/area_delimitation_controller.dart';

class SearchRadiusCard extends StatelessWidget {
  final AreaDelimitationController controller;

  const SearchRadiusCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final radiusKm = controller.radiusKm;
    final isUnitKm = controller.isUnitKm;
    final isExceeded = controller.isRadiusExceeded;
    final intersects = controller.intersectsBoundary;
    final overlapPct = controller.boundaryOverlapPct;

    final displayRadius = isUnitKm ? radiusKm : radiusKm * 1000.0;
    final unitLabel = isUnitKm ? 'km' : 'm';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExceeded ? AppColors.vermelhoErro : AppColors.cardBorder,
          width: isExceeded ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Raio da Área de Busca',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _UnitSelector(
                isUnitKm: isUnitKm,
                onSelectKm: () => controller.toggleUnit(true),
                onSelectMeters: () => controller.toggleUnit(false),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Extensão do Vetor Circular:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              Container(
                width: 90,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isExceeded ? AppColors.vermelhoErro : AppColors.inputBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isUnitKm ? displayRadius.toStringAsFixed(1) : displayRadius.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isExceeded ? AppColors.vermelhoErro : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      unitLabel,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: isExceeded ? AppColors.vermelhoErro : AppColors.primaryPurple,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: isExceeded ? AppColors.vermelhoErro : AppColors.primaryPurple,
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Slider(
              value: radiusKm.clamp(0.5, 10.0),
              min: 0.5,
              max: 10.0,
              divisions: 95,
              onChanged: (val) => controller.setRadius(val, isUnitKm: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('0.5 km', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                    Text('(Mín)', style: TextStyle(fontSize: 9, color: AppColors.textMuted)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Teto Máx API: 8.0 km',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const Text('10.0 km', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isExceeded ? AppColors.badgeRedLight : AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isExceeded ? AppColors.badgeRed.withValues(alpha: 0.4) : AppColors.cardBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isExceeded ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: isExceeded ? AppColors.vermelhoErro : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExceeded
                        ? 'O raio ultrapassou 8.0 km! A API bloqueou a simulação automaticamente por teto computacional em grade de alta densidade.'
                        : 'Caso o raio ultrapasse 8.0 km, a API bloqueará a simulação automaticamente por teto computacional em grade de alta densidade.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      fontWeight: isExceeded ? FontWeight.w700 : FontWeight.w500,
                      color: isExceeded ? AppColors.vermelhoErro : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (intersects && !isExceeded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aviso de Interceptação da Malha BDGD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.warning,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'A área circular intercepta o limite da concessão BDGD em ${overlapPct.toStringAsFixed(0)}% da borda norte. Ativos externos à área homologada serão desconsiderados.',
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleUltraLight,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryPurpleLight),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_rounded, size: 16, color: AppColors.primaryPurple),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOTA DE ENGENHARIA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryPurple,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'O raio delimita a área de busca de estruturas — NÃO representa o alcance de RF. A cobertura real é calculada individualmente na Etapa 2.',
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitSelector extends StatelessWidget {
  final bool isUnitKm;
  final VoidCallback onSelectKm;
  final VoidCallback onSelectMeters;

  const _UnitSelector({
    required this.isUnitKm,
    required this.onSelectKm,
    required this.onSelectMeters,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onSelectKm,
          child: Text(
            'km',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isUnitKm ? FontWeight.w800 : FontWeight.w600,
              color: isUnitKm ? AppColors.primaryPurple : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSelectMeters,
          child: Text(
            'metros',
            style: TextStyle(
              fontSize: 12,
              fontWeight: !isUnitKm ? FontWeight.w800 : FontWeight.w600,
              color: !isUnitKm ? AppColors.primaryPurple : AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}
