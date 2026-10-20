import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/area_delimitation_controller.dart';
import '../../../bdgd_import/data/bdgd_import_service.dart';
import '../../../bdgd_import/models/bdgd_base.dart';

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
  List<BdgdBase> _bases = [];
  BdgdBase? _selectedBase;
  List<String> _regions = [];
  List<String> _distributors = [];
  String? _selectedRegion;
  String? _selectedDistributor;
  final BdgdImportService _importService = BdgdImportService();

  @override
  void initState() {
    super.initState();
    final cfg = widget.controller.config;
    _addressCtrl = TextEditingController(text: cfg.address);
    _latCtrl = TextEditingController(text: cfg.centerLatitude.toStringAsFixed(4));
    _lngCtrl = TextEditingController(text: cfg.centerLongitude.toStringAsFixed(4));
    widget.controller.addListener(_onControllerChange);
    _loadFilterOptions();
    _loadBases();
  }

  Future<void> _loadFilterOptions() async {
    final regions = await _importService.fetchRegions();
    final distributors = await _importService.fetchDistributors(regiao: _selectedRegion);
    if (!mounted) return;
    setState(() {
      _regions = regions;
      _distributors = distributors;
      if (_selectedRegion != null && !_regions.contains(_selectedRegion)) {
        _selectedRegion = null;
      }
      if (_selectedDistributor != null && !_distributors.contains(_selectedDistributor)) {
        _selectedDistributor = null;
      }
    });
  }

  Future<void> _onRegionChanged(String? value) async {
    setState(() {
      _selectedRegion = value;
      _selectedDistributor = null;
    });
    await _loadFilterOptions();
    await _loadBases();
  }

  Future<void> _onDistributorChanged(String? value) async {
    setState(() {
      _selectedDistributor = value;
    });
    await _loadBases();
  }

  String _baseKey(BdgdBase base) => base.id ?? base.distribuidora;

  Future<void> _loadBases() async {
    try {
      final bases = await _importService.fetchBases(
        regiao: _selectedRegion,
        distribuidora: _selectedDistributor,
      );
      if (!mounted) return;
      setState(() {
        _bases = bases;
        final currentKey = _selectedBase != null ? _baseKey(_selectedBase!) : null;
        final stillPresent =
            currentKey != null && _bases.any((b) => _baseKey(b) == currentKey);
        if (!stillPresent) {
          if (_bases.isEmpty) {
            _selectedBase = null;
          } else {
            final cfgBase = widget.controller.config.baseName.toLowerCase();
            try {
              _selectedBase = _bases.firstWhere(
                (b) => b.distribuidora.toLowerCase().contains(cfgBase) ||
                       cfgBase.contains(b.distribuidora.toLowerCase()),
              );
            } catch (_) {
              _selectedBase = _bases.first;
            }
          }
        }
      });
    } catch (_) {}
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

  Widget _filterSelector({
    required String label,
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: (value != null && items.contains(value)) ? value : null,
              hint: Text(
                hint,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final defineClicking = widget.controller.defineClickingOnMap;
    final pointOutOfBounds = widget.controller.pointOutOfBounds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: pointOutOfBounds ? AppColors.vermelhoErro : AppColors.cardBorder,
          width: pointOutOfBounds ? 1.5 : 1.0,
        ),
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
          if (_regions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _filterSelector(
                    label: 'REGIÃO',
                    value: _selectedRegion,
                    hint: 'Todas as regiões',
                    items: _regions,
                    onChanged: _onRegionChanged,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _filterSelector(
                    label: 'DISTRIBUIDORA',
                    value: _selectedDistributor,
                    hint: 'Todas as distribuidoras',
                    items: _distributors,
                    onChanged: _onDistributorChanged,
                  ),
                ),
              ],
            ),
          ],
          if (_bases.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'BASE DE DADOS BDGD IMPORTADA:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedBase != null
                      ? (_selectedBase!.id ?? _selectedBase!.distribuidora)
                      : null,
                  hint: const Text(
                    'Selecione uma base BDGD importada...',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: _bases.map<DropdownMenuItem<String>>((BdgdBase b) {
                    final itemKey = b.id ?? b.distribuidora;
                    return DropdownMenuItem<String>(
                      value: itemKey,
                      child: Text(
                        '${b.displayName} (${b.ativosMapeados} pts)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val == null) return;
                    final found = _bases.firstWhere(
                      (b) => (b.id ?? b.distribuidora) == val,
                      orElse: () => _bases.first,
                    );
                    setState(() {
                      _selectedBase = found;
                    });
                    widget.controller.applyConfig(
                      widget.controller.config.copyWith(
                        centerLatitude: found.defaultLatitude,
                        centerLongitude: found.defaultLongitude,
                        address: found.defaultAddress,
                        baseName: found.distribuidora,
                        bdgdImportId: found.id,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
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
          if (pointOutOfBounds) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.badgeRedLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.badgeRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 16, color: AppColors.vermelhoErro),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'O ponto informado esta fora da area de cobertura da BDGD selecionada. Escolha um ponto dentro do contorno destacado no mapa.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vermelhoErro,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.controller.areaDelimitationError != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.badgeRedLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.badgeRed.withValues(alpha: 0.4)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.vermelhoErro),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.controller.areaDelimitationError!,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColors.vermelhoErro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: widget.controller.isLoading
                        ? null
                        : widget.controller.evaluateArea,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          ],
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
