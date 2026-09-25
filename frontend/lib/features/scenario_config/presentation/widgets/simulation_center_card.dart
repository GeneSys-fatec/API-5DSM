import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/area_delimitation_controller.dart';

class SimulationCenterCard extends StatefulWidget {
  final AreaDelimitationController controller;

  const SimulationCenterCard({super.key, required this.controller});

  @override
  State<SimulationCenterCard> createState() => _SimulationCenterCardState();
}

class _SimulationCenterCardState extends State<SimulationCenterCard> {
  late final TextEditingController _addressCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;

  @override
  void initState() {
    super.initState();
    final cfg = widget.controller.config;
    _addressCtrl = TextEditingController(text: cfg.address);
    _latCtrl = TextEditingController(text: cfg.centerLatitude.toStringAsFixed(4));
    _lngCtrl = TextEditingController(text: cfg.centerLongitude.toStringAsFixed(4));
    widget.controller.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    final cfg = widget.controller.config;
    final newLat = cfg.centerLatitude.toStringAsFixed(4);
    final newLng = cfg.centerLongitude.toStringAsFixed(4);
    if (_latCtrl.text != newLat) {
      _latCtrl.text = newLat;
    }
    if (_lngCtrl.text != newLng) {
      _lngCtrl.text = newLng;
    }
    if (_addressCtrl.text != cfg.address) {
      _addressCtrl.text = cfg.address;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    _addressCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  void _commitCoordinates() {
    final lat = double.tryParse(_latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(_lngCtrl.text.replaceAll(',', '.'));
    if (lat != null && lng != null) {
      widget.controller.setCenterCoordinates(lat, lng);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defineClicking = widget.controller.defineClickingOnMap;

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
              const Icon(Icons.location_on_outlined, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ponto Central da Simulação',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'GIS ANCHOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'BUSCAR ENDEREÇO OU SUBESTAÇÃO BDGD:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _addressCtrl,
            onChanged: (val) => widget.controller.setAddressQuery(val),
            decoration: InputDecoration(
              hintText: 'Av. Pres. Kennedy, Campinas - SP',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _addressCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.cancel_rounded, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        _addressCtrl.clear();
                        widget.controller.clearAddress();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.inputBackground,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.inputBorderFocused, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latitude (SIRGAS)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _latCtrl,
                      onSubmitted: (_) => _commitCoordinates(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        suffixText: '°S',
                        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitude (SIRGAS)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _lngCtrl,
                      onSubmitted: (_) => _commitCoordinates(),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: InputDecoration(
                        suffixText: '°W',
                        suffixStyle: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        filled: true,
                        fillColor: AppColors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () => widget.controller.setDefineClickingOnMap(!defineClicking),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, color: AppColors.primaryPurple, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Definir Clicando no Mapa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: defineClicking,
                    onChanged: (val) => widget.controller.setDefineClickingOnMap(val),
                    activeTrackColor: AppColors.primaryPurple,
                    activeThumbColor: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
