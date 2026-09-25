import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../data/bdgd_import_service.dart';
import '../../models/bdgd_base.dart';
import '../widgets/bases_section.dart';
import '../widgets/file_upload_dropzone.dart';

const List<String> kAllowedExtensions = ['zip'];

class BdgdImportScreen extends StatefulWidget {
  const BdgdImportScreen({super.key});

  @override
  State<BdgdImportScreen> createState() => _BdgdImportScreenState();
}

class _BdgdImportScreenState extends State<BdgdImportScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  bool _isUploading = false;
  String? _errorMessage;
  String? _successMessage;
  final _distribuidoraController = TextEditingController();
  final _regiaoController = TextEditingController();
  final _dataController = TextEditingController();
  final _importService = BdgdImportService();

  final GlobalKey _dateFieldKey = GlobalKey();
  OverlayEntry? _dateOverlayEntry;

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedExtensions,
        withData: true,
      );

      if (result == null) {
        return;
      }

      setState(() {
        _selectedFile = result.files.single;
        _successMessage = null;
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
      _errorMessage = null;
      _successMessage = null;
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
      _errorMessage = null;
      _successMessage = null;
    });
    try {
      await _importService.upload(
        fileName: file.name,
        fileBytes: file.bytes ?? const [],
        filePath: file.path,
        distribuidora: _distribuidoraController.text.trim(),
        regiao: _regiaoController.text.trim(),
        data: _dataController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _successMessage = 'Arquivo enviado para a pasta uploads.');
    } on BdgdUploadException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (_) {
      if (mounted) setState(() => _errorMessage = 'Falha ao enviar o arquivo.');
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
                    Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
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
                          _isUploading ? 'Enviando...' : 'Enviar arquivo',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          BasesSection(bases: kMockBases),
        ],
      ),
    );
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
