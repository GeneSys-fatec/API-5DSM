import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/area_delimitation_controller.dart';
import 'radius_input_utils.dart';

class SearchRadiusCard extends StatelessWidget {
  final AreaDelimitationController controller;

  const SearchRadiusCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final useDrawnPolygon = controller.useDrawnPolygon;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
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
                  'Área de Busca',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AreaModeSelector(
            useDrawnPolygon: useDrawnPolygon,
            onSelectRadius: () => controller.setUseDrawnPolygon(false),
            onSelectPolygon: () => controller.setUseDrawnPolygon(true),
          ),
          const SizedBox(height: 14),
          if (useDrawnPolygon)
            _PolygonModeContent(controller: controller)
          else
            _RadiusModeContent(controller: controller),
        ],
      ),
    );
  }
}

class _AreaModeSelector extends StatelessWidget {
  final bool useDrawnPolygon;
  final VoidCallback onSelectRadius;
  final VoidCallback onSelectPolygon;

  const _AreaModeSelector({
    required this.useDrawnPolygon,
    required this.onSelectRadius,
    required this.onSelectPolygon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Raio Circular',
              icon: Icons.circle_outlined,
              isSelected: !useDrawnPolygon,
              onTap: onSelectRadius,
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Polígono Manual',
              icon: Icons.pentagon_outlined,
              isSelected: useDrawnPolygon,
              onTap: onSelectPolygon,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surfaceWhite : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? const [BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.primaryPurple : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primaryPurple : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _RadiusModeContent extends StatefulWidget {
  final AreaDelimitationController controller;

  const _RadiusModeContent({required this.controller});

  @override
  State<_RadiusModeContent> createState() => _RadiusModeContentState();
}

class _RadiusModeContentState extends State<_RadiusModeContent> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  late String _lastValidText;

  @override
  void initState() {
    super.initState();
    _lastValidText = _formatCurrentRadius();
    _textController = TextEditingController(text: _lastValidText);
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commit();
      }
    });
  }

  @override
  void didUpdateWidget(_RadiusModeContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!_focusNode.hasFocus) {
      final formatted = _formatCurrentRadius();
      _textController.text = formatted;
      _lastValidText = formatted;
    }
  }

  String _formatCurrentRadius() {
    final radiusKm = widget.controller.radiusKm;
    final isUnitKm = widget.controller.isUnitKm;
    final displayRadius = isUnitKm ? radiusKm : radiusKm * 1000.0;
    return isUnitKm ? displayRadius.toStringAsFixed(1) : displayRadius.toStringAsFixed(0);
  }

  void _commit() {
    final parsedValue = parseRadiusInput(_textController.text);
    if (parsedValue == null) {
      _textController.text = _lastValidText;
      return;
    }

    final isUnitKm = widget.controller.isUnitKm;
    final clampedKm = clampConfirmedRadius(
      parsedValue,
      isUnitKm: isUnitKm,
      maxRadiusKm: widget.controller.maxRadiusKm,
    );

    final valueInSelectedUnit = isUnitKm ? clampedKm : clampedKm * 1000.0;
    widget.controller.setRadius(valueInSelectedUnit, isUnitKm: isUnitKm); // AC 3.3

    final formatted = _formatCurrentRadius();
    _textController.text = formatted;
    _lastValidText = formatted;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final radiusKm = controller.radiusKm;
    final isUnitKm = controller.isUnitKm;
    final isExceeded = controller.isRadiusExceeded;
    final intersects = controller.intersectsBoundary;
    final overlapPct = controller.boundaryOverlapPct;

    final unitLabel = isUnitKm ? 'km' : 'm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Extensão do Vetor Circular:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            _UnitSelector(
              isUnitKm: isUnitKm,
              onSelectKm: () => controller.toggleUnit(true),
              onSelectMeters: () => controller.toggleUnit(false),
            ),
            const SizedBox(width: 8),
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
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      textAlign: TextAlign.start,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        _SingleDecimalSeparatorFormatter(),
                      ],
                      decoration: const InputDecoration.collapsed(hintText: ''),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isExceeded ? AppColors.vermelhoErro : AppColors.textPrimary,
                      ),
                      onEditingComplete: _commit,
                      onSubmitted: (_) => _commit(),
                    ),
                  ),
                  const SizedBox(width: 4),
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
            value: radiusKm.clamp(0.5, controller.maxRadiusKm),
            min: 0.5,
            max: controller.maxRadiusKm,
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
                  Text(
                    'Teto Máx API: ${controller.maxRadiusKm.toStringAsFixed(1)} km',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              Text(
                '${controller.maxRadiusKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
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
                      ? 'O raio ultrapassou ${controller.maxRadiusKm.toStringAsFixed(1)} km! A API bloqueou a simulação automaticamente por teto computacional em grade de alta densidade.'
                      : 'Caso o raio ultrapasse ${controller.maxRadiusKm.toStringAsFixed(1)} km, a API bloqueará a simulação automaticamente por teto computacional em grade de alta densidade.',
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
    );
  }
}

class _SingleDecimalSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final separatorCount = newValue.text.split('').where((c) => c == '.' || c == ',').length;
    if (separatorCount > 1) {
      return oldValue;
    }
    return newValue;
  }
}

class _PolygonModeContent extends StatelessWidget {
  final AreaDelimitationController controller;

  const _PolygonModeContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    final pointCount = controller.drawnPolygonPoints.length;
    final outOfBounds = controller.polygonPointOutOfBounds;
    final hasEnoughPoints = pointCount >= 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                hasEnoughPoints
                    ? 'Polígono com $pointCount pontos'
                    : 'Clique no mapa para adicionar pontos (mínimo 3)',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            if (pointCount > 0)
              TextButton.icon(
                onPressed: controller.clearDrawnPolygon,
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.vermelhoErro),
                label: const Text(
                  'Limpar',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.vermelhoErro),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: outOfBounds ? AppColors.badgeRedLight : AppColors.primaryPurpleUltraLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: outOfBounds
                  ? AppColors.badgeRed.withValues(alpha: 0.4)
                  : AppColors.primaryPurpleLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                outOfBounds ? Icons.error_outline_rounded : Icons.info_rounded,
                size: 16,
                color: outOfBounds ? AppColors.vermelhoErro : AppColors.primaryPurple,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  outOfBounds
                      ? 'Um dos pontos informados está fora da área de cobertura da BDGD selecionada. Ajuste o ponto para dentro do contorno destacado no mapa.'
                      : 'Clique no mapa para adicionar vértices. Arraste um ponto para ajustá-lo e dê duplo clique para removê-lo. O polígono fecha automaticamente a partir de 3 pontos.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: outOfBounds ? FontWeight.w700 : FontWeight.w500,
                    color: outOfBounds ? AppColors.vermelhoErro : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
