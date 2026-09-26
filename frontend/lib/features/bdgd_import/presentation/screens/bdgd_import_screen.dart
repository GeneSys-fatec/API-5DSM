import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

  List<BdgdBase> _bases = [];
  bool _isLoadingBases = false;
  String? _basesError;

  @override
  void initState() {
    super.initState();
    _loadBases();
  }

  Future<void> _loadBases() async {
    setState(() {
      _isLoadingBases = true;
      _basesError = null;
    });

    try {
      final bases = await _importService.fetchBases();
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

  Future<void> _pickFile() async {
    setState(() {
      _isPicking = true;
      _errorMessage = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: kAllowedExtensions,
        withData: false, // Muito importante: não carregar na memória
        withReadStream: true, // Importante: ler como fluxo de dados
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
      print('1. Iniciando chamada do Service na Tela...');
      await _importService.upload(
        fileName: file.name,
        fileStream: file.readStream, // Passando o stream
        fileSize: file.size,         // Passando o tamanho
        filePath: kIsWeb ? null : file.path, // Corrige o erro de path na Web
        distribuidora: _distribuidoraController.text.trim(),
        regiao: _regiaoController.text.trim(),
        data: _dataController.text.trim(),
      );
      print('6. Upload concluído com sucesso e retornado à Tela!');
      
      if (!mounted) return;
      setState(() => _successMessage = 'Arquivo enviado para a pasta uploads.');
      _clearFile();
      _loadBases();
    } on BdgdUploadException catch (e) {
      print('Erro BdgdUploadException: ${e.message}');
      if (mounted) setState(() => _errorMessage = e.message);
    } catch (e, stackTrace) {
      print('Erro fatal desconhecido no Dart: $e');
      print('Stacktrace: $stackTrace');
      if (mounted) setState(() => _errorMessage = 'Erro local: $e');
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
              child: Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: _metadataField(
                      _distribuidoraController,
                      'Distribuidora',
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: _metadataField(_regiaoController, 'Região'),
                  ),
                  SizedBox(
                    width: 180,
                    child: _metadataField(
                      _dataController,
                      'Data',
                      hint: 'AAAA-MM-DD',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          FileUploadDropzone(
            selectedFile: _selectedFile,
            isPicking: _isPicking,
            errorMessage: _errorMessage,
            onPick: _pickFile,
            onClear: _clearFile,
          ),
          if (_successMessage != null) ...[
            const SizedBox(height: 12),
            Text(_successMessage!, style: const TextStyle(color: Colors.green)),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _selectedFile == null || _isUploading
                ? null
                : _uploadFile,
            icon: _isUploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file_rounded),
            label: Text(_isUploading ? 'Enviando...' : 'Enviar arquivo'),
          ),
          const SizedBox(height: 24),
          BasesSection(
            bases: _bases,
            isLoading: _isLoadingBases,
            onRefresh: _loadBases,
            error: _basesError,
          ),
        ],
      ),
    );
  }

  Widget _metadataField(
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  @override
  void dispose() {
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
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ANEEL PRODIST Módulo 8',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
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