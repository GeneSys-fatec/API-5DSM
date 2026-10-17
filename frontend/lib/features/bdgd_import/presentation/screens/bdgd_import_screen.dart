import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../platform/bdgd_web_file.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../data/bdgd_import_service.dart';
import '../../models/bdgd_base.dart';
import '../widgets/bases_section.dart';
import '../widgets/file_upload_dropzone.dart';
import '../../../scenario_config/domain/models/area_delimitation_model.dart';
import '../../../scenario_config/presentation/controllers/area_delimitation_controller.dart';

const List<String> kAllowedExtensions = ['zip'];

class BdgdImportScreen extends StatefulWidget {
  const BdgdImportScreen({super.key});

  @override
  State<BdgdImportScreen> createState() => _BdgdImportScreenState();
}

class _BdgdImportScreenState extends State<BdgdImportScreen> {
  PlatformFile? _selectedFile;
  WebFile? _webFile; // arquivo nativo do browser para upload chunked
  bool _isPicking = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0; // 0.0 a 1.0
  String? _errorMessage;
  String? _successMessage;
  final _distribuidoraController = TextEditingController();
  final _regiaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _importService = BdgdImportService();

  List<BdgdBase> _bases = [];
  bool _isLoadingBases = false;
  String? _basesError;
  List<String> _regions = [];
  List<String> _distributors = [];
  String? _selectedRegion;
  String? _selectedDistributor;
  final GlobalKey _dateFieldKey = GlobalKey();
  OverlayEntry? _dateOverlayEntry;

  @override
  void initState() {
    super.initState();
    _loadBases();
    _loadFilterOptions();
  }

  Future<void> _loadBases() async {
    setState(() {
      _isLoadingBases = true;
      _basesError = null;
    });

    try {
      final bases = await _importService.fetchBases(
        regiao: _selectedRegion,
        distribuidora: _selectedDistributor,
      );
      if (!mounted) return;
      setState(() {
        _bases = bases;
      });
    } on BdgdUploadException catch (e) {
      if (!mounted) return;
      setState(() {
        _basesError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _basesError = 'Falha ao carregar lista de bases.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingBases = false;
        });
      }
    }
  }

  Future<void> _loadFilterOptions() async {
    final regions = await _importService.fetchRegions();
    final distributors = await _importService.fetchDistributors(
      regiao: _selectedRegion,
    );
    if (!mounted) return;
    setState(() {
      _regions = regions;
      _distributors = distributors;
      if (_selectedRegion != null && !_regions.contains(_selectedRegion)) {
        _selectedRegion = null;
      }
      if (_selectedDistributor != null &&
          !_distributors.contains(_selectedDistributor)) {
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

  Future<void> _clearFilters() async {
    setState(() {
      _selectedRegion = null;
      _selectedDistributor = null;
    });
    await _loadFilterOptions();
    await _loadBases();
  }

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedExtensions,
        withData: false,
        withReadStream: true,
      );

      if (result == null) return;

      setState(() {
        _selectedFile = result.files.single;
        _webFile = null; // será obtido via readStream
        _successMessage = null;
        _uploadProgress = 0.0;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Não foi possível abrir o seletor de arquivos.';
      });
    } finally {
      setState(() {
        _isPicking = false;
      });
    }
  }

  void _toggleDatePicker() {
    if (_dateOverlayEntry != null) {
      _removeDateOverlay();
      return;
    }

    final renderBox =
        _dateFieldKey.currentContext!.findRenderObject() as RenderBox;
    final fieldSize = renderBox.size;
    final fieldPosition = renderBox.localToGlobal(Offset.zero);
    final now = DateTime.now();
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    const calendarHeight = 360.0;
    const margin = 12.0;

    final panelWidth = fieldSize.width < 300 ? 300.0 : fieldSize.width;

    var left = fieldPosition.dx;
    if (left + panelWidth > screenWidth - margin) {
      left = screenWidth - panelWidth - margin;
    }
    if (left < margin) {
      left = margin;
    }

    final spaceBelow = screenHeight - (fieldPosition.dy + fieldSize.height);
    final spaceAbove = fieldPosition.dy;

    double top;
    if (spaceBelow >= calendarHeight + margin || spaceBelow >= spaceAbove) {
      top = fieldPosition.dy + fieldSize.height + 6;
      final maxTop = screenHeight - margin - calendarHeight;
      if (top > maxTop) top = maxTop;
    } else {
      top = fieldPosition.dy - calendarHeight - 6;
    }
    if (top < margin) top = margin;

    _dateOverlayEntry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeDateOverlay,
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: panelWidth,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: screenHeight - (2 * margin),
                  ),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                primary: AppColors.primary,
                                onPrimary: Colors.white,
                              ),
                        ),
                        child: CalendarDatePicker(
                          initialDate: _parseDate(_dataController.text) ?? now,
                          firstDate: DateTime(now.year - 15),
                          lastDate: DateTime(now.year + 1),
                          onDateChanged: (picked) {
                            setState(() {
                              _dataController.text =
                                  '${picked.year.toString().padLeft(4, '0')}-'
                                  '${picked.month.toString().padLeft(2, '0')}-'
                                  '${picked.day.toString().padLeft(2, '0')}';
                            });
                            _removeDateOverlay();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_dateOverlayEntry!);
  }

  void _removeDateOverlay() {
    _dateOverlayEntry?.remove();
    _dateOverlayEntry = null;
  }

  DateTime? _parseDate(String value) {
    if (value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  void _clearFile() {
    setState(() {
      _selectedFile = null;
      _webFile = null;
      _errorMessage = null;
      _successMessage = null;
      _uploadProgress = 0.0;
    });
  }

  Future<void> _uploadFile() async {
    final file = _selectedFile;
    if (file == null) return;
    if (_distribuidoraController.text.trim().isEmpty ||
        _regiaoController.text.trim().isEmpty ||
        _dataController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Preencha distribuidora, região e data.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _importService.upload(
        fileName: file.name,
        fileStream: file.readStream, 
        fileSize: file.size,        
        filePath: kIsWeb ? null : file.path, 
        distribuidora: _distribuidoraController.text.trim(),
        regiao: _regiaoController.text.trim(),
        data: _dataController.text.trim(),
        onProgress: (p) {
          if (mounted) setState(() => _uploadProgress = p);
        },
      );

      if (!mounted) return;
      setState(() {
        _successMessage = 'Arquivo enviado com sucesso!';
        _uploadProgress = 1.0;
      });
      _clearFile();
      _loadBases();
    } on BdgdUploadException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e, stackTrace) {
      print('Erro fatal: $e\n$stackTrace');
      if (mounted) setState(() => _errorMessage = 'Erro: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Importação de Dados BDGD & Ativos de Rede',
      currentRoute: '/bdgd-import',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ImportTitleCard(),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Dados da importação',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final isMobile = Responsive.isMobile(context);
                      return Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          SizedBox(
                            width: isMobile
                                ? MediaQuery.of(context).size.width - 72
                                : 220,
                            child: _metadataField(
                              _distribuidoraController,
                              'Distribuidora',
                              icon: Icons.business_rounded,
                            ),
                          ),
                          SizedBox(
                            width: isMobile
                                ? MediaQuery.of(context).size.width - 72
                                : 220,
                            child: _metadataField(
                              _regiaoController,
                              'Região',
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          SizedBox(
                            width: isMobile
                                ? MediaQuery.of(context).size.width - 72
                                : 220,
                            child: _metadataField(
                              _dataController,
                              'Data',
                              hint: 'Selecione a data',
                              icon: Icons.calendar_today_outlined,
                              readOnly: true,
                              onTap: _toggleDatePicker,
                              fieldKey: _dateFieldKey,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Arquivo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey.shade700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FileUploadDropzone(
                    selectedFile: _selectedFile,
                    isPicking: _isPicking,
                    errorMessage: _errorMessage,
                    onPick: _pickFile,
                    onClear: _clearFile,
                  ),
                  if (_successMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  // Barra de progresso do upload chunked
                  if (_isUploading) ...[
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Enviando em partes…',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                            Text(
                              '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _uploadProgress,
                            minHeight: 6,
                            backgroundColor: AppColors.primaryLight,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _selectedFile == null || _isUploading
                            ? null
                            : _uploadFile,
                        icon: _isUploading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file_rounded, size: 18),
                        label: Text(
                          _isUploading
                              ? 'Enviando ${(_uploadProgress * 100).toStringAsFixed(0)}%…'
                              : 'Enviar arquivo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildFilters(),
          const SizedBox(height: 16),
          BasesSection(
            bases: _bases,
            isLoading: _isLoadingBases,
            onRefresh: _loadBases,
            error: _basesError,
            onSelectBase: _onSelectBase,
            onEditBase: _editBase,
            emptyMessage: (_selectedRegion != null || _selectedDistributor != null)
                ? 'Nenhuma base encontrada para os filtros selecionados.'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final hasFilters = _selectedRegion != null || _selectedDistributor != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            SizedBox(
              width: 260,
              child: _filterDropdown(
                label: 'Região',
                hint: 'Todas as regiões',
                value: _selectedRegion,
                items: _regions,
                onChanged: _isLoadingBases ? null : _onRegionChanged,
              ),
            ),
            SizedBox(
              width: 300,
              child: _filterDropdown(
                label: 'Distribuidora',
                hint: 'Todas as distribuidoras',
                value: _selectedDistributor,
                items: _distributors,
                onChanged: _isLoadingBases ? null : _onDistributorChanged,
              ),
            ),
            if (hasFilters)
              TextButton.icon(
                onPressed: _isLoadingBases ? null : _clearFilters,
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpar filtros'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filterDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: (value != null && items.contains(value)) ? value : null,
              hint: Text(
                hint,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: items
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
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

  void _onSelectBase(BdgdBase base) {
    final config = AreaDelimitationConfig(
      centerLatitude: base.defaultLatitude,
      centerLongitude: base.defaultLongitude,
      address: base.defaultAddress,
      radiusKm: 3.5,
      baseName: base.distribuidora,
      bdgdImportId: base.id,
    );
    AreaDelimitationController.setSharedConfig(config);
    Navigator.of(context).pushReplacementNamed('/scenario');
  }

  Future<void> _editBase(BdgdBase base) async {
    if (base.id == null) return;

    final result = await showDialog<({String regiao, String distribuidora})>(
      context: context,
      builder: (_) => _EditGroupDialog(base: base),
    );
    if (result == null || !mounted) return;

    try {
      await _importService.updateBaseGroup(
        id: base.id!,
        regiao: result.regiao,
        distribuidora: result.distribuidora,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grupo da base atualizado com sucesso.')),
      );
      await _loadFilterOptions();
      await _loadBases();
    } on BdgdUploadException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível atualizar o grupo da base.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _metadataField(
    TextEditingController controller,
    String label, {
    String? hint,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    Key? fieldKey,
  }) {
    return TextField(
      key: fieldKey,
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1F2937),
      ),
      cursorColor: AppColors.primary,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade400,
        ),
        prefixIcon: icon == null
            ? null
            : Icon(icon, size: 18, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade600,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeDateOverlay();
    _distribuidoraController.dispose();
    _regiaoController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}

class _EditGroupDialog extends StatefulWidget {
  final BdgdBase base;

  const _EditGroupDialog({required this.base});

  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late final TextEditingController _regiaoController;
  late final TextEditingController _distribuidoraController;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _regiaoController = TextEditingController(text: widget.base.regiao ?? '');
    _distribuidoraController = TextEditingController(text: widget.base.distribuidora);
  }

  @override
  void dispose() {
    _regiaoController.dispose();
    _distribuidoraController.dispose();
    super.dispose();
  }

  void _submit() {
    final regiao = _regiaoController.text.trim();
    final distribuidora = _distribuidoraController.text.trim();
    if (regiao.isEmpty || distribuidora.isEmpty) {
      setState(() => _validationError = 'Preencha região e distribuidora.');
      return;
    }
    Navigator.of(context).pop((regiao: regiao, distribuidora: distribuidora));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar grupo da base'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mova a base para outra região/distribuidora.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _regiaoController,
            decoration: const InputDecoration(
              labelText: 'Região',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _distribuidoraController,
            decoration: const InputDecoration(
              labelText: 'Distribuidora',
              border: OutlineInputBorder(),
            ),
          ),
          if (_validationError != null) ...[
            const SizedBox(height: 12),
            Text(
              _validationError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _ImportTitleCard extends StatelessWidget {
  const _ImportTitleCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    );

    final title = Text(
      'Importação de Dados BDGD & Ativos de Rede',
      style: Theme.of(context).textTheme.titleLarge,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [title, const SizedBox(height: 10), badge],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: title),
                  badge,
                ],
              ),
      ),
    );
  }
}