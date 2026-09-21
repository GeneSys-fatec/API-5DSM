import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'map_layer_type.dart';

class MapLayerToggleBar extends StatelessWidget {
  final Set<MapLayerType> activeLayers;
  final ValueChanged<MapLayerType> onToggle;

  const MapLayerToggleBar({
    super.key,
    required this.activeLayers,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: kMapLayerInfo.entries.map((entry) {
        final layer = entry.key;
        final info = entry.value;
        final isActive = activeLayers.contains(layer);

        return Tooltip(
          message: info.available ? '' : 'Disponível em breve',
          child: FilterChip(
            avatar: Icon(
              info.icon,
              size: 16,
              color: !info.available
                  ? Colors.grey.shade400
                  : isActive
                      ? Colors.white
                      : AppColors.primaryDark,
            ),
            label: Text(info.label),
            selected: isActive,
            onSelected: info.available ? (_) => onToggle(layer) : null,
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: !info.available
                  ? Colors.grey.shade400
                  : isActive
                      ? Colors.white
                      : AppColors.primaryDark,
            ),
            selectedColor: AppColors.primaryDark,
            backgroundColor: AppColors.primaryLight,
            disabledColor: Colors.grey.shade100,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
          ),
        );
      }).toList(),
    );
  }
}