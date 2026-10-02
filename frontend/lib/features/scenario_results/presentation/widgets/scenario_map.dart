import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/scenario_results_models.dart';
import 'gateway_info_card.dart';
import 'map_layer_toggle_bar.dart';
import 'map_layer_type.dart';

/// Enquadramento inicial do mapa: a área de busca da Etapa 1 mais o alcance de
/// cada gateway, para que dê para ver o quanto da área os gateways cobrem.
/// Retorna null quando o cenário não tem área de busca (usa o zoom padrão).
LatLngBounds? computeScenarioViewBounds(SimulationScenario scenario) {
  if (scenario.searchRadiusMeters <= 0) return null;

  var minLat = double.infinity;
  var maxLat = -double.infinity;
  var minLng = double.infinity;
  var maxLng = -double.infinity;

  void include(double lat, double lng, double radiusMeters) {
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLng =
        metersPerDegreeLat * math.cos(lat * math.pi / 180.0);
    final dLat = radiusMeters / metersPerDegreeLat;
    final dLng = metersPerDegreeLng <= 0 ? 180.0 : radiusMeters / metersPerDegreeLng;
    minLat = math.min(minLat, lat - dLat);
    maxLat = math.max(maxLat, lat + dLat);
    minLng = math.min(minLng, lng - dLng);
    maxLng = math.max(maxLng, lng + dLng);
  }

  include(scenario.centerLat, scenario.centerLng, scenario.searchRadiusMeters);
  for (final gw in scenario.results.gateways) {
    include(gw.lat, gw.lng, gw.coverageRadiusMeters);
  }

  return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
}

class ScenarioMap extends StatefulWidget {
  final SimulationScenario scenario;
  final bool isFullScreen;
  final bool enableTiles;

  const ScenarioMap({
    super.key,
    required this.scenario,
    this.isFullScreen = false,
    this.enableTiles = true,
  });

  @override
  State<ScenarioMap> createState() => _ScenarioMapState();
}

class _ScenarioMapState extends State<ScenarioMap> {
  Set<MapLayerType> _activeLayers = {
    MapLayerType.searchArea,
    MapLayerType.coverage,
    MapLayerType.gateways,
  };

  GatewayPoint? _selectedGateway;

  void _toggleLayer(MapLayerType layer) {
    setState(() {
      if (_activeLayers.contains(layer)) {
        _activeLayers.remove(layer);
      } else {
        _activeLayers.add(layer);
      }
    });
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            titleSpacing: 0,
            leadingWidth: 40,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: const Text('Mapa de Cobertura', style: TextStyle(fontSize: 20)),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: ScenarioMap(
              scenario: widget.scenario,
              isFullScreen: true,
              enableTiles: widget.enableTiles,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.scenario.centerLat, widget.scenario.centerLng);
    final gateways = widget.scenario.results.gateways;
    final searchRadius = widget.scenario.searchRadiusMeters;
    final hasSearchArea = searchRadius > 0;
    final viewBounds = computeScenarioViewBounds(widget.scenario);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapLayerToggleBar(
          activeLayers: _activeLayers,
          onToggle: _toggleLayer,
          hiddenLayers: hasSearchArea ? const {} : const {MapLayerType.searchArea},
        ),
        const SizedBox(height: 10),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 12,
                    initialCameraFit: viewBounds == null
                        ? null
                        : CameraFit.bounds(
                            bounds: viewBounds,
                            padding: const EdgeInsets.all(24),
                          ),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (_, __) => setState(() => _selectedGateway = null),
                  ),
                  children: [
                    if (widget.enableTiles)
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.tecsys.api5dsm',
                      ),
                    if (hasSearchArea &&
                        _activeLayers.contains(MapLayerType.searchArea))
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: center,
                            radius: searchRadius,
                            useRadiusInMeter: true,
                            color: Colors.deepOrange.withValues(alpha: 0.05),
                            borderColor: Colors.deepOrange.withValues(alpha: 0.85),
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (_activeLayers.contains(MapLayerType.coverage))
                      CircleLayer(
                        circles: gateways
                            .map(
                              (gw) => CircleMarker(
                                point: LatLng(gw.lat, gw.lng),
                                radius: gw.coverageRadiusMeters,
                                useRadiusInMeter: true,
                                color: AppColors.primaryDark.withOpacity(0.08),
                                borderColor:
                                    AppColors.primaryDark.withOpacity(0.4),
                                borderStrokeWidth: 1.5,
                              ),
                            )
                            .toList(),
                      ),
                    if (_activeLayers.contains(MapLayerType.gateways))
                      MarkerLayer(
                        markers: gateways
                            .map(
                              (gw) => Marker(
                                point: LatLng(gw.lat, gw.lng),
                                width: 34,
                                height: 34,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedGateway = gw),
                                  child: Icon(
                                    Icons.cell_tower,
                                    color: _selectedGateway?.id == gw.id
                                        ? AppColors.primaryDark
                                        : Colors.amber,
                                    size: 30,
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 3,
                                        color: Colors.black45,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('© OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
                if (hasSearchArea && _activeLayers.contains(MapLayerType.searchArea))
                  Positioned(
                    right: 8,
                    bottom: 24,
                    child: _SearchAreaLegend(radiusMeters: searchRadius),
                  ),
                if (_selectedGateway != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: GatewayInfoCard(
                      gateway: _selectedGateway!,
                      onClose: () => setState(() => _selectedGateway = null),
                    ),
                  ),
                if (!widget.isFullScreen)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _FullScreenButton(
                      icon: Icons.fullscreen,
                      onTap: _openFullScreen,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchAreaLegend extends StatelessWidget {
  final double radiusMeters;

  const _SearchAreaLegend({required this.radiusMeters});

  @override
  Widget build(BuildContext context) {
    final label = radiusMeters >= 1000
        ? '${(radiusMeters / 1000).toStringAsFixed(1)} km'
        : '${radiusMeters.toStringAsFixed(0)} m';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepOrange.withValues(alpha: 0.15),
              border: Border.all(color: Colors.deepOrange, width: 2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Área de busca (raio $label)',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _FullScreenButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FullScreenButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}