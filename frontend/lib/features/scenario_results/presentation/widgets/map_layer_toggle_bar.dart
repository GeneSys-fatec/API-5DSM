import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'map_layer_type.dart';

class MapLayerToggleBar extends StatelessWidget {
  final Set<MapLayerType> activeLayers;
  final ValueChanged<MapLayerType> onToggle;
  final Set<MapLayerType> hiddenLayers;

  const MapLayerToggleBar({
    super.key,
    required this.activeLayers,
    required this.onToggle,
    this.hiddenLayers = const {},
  });

  @override
  Widget build(BuildContext context) {
    final layers = MapLayerType.values
        .where((layer) => !hiddenLayers.contains(layer))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          for (final layer in layers) ...[
            _LayerChip(
              info: kMapLayerInfo[layer]!,
              selected: activeLayers.contains(layer),
              onTap: () => onToggle(layer),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _LayerChip extends StatelessWidget {
  final MapLayerInfo info;
  final bool selected;
  final VoidCallback onTap;

  const _LayerChip({
    required this.info,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final available = info.available;
    final isOn = available && selected;

    final background = !available
        ? Colors.grey.shade100
        : isOn
        ? AppColors.primaryPurple
        : Colors.white;
    final foreground = !available
        ? Colors.grey.shade400
        : isOn
        ? Colors.white
        : AppColors.textSecondary;
    final borderColor = !available
        ? Colors.grey.shade200
        : isOn
        ? AppColors.primaryPurple
        : Colors.grey.shade300;

    final chip = Material(
      color: background,
      elevation: isOn ? 1 : 0,
      shadowColor: AppColors.primaryPurple.withValues(alpha: 0.15),
      shape: StadiumBorder(side: BorderSide(color: borderColor, width: 1.0)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: available ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(info.icon, size: 14, color: foreground),
              const SizedBox(width: 4), 
              Text(
                info.label,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return available ? chip : Tooltip(message: 'Em breve', child: chip);
  }
}