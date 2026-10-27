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
  final hasPolygon = scenario.searchPolygon.length >= 3;
  if (!hasPolygon && scenario.searchRadiusMeters <= 0) return null;

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

  if (hasPolygon) {
    for (final point in scenario.searchPolygon) {
      include(point[0], point[1], 0);
    }
  } else {
    include(scenario.centerLat, scenario.centerLng, scenario.searchRadiusMeters);
  }
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
  final MapController _mapController = MapController();
  double _currentZoom = 12.0;

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

  static Color _colorForAssetType(String rawType) {
    final t = rawType.trim().toUpperCase();
    if (t == 'PONNOT' || t == 'POSTE' || t == 'POST') return AppColors.primaryPurple;
    if (t == 'UNTRMT' || t == 'TRAFO' || t == 'TRANSFORMADOR') return const Color(0xFFF59E0B);
    if (t == 'UNREMT' || t == 'RELIGADOR' || t == 'RECLOSER') return const Color(0xFF4F46E5);
    if (t == 'SUB' || t == 'SUBESTACAO' || t == 'SUBSTATION') return const Color(0xFFDC2626);
    if (t == 'SSDMT') return const Color(0xFF8B5CF6);
    if (t == 'SSDBT') return const Color(0xFF06B6D4);
    if (t == 'SSDAT') return const Color(0xFFEC4899);
    if (t == 'UCBT') return const Color(0xFF3B82F6);
    if (t == 'UCMT') return const Color(0xFFF97316);
    if (t == 'UNCRAT') return const Color(0xFF10B981);
    return const Color(0xFF64748B);
  }

  static IconData _iconForAssetType(String rawType) {
    final t = rawType.trim().toUpperCase();
    if (t == 'PONNOT' || t == 'POSTE' || t == 'POST') return Icons.circle;
    if (t == 'UNTRMT' || t == 'TRAFO' || t == 'TRANSFORMADOR') return Icons.crop_square_rounded;
    if (t == 'UNREMT' || t == 'RELIGADOR' || t == 'RECLOSER') return Icons.crop_square_rounded;
    if (t == 'SUB' || t == 'SUBESTACAO' || t == 'SUBSTATION') return Icons.bolt_rounded;
    if (t == 'SSDMT') return Icons.show_chart_rounded;
    if (t == 'SSDBT') return Icons.timeline_rounded;
    if (t == 'SSDAT') return Icons.electric_bolt_rounded;
    if (t == 'UCBT') return Icons.home_rounded;
    if (t == 'UCMT') return Icons.factory_rounded;
    if (t == 'UNCRAT') return Icons.tune_rounded;
    return Icons.circle;
  }

  static String _labelForAssetType(String rawType) {
    final t = rawType.trim().toUpperCase();
    if (t == 'PONNOT' || t == 'POSTE' || t == 'POST') return 'Poste MT';
    if (t == 'UNTRMT' || t == 'TRAFO' || t == 'TRANSFORMADOR') return 'Trafo MT/BT';
    if (t == 'UNREMT' || t == 'RELIGADOR' || t == 'RECLOSER') return 'Religador';
    if (t == 'SUB' || t == 'SUBESTACAO' || t == 'SUBSTATION') return 'Subestação';
    if (t == 'UCBT') return 'Consumidor BT';
    if (t == 'UCMT') return 'Consumidor MT';
    if (t == 'SSDMT') return 'Segmento MT';
    if (t == 'SSDBT') return 'Segmento BT';
    if (t == 'SSDAT') return 'Segmento AT';
    if (t == 'UNCRAT') return 'Chave AT';
    return rawType.isEmpty ? 'Ativo BDGD' : rawType;
  }

  List<Marker> _buildAssetMarkers(List<AssetPoint> assets, double zoom) {
    if (assets.isEmpty) return const [];

    // Zoom >= 14.5: Render individual markers
    if (zoom >= 14.5) {
      return assets.map(_buildIndividualAssetMarker).toList();
    }

    // Zoom < 14.5: Cluster assets using dynamic proximity grid
    final step = 360.0 / math.pow(2, zoom + 5.0);
    final grid = <String, List<AssetPoint>>{};

    for (final asset in assets) {
      final gx = (asset.lng / step).floor();
      final gy = (asset.lat / step).floor();
      final key = '$gx:$gy';
      (grid[key] ??= []).add(asset);
    }

    final markers = <Marker>[];
    for (final cellAssets in grid.values) {
      if (cellAssets.length == 1) {
        markers.add(_buildIndividualAssetMarker(cellAssets.first));
      } else {
        var sumLat = 0.0;
        var sumLng = 0.0;
        var coveredCount = 0;
        final typeCounts = <String, int>{};

        for (final a in cellAssets) {
          sumLat += a.lat;
          sumLng += a.lng;
          if (a.covered) coveredCount++;
          final t = a.type.toUpperCase(); typeCounts[t] = (typeCounts[t] ?? 0) + 1;
        }

        final count = cellAssets.length;
        final avgLat = sumLat / count;
        final avgLng = sumLng / count;
        final shadowCount = count - coveredCount;

        String dominantType = cellAssets.first.type;
        var maxTypeCount = 0;
        typeCounts.forEach((t, c) {
          if (c > maxTypeCount) {
            maxTypeCount = c;
            dominantType = t;
          }
        });

        markers.add(
          _buildClusterMarker(
            lat: avgLat,
            lng: avgLng,
            count: count,
            coveredCount: coveredCount,
            shadowCount: shadowCount,
            dominantType: dominantType,
          ),
        );
      }
    }

    return markers;
  }

  Marker _buildIndividualAssetMarker(AssetPoint asset) {
    final typeColor = _colorForAssetType(asset.type);
    final typeIcon = _iconForAssetType(asset.type);
    final borderColor = asset.covered
        ? const Color(0xFF10B981) // Green / Conectado
        : const Color(0xFFEF4444); // Red / Em sombra

    return Marker(
      point: LatLng(asset.lat, asset.lng),
      width: 20,
      height: 20,
      child: Tooltip(
        message:
            '${_labelForAssetType(asset.type)} · ${asset.assetKey}\nStatus: ${asset.covered ? "Conectado" : "Em Sombra"}',
        child: Container(
          decoration: BoxDecoration(
            color: typeColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: borderColor,
              width: 2.2,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              typeIcon,
              size: 10,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Marker _buildClusterMarker({
    required double lat,
    required double lng,
    required int count,
    required int coveredCount,
    required int shadowCount,
    required String dominantType,
  }) {
    final size = count >= 100 ? 40.0 : (count >= 10 ? 36.0 : 32.0);

    Color bgStart;
    Color bgEnd;
    Color borderColor;

    if (shadowCount == 0) {
      bgStart = const Color(0xFF059669);
      bgEnd = const Color(0xFF10B981);
      borderColor = const Color(0xFF34D399);
    } else if (coveredCount == 0) {
      bgStart = const Color(0xFFDC2626);
      bgEnd = const Color(0xFFEF4444);
      borderColor = const Color(0xFFF87171);
    } else {
      bgStart = const Color(0xFF4F46E5);
      bgEnd = const Color(0xFF7C3AED);
      borderColor = const Color(0xFFA78BFA);
    }

    return Marker(
      point: LatLng(lat, lng),
      width: size,
      height: size,
      child: Tooltip(
        message:
            'Cluster com $count ativos\n$coveredCount conectados · $shadowCount em sombra\nClique para aproximar',
        child: GestureDetector(
          onTap: () {
            final nextZoom = math.min(_currentZoom + 2.0, 18.0);
            _mapController.move(LatLng(lat, lng), nextZoom);
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [bgStart, bgEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: borderColor, width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (coveredCount > 0 && shadowCount > 0)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                Text(
                  count > 999 ? '${(count / 1000).toStringAsFixed(1)}k' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
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
    final searchPolygon = widget.scenario.searchPolygon;
    final hasPolygon = searchPolygon.length >= 3;
    final hasSearchArea = hasPolygon || searchRadius > 0;
    final viewBounds = computeScenarioViewBounds(widget.scenario);
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final hasAssets = widget.scenario.results.assets.isNotEmpty;

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
                    mapController: _mapController,
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
                      onPositionChanged: (camera, hasGesture) {
                        if ((camera.zoom - _currentZoom).abs() >= 0.5) {
                          setState(() => _currentZoom = camera.zoom);
                        }
                      },
                      onTap: (_, _) => setState(() => _selectedGateway = null),
                    ),
                    children: [
                      if (widget.enableTiles)
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.tecsys.api5dsm',
                        ),
                      if (hasPolygon &&
                          _activeLayers.contains(MapLayerType.searchArea))
                        PolygonLayer(
                          polygons: [
                            Polygon(
                              points: searchPolygon
                                  .map((point) => LatLng(point[0], point[1]))
                                  .toList(),
                              color: Colors.deepOrange.withValues(alpha: 0.05),
                              borderColor: Colors.deepOrange.withValues(
                                alpha: 0.85,
                              ),
                              borderStrokeWidth: 2,
                            ),
                          ],
                        ),
                      if (!hasPolygon &&
                          hasSearchArea &&
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
                          markers: _buildAssetMarkers(
                            widget.scenario.results.assets,
                            _currentZoom,
                          ),
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
                  if (hasAssets && _activeLayers.contains(MapLayerType.assets))
                    Positioned(
                      left: 8,
                      top: 8,
                      child: _AssetsMapLegend(
                        assets: widget.scenario.results.assets,
                        totalAssets: widget.scenario.results.totalAssets,
                        connectedAssets: widget.scenario.results.connectedAssets,
                        coveragePercent: widget.scenario.results.coveragePercent,
                        isMobile: isMobile,
                      ),
                    ),
                  if (hasSearchArea &&
                      _activeLayers.contains(MapLayerType.searchArea))
                    Positioned(
                      right: 8,
                      bottom: 24,
                      child: _SearchAreaLegend(
                        radiusMeters: searchRadius,
                        isPolygon: hasPolygon,
                      ),
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

class _AssetsMapLegend extends StatefulWidget {
  final List<AssetPoint> assets;
  final int totalAssets;
  final int connectedAssets;
  final double coveragePercent;
  final bool isMobile;

  const _AssetsMapLegend({
    required this.assets,
    required this.totalAssets,
    required this.connectedAssets,
    required this.coveragePercent,
    required this.isMobile,
  });

  @override
  State<_AssetsMapLegend> createState() => _AssetsMapLegendState();
}

class _AssetsMapLegendState extends State<_AssetsMapLegend> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = !widget.isMobile;
  }

  @override
  Widget build(BuildContext context) {
    final typesMap = <String, int>{};
    for (final a in widget.assets) {
      final t = a.type.toUpperCase(); typesMap[t] = (typesMap[t] ?? 0) + 1;
    }

    if (!_expanded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = true),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.layers_outlined, size: 14, color: AppColors.primaryPurple),
                const SizedBox(width: 6),
                const Text(
                  'Legenda de Ativos',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurpleLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.assets.length}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primaryPurple),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.isMobile ? 200 : 230,
      constraints: const BoxConstraints(maxHeight: 260),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
        ],
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 14, color: AppColors.primaryPurple),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Legenda de Ativos',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              InkWell(
                onTap: () => setState(() => _expanded = false),
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'STATUS DE COBERTURA',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Conectado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${widget.connectedAssets}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEF4444),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                ),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Em Sombra', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              Text(
                '${widget.totalAssets - widget.connectedAssets}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          if (typesMap.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 5),
            const Text(
              'TIPOS DE ATIVOS',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.4),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final entry in typesMap.entries) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: _ScenarioMapState._colorForAssetType(entry.key),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                _ScenarioMapState._iconForAssetType(entry.key),
                                size: 7,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _ScenarioMapState._labelForAssetType(entry.key),
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${entry.value}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchAreaLegend extends StatelessWidget {
  final double radiusMeters;
  final bool isPolygon;

  const _SearchAreaLegend({required this.radiusMeters, this.isPolygon = false});

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
            isPolygon ? 'Área de busca (polígono manual)' : 'Área de busca (raio $label)',
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
