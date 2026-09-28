import 'package:flutter/material.dart';

enum MapLayerType {
  coverage,
  gateways,
  rssiHeatmap,
  lineOfSight,
  terrain,
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
  MapLayerType.coverage: MapLayerInfo(
    label: 'Cobertura RF',
    icon: Icons.blur_circular,
  ),
  MapLayerType.gateways: MapLayerInfo(
    label: 'Gateways',
    icon: Icons.cell_tower,
  ),
  MapLayerType.rssiHeatmap: MapLayerInfo(
    label: 'Heatmap RSSI',
    icon: Icons.grain,
    available: false,
  ),
  MapLayerType.lineOfSight: MapLayerInfo(
    label: 'Visada (LoS)',
    icon: Icons.visibility_outlined,
    available: false,
  ),
  MapLayerType.terrain: MapLayerInfo(
    label: 'Relevo',
    icon: Icons.terrain,
    available: false,
  ),
};