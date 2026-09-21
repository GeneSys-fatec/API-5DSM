import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/scenario_history_models.dart';
import 'gateway_info_card.dart';
import 'map_layer_toggle_bar.dart';
import 'map_layer_type.dart';

class ScenarioMap extends StatefulWidget {
  final SimulationScenario scenario;

  const ScenarioMap({super.key, required this.scenario});

  @override
  State<ScenarioMap> createState() => _ScenarioMapState();
}

class _ScenarioMapState extends State<ScenarioMap> {
  Set<MapLayerType> _activeLayers = {
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

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.scenario.centerLat, widget.scenario.centerLng);
    final gateways = widget.scenario.results.gateways;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MapLayerToggleBar(
          activeLayers: _activeLayers,
          onToggle: _toggleLayer,
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
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onTap: (_, __) => setState(() => _selectedGateway = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.tecsys.api5dsm',
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
                if (_selectedGateway != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: GatewayInfoCard(
                      gateway: _selectedGateway!,
                      onClose: () => setState(() => _selectedGateway = null),
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