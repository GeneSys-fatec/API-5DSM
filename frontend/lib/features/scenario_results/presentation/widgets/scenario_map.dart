import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../models/scenario_results_models.dart';
import 'gateway_info_card.dart';
import 'map_layer_toggle_bar.dart';
import 'map_layer_type.dart';

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
    final dLng = metersPerDegreeLng <= 0
        ? 180.0
        : radiusMeters / metersPerDegreeLng;
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
  final GlobalKey? captureKey;

  final bool showLayerToggleBar;

  const ScenarioMap({
    super.key,
    required this.scenario,
    this.isFullScreen = false,
    this.enableTiles = true,
    this.captureKey,
    this.showLayerToggleBar = true,
  });

  @override
  State<ScenarioMap> createState() => _ScenarioMapState();
}

class _ScenarioMapState extends State<ScenarioMap> {
  late Set<MapLayerType> _activeLayers;

  GatewayPoint? _selectedGateway;

  @override
  void initState() {
    super.initState();
    _activeLayers = {
      MapLayerType.searchArea,
      MapLayerType.coverage,
      MapLayerType.gateways,
      if (widget.scenario.results.assets.isNotEmpty) MapLayerType.assets,
    };
  }

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
            title: const Text(
              'Mapa de Cobertura',
              style: TextStyle(fontSize: 20),
            ),
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
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showLayerToggleBar) ...[
          MapLayerToggleBar(
            activeLayers: _activeLayers,
            onToggle: _toggleLayer,
            hiddenLayers: hasSearchArea ? const {} : const {MapLayerType.searchArea},
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RepaintBoundary(
              key: widget.captureKey,
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
                      onTap: (_, _) => setState(() => _selectedGateway = null),
                    ),
                    children: [
                      if (widget.enableTiles)
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                              borderColor: Colors.deepOrange.withValues(
                                alpha: 0.85,
                              ),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (_activeLayers.contains(MapLayerType.coverage))
                        _buildCoverageLayer(gateways),
                      if (_activeLayers.contains(MapLayerType.assets))
                        MarkerLayer(
                          markers: [
                            for (final asset in widget.scenario.results.assets)
                              Marker(
                                point: LatLng(asset.lat, asset.lng),
                                width: 10,
                                height: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: asset.covered
                                        ? Colors.green.shade700
                                        : Colors.red.shade700,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (_activeLayers.contains(MapLayerType.gateways))
                        MarkerLayer(
                          markers: [
                            for (final gw in gateways)
                              Marker(
                                point: LatLng(gw.lat, gw.lng),
                                width: 36,
                                height: 36,
                                child: Tooltip(
                                  message:
                                      '${gw.id} · ${gw.posteId}\nClique para ver detalhes de localização',
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _selectedGateway = gw),
                                    child: Icon(
                                      Icons.cell_tower,
                                      color: _selectedGateway?.id == gw.id
                                          ? AppColors.primaryDark
                                          : Colors.amber.shade700,
                                      size: 32,
                                      shadows: const [
                                        Shadow(
                                          blurRadius: 4,
                                          color: Colors.black45,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('© OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),
                  if (hasSearchArea &&
                      _activeLayers.contains(MapLayerType.searchArea))
                    Positioned(
                      right: 8,
                      bottom: 24,
                      child: _SearchAreaLegend(radiusMeters: searchRadius),
                    ),
                  Positioned(
                    left: isMobile ? 12 : 16,
                    right: isMobile ? 12 : null,
                    bottom: 12,
                    child: IgnorePointer(
                      ignoring: _selectedGateway == null,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 320),
                        reverseDuration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.linear,
                        switchOutCurve: Curves.linear,
                        transitionBuilder: (child, animation) {
                          final fadeAnimation = CurvedAnimation(
                            parent: animation,
                            curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
                            reverseCurve: const Interval(0.25, 1.0, curve: Curves.easeIn),
                          );
                          final scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutBack,
                              reverseCurve: Curves.easeInCubic,
                            ),
                          );
                          final slideAnimation = Tween<Offset>(
                            begin: Offset(0.0, isMobile ? 0.08 : 0.05),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                              reverseCurve: Curves.easeInCubic,
                            ),
                          );

                          return FadeTransition(
                            opacity: fadeAnimation,
                            child: ScaleTransition(
                              scale: scaleAnimation,
                              alignment: isMobile
                                  ? Alignment.bottomCenter
                                  : Alignment.bottomLeft,
                              child: SlideTransition(
                                position: slideAnimation,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _selectedGateway == null
                            ? const SizedBox.shrink(key: ValueKey('empty_gateway'))
                            : ConstrainedBox(
                                key: ValueKey('gateway_${_selectedGateway!.id}'),
                                constraints: BoxConstraints(
                                  maxWidth: isMobile ? double.infinity : 360,
                                  maxHeight: isMobile ? 400 : 480,
                                ),
                                child: GatewayInfoCard(
                                  gateway: _selectedGateway!,
                                  defaultMunicipio: widget.scenario.region,
                                  onClose: () =>
                                      setState(() => _selectedGateway = null),
                                ),
                              ),
                      ),
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
        ),
      ],
    );
  }

  Widget _buildCoverageLayer(List<GatewayPoint> gateways) {
    final polygons = <Polygon>[];
    final circles = <CircleMarker>[];
    for (final gateway in gateways) {
      final geometry = gateway.coverageGeometryGeoJson;
      if (geometry != null) {
        try {
          final decoded = jsonDecode(geometry) as Map<String, dynamic>;
          final rings = decoded['coordinates'] as List<dynamic>;
          final points = (rings.first as List<dynamic>)
              .map((point) => point as List<dynamic>)
              .map(
                (point) => LatLng(
                  (point[1] as num).toDouble(),
                  (point[0] as num).toDouble(),
                ),
              )
              .toList();
          if (points.length >= 3) {
            polygons.add(
              Polygon(
                points: points,
                color: AppColors.primaryDark.withValues(alpha: 0.10),
                borderColor: AppColors.primaryDark.withValues(alpha: 0.55),
                borderStrokeWidth: 1.5,
              ),
            );
            continue;
          }
        } catch (_) {
          // A malformed optional geometry falls back to the legacy radius.
        }
      }
      circles.add(
        CircleMarker(
          point: LatLng(gateway.lat, gateway.lng),
          radius: gateway.coverageRadiusMeters,
          useRadiusInMeter: true,
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          borderColor: AppColors.primaryDark.withValues(alpha: 0.4),
          borderStrokeWidth: 1.5,
        ),
      );
    }
    return Stack(
      children: [
        if (polygons.isNotEmpty) PolygonLayer(polygons: polygons),
        if (circles.isNotEmpty) CircleLayer(circles: circles),
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
