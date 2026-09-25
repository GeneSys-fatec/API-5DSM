import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../controllers/area_delimitation_controller.dart';

class AreaDelimitationMap extends StatefulWidget {
  final AreaDelimitationController controller;
  final bool enableTiles;

  const AreaDelimitationMap({
    super.key,
    required this.controller,
    this.enableTiles = true,
  });

  @override
  State<AreaDelimitationMap> createState() => _AreaDelimitationMapState();
}

class _AreaDelimitationMapState extends State<AreaDelimitationMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.controller.config;
    final center = LatLng(cfg.centerLatitude, cfg.centerLongitude);
    final radiusM = cfg.radiusMeters;
    final candidates = widget.controller.filteredCandidates;
    final selectedCand = widget.controller.selectedCandidate;
    final activeLayer = widget.controller.activeMapLayer;

    String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    if (activeLayer == 'satelite') {
      tileUrl = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    } else if (activeLayer == 'relevo') {
      tileUrl = 'https://tile.opentopomap.org/{z}/{x}/{y}.png';
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13.5,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onTap: (_, latLng) {
                widget.controller.onMapTap(latLng.latitude, latLng.longitude);
              },
            ),
            children: [
              if (widget.enableTiles)
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.tecsys.api5dsm',
                ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: radiusM,
                    useRadiusInMeter: true,
                    color: Colors.black.withValues(alpha: 0.40),
                    borderColor: Colors.black87,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 240,
                    height: 48,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primaryPurple,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                            child: const Text(
                              'Centro da Busca',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ...candidates.map((cand) {
                    return Marker(
                      point: LatLng(cand.latitude, cand.longitude),
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => widget.controller.selectCandidate(cand),
                        child: _CandidateMarkerIcon(candidate: cand),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _TopMapBar(
              activeLayer: activeLayer,
              onSelectLayer: (layer) => widget.controller.setMapLayer(layer),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _ZoomControls(
              onZoomIn: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, currentZoom + 1);
              },
              onZoomOut: () {
                final currentZoom = _mapController.camera.zoom;
                _mapController.move(_mapController.camera.center, currentZoom - 1);
              },
              onResetCenter: () {
                _mapController.move(center, 13.5);
              },
            ),
          ),
          Positioned(
            top: 160,
            right: 120,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                'Raio de Busca = ${cfg.radiusKm.toStringAsFixed(2)} km',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (selectedCand != null)
            Positioned(
              top: 56,
              right: 60,
              child: _CandidateDetailsCard(
                candidate: selectedCand,
                onClose: () => widget.controller.selectCandidate(null),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _CartographicLegendBar(controller: widget.controller),
          ),
        ],
      ),
    );
  }
}

class _CandidateMarkerIcon extends StatelessWidget {
  final CandidateAsset candidate;

  const _CandidateMarkerIcon({required this.candidate});

  @override
  Widget build(BuildContext context) {
    switch (candidate.type) {
      case CandidateAssetType.poste:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryPurple,
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        );
      case CandidateAssetType.trafo:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: const Color(0xFFF59E0B),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        );
      case CandidateAssetType.religador:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: const Color(0xFF4F46E5),
            border: Border.all(color: Colors.white, width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
        );
      case CandidateAssetType.subestacao:
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFDC2626),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.bolt_rounded, size: 14, color: Colors.white),
          ),
        );
    }
  }
}

class _CandidateDetailsCard extends StatelessWidget {
  final CandidateAsset candidate;
  final VoidCallback onClose;

  const _CandidateDetailsCard({required this.candidate, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2F).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  '${candidate.voltageKv.toStringAsFixed(1)} kV',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  '•  ${candidate.distanceMeters.toStringAsFixed(0)} m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Visada RF (LoS): ', style: TextStyle(fontSize: 11, color: Colors.white70)),
                Text(
                  candidate.losVisada,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF34D399)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text('Altura Poste: ', style: TextStyle(fontSize: 11, color: Colors.white70)),
                Text(
                  '${candidate.poleHeightM.toStringAsFixed(0)} m',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BDGD ID: ${candidate.bdgdId}',
                  style: const TextStyle(fontSize: 11, color: Colors.white60),
                ),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ficha Técnica',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFA78BFA),
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new_rounded, size: 12, color: Color(0xFFA78BFA)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopMapBar extends StatelessWidget {
  final String activeLayer;
  final ValueChanged<String> onSelectLayer;

  const _TopMapBar({required this.activeLayer, required this.onSelectLayer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayerPill(
            label: 'Vetor BDGD',
            isSelected: activeLayer == 'vetor',
            onTap: () => onSelectLayer('vetor'),
          ),
          const SizedBox(width: 4),
          _LayerPill(
            label: 'Satélite Híbrido',
            isSelected: activeLayer == 'satelite',
            onTap: () => onSelectLayer('satelite'),
          ),
          const SizedBox(width: 4),
          _LayerPill(
            label: 'Relevo SRTM 30m',
            isSelected: activeLayer == 'relevo',
            onTap: () => onSelectLayer('relevo'),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryPurpleLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: AppColors.primaryPurple),
                SizedBox(width: 4),
                Text(
                  'Área Ativa',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple,
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

class _LayerPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LayerPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPurple : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetCenter;

  const _ZoomControls({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ZoomButton(icon: Icons.add_rounded, onTap: onZoomIn),
        const SizedBox(height: 4),
        _ZoomButton(icon: Icons.remove_rounded, onTap: onZoomOut),
        const SizedBox(height: 4),
        _ZoomButton(icon: Icons.crop_free_rounded, onTap: onResetCenter),
      ],
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Icon(icon, size: 18, color: AppColors.textPrimary),
      ),
    );
  }
}

class _CartographicLegendBar extends StatelessWidget {
  final AreaDelimitationController controller;

  const _CartographicLegendBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: const Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Text(
              'CONVENÇÃO CARTOGRÁFICA:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 12),
            _LegendItem(
              label: 'Poste MT (${controller.countForType(CandidateAssetType.poste)})',
              color: AppColors.primaryPurple,
              iconData: Icons.circle,
            ),
            const SizedBox(width: 12),
            _LegendItem(
              label: 'Trafo MT/BT (${controller.countForType(CandidateAssetType.trafo)})',
              color: const Color(0xFFF59E0B),
              iconData: Icons.crop_square_rounded,
            ),
            const SizedBox(width: 12),
            _LegendItem(
              label: 'Religador (${controller.countForType(CandidateAssetType.religador)})',
              color: const Color(0xFF4F46E5),
              iconData: Icons.crop_square_rounded,
            ),
            const SizedBox(width: 12),
            _LegendItem(
              label: 'Subestação (${controller.countForType(CandidateAssetType.subestacao)})',
              color: const Color(0xFFDC2626),
              iconData: Icons.bolt_rounded,
            ),
            const SizedBox(width: 12),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 2,
                  color: const Color(0xFFF97316),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Limite Concessão',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(width: 24),
            const Text(
              'Escala 1:25.000 • SIRGAS 2000',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;
  final IconData iconData;

  const _LegendItem({
    required this.label,
    required this.color,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(iconData, size: 10, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
