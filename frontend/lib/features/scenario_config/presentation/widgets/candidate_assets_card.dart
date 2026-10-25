import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../controllers/area_delimitation_controller.dart';

class CandidateAssetsCard extends StatelessWidget {
  final AreaDelimitationController controller;

  const CandidateAssetsCard({super.key, required this.controller});

  static const List<CandidateAssetType> _allDisplayTypes = [
    CandidateAssetType.poste,
    CandidateAssetType.trafo,
    CandidateAssetType.religador,
    CandidateAssetType.subestacao,
    CandidateAssetType.ucbt,
    CandidateAssetType.ucmt,
    CandidateAssetType.ssdmt,
    CandidateAssetType.ssdbt,
    CandidateAssetType.ssdat,
    CandidateAssetType.uncrat,
  ];

  List<CandidateAssetType> _resolveDisplayTypes() {
    final result = controller.result;
    if (result == null) {
      return _allDisplayTypes;
    }

    final dynamicTypes = <CandidateAssetType>{};
    // Include types reported by backend counts or availableTypes
    for (final raw in result.availableTypes) {
      dynamicTypes.add(CandidateAssetTypeExt.fromString(raw));
    }
    result.countsByType.forEach((type, count) {
      if (count > 0) {
        dynamicTypes.add(type);
      }
    });

    // If backend provided types, filter _allDisplayTypes to present them in logical order,
    // plus any extra dynamic types found.
    if (dynamicTypes.isNotEmpty) {
      final ordered = _allDisplayTypes.where(dynamicTypes.contains).toList();
      for (final t in dynamicTypes) {
        if (!ordered.contains(t) && t != CandidateAssetType.outros) {
          ordered.add(t);
        }
      }
      return ordered.isEmpty ? _allDisplayTypes : ordered;
    }

    return _allDisplayTypes;
  }

  Color _colorForType(CandidateAssetType type) => type.color;

  IconData _iconForType(CandidateAssetType type) => type.icon;

  @override
  Widget build(BuildContext context) {
    final selectedTypes = controller.selectedAssetTypes;
    final totalCount = controller.totalCandidatesCount;
    final displayTypes = _resolveDisplayTypes();
    final allSelected = displayTypes.every(selectedTypes.contains);
    final noneSelected = selectedTypes.isEmpty;

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
              const Icon(Icons.hub_outlined, color: AppColors.primaryPurple, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ativos Candidatos Identificados',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurpleLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount Locais',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryPurple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Selecione as classes de estruturas BDGD que serão elegíveis para receber transceptores RF:',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                key: const ValueKey('btn_marcar_todos'),
                onPressed: allSelected
                    ? null
                    : () => controller.selectAllAssetTypes(displayTypes),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.check_box_outlined, size: 14),
                label: const Text('Marcar Todos'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                key: const ValueKey('btn_desmarcar_todos'),
                onPressed: noneSelected
                    ? null
                    : () => controller.deselectAllAssetTypes(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  foregroundColor: AppColors.textSecondary,
                ),
                icon: const Icon(Icons.check_box_outline_blank, size: 14),
                label: const Text('Desmarcar Todos'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: displayTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final type = displayTypes[index];
                return _AssetTypeRow(
                  type: type,
                  label: type.label,
                  count: controller.countForType(type),
                  color: _colorForType(type),
                  iconData: _iconForType(type),
                  isChecked: selectedTypes.contains(type),
                  onToggle: () => controller.toggleAssetType(type),
                );
              },
            ),
          ),
          if (noneSelected) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selecione ao menos um tipo de ativo para avançar.',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AssetTypeRow extends StatelessWidget {
  final CandidateAssetType type;
  final String label;
  final int count;
  final Color color;
  final IconData iconData;
  final bool isChecked;
  final VoidCallback onToggle;

  const _AssetTypeRow({
    required this.type,
    required this.label,
    required this.count,
    required this.color,
    required this.iconData,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isChecked ? AppColors.inputBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: isChecked,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.primaryPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(width: 8),
            Icon(iconData, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
