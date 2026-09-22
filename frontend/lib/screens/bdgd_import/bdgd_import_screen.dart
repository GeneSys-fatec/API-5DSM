import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../widgets/common/app_scaffold.dart';
import 'models/bdgd_base.dart';
import 'widgets/bases_section.dart';
import 'widgets/file_upload_dropzone.dart';

const List<String> kAllowedExtensions = ['zip', 'gpkg', 'json', 'geojson'];

class BdgdImportScreen extends StatefulWidget {
  const BdgdImportScreen({super.key});

  @override
  State<BdgdImportScreen> createState() => _BdgdImportScreenState();
}

class _BdgdImportScreenState extends State<BdgdImportScreen> {
  PlatformFile? _selectedFile;
  bool _isPicking = false;
  String? _errorMessage;

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
      );

      if (result == null) {
        return;
      }

      setState(() {
        _selectedFile = result.files.single;
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
    });
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
          FileUploadDropzone(
            selectedFile: _selectedFile,
            isPicking: _isPicking,
            errorMessage: _errorMessage,
            onPick: _pickFile,
            onClear: _clearFile,
          ),
          const SizedBox(height: 24),
          BasesSection(bases: kMockBases),
        ],
      ),
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
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'ANEEL PRODIST Módulo 8',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
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
                children: [Expanded(child: title), badge],
              ),
      ),
    );
  }
}