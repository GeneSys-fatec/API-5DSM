import 'package:flutter/material.dart';

enum MapLayerType {
  searchArea,
  coverage,
  gateways,
  assets,
}

class MapLayerInfo {
  final String label;
  final IconData icon;
  final bool available;

  const MapLayerInfo({
    required this.label,
    required this.icon,
    this.available = true,
  });
}

const Map<MapLayerType, MapLayerInfo> kMapLayerInfo = {
  MapLayerType.searchArea: MapLayerInfo(
    label: 'Área de busca',
    icon: Icons.radar,
  ),
  MapLayerType.coverage: MapLayerInfo(
    label: 'Cobertura RF',
    icon: Icons.blur_circular,
  ),
  MapLayerType.gateways: MapLayerInfo(
    label: 'Gateways',
    icon: Icons.cell_tower,
  ),
  MapLayerType.assets: MapLayerInfo(
    label: 'Ativos',
    icon: Icons.electrical_services,
  ),
};
