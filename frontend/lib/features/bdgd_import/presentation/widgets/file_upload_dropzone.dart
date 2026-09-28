import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/dashed_border_box.dart';

class FileUploadDropzone extends StatelessWidget {
  final PlatformFile? selectedFile;
  final bool isPicking;
  final String? errorMessage;
  final VoidCallback onPick;
  final VoidCallback onClear;

  const FileUploadDropzone({
    super.key,
    required this.selectedFile,
    required this.isPicking,
    required this.errorMessage,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Column(
      children: [
        DashedBorderBox(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isMobile ? 260 : 250),
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 28 : 44,
                horizontal: 16,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: isPicking
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(Icons.cloud_upload_rounded,
                              color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        const Text(
                          'Arraste e solte o pacote da distribuidora ou ',
                          style: TextStyle(fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        InkWell(
                          onTap: isPicking ? null : onPick,
                          child: const Text(
                            'procure arquivos',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Arquivos .ZIP contendo SHP/DBF/SHX, GeoPackage (.GPKG), GeoJSON\n'
                      'exportados do QGIS/ArcGIS ou dump tabular BDGD.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.vermelhoErro, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.vermelhoErro),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (selectedFile != null) ...[
          const SizedBox(height: 16),
          _UploadedFileTile(file: selectedFile!, onRemove: onClear),
        ],
      ],
    );
  }
}

class _UploadedFileTile extends StatelessWidget {
  final PlatformFile file;
  final VoidCallback onRemove;

  const _UploadedFileTile({required this.file, required this.onRemove});

  String get _sizeLabel {
    final bytes = file.size;
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.layers_rounded,
                color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(_sizeLabel,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}