import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/area_delimitation_model.dart';
import '../controllers/area_delimitation_controller.dart';

class CandidateAssetsCard extends StatelessWidget {
  final AreaDelimitationController controller;

  const CandidateAssetsCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final selectedTypes = controller.selectedAssetTypes;
    final totalCount = controller.totalCandidatesCount;

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
          const SizedBox(height: 12),
          _AssetTypeRow(
            type: CandidateAssetType.poste,
            label: 'Postes de Média Tensão (PONNOT)',
            count: controller.countForType(CandidateAssetType.poste),
            color: AppColors.primaryPurple,
            iconData: Icons.circle,
            isChecked: selectedTypes.contains(CandidateAssetType.poste),
            onToggle: () => controller.toggleAssetType(CandidateAssetType.poste),
          ),
          const SizedBox(height: 8),
          _AssetTypeRow(
            type: CandidateAssetType.trafo,
            label: 'Transformadores MT/BT (UNTRMT)',
            count: controller.countForType(CandidateAssetType.trafo),
            color: const Color(0xFFF59E0B),
            iconData: Icons.crop_square_rounded,
            isChecked: selectedTypes.contains(CandidateAssetType.trafo),
            onToggle: () => controller.toggleAssetType(CandidateAssetType.trafo),
          ),
          const SizedBox(height: 8),
          _AssetTypeRow(
            type: CandidateAssetType.religador,
            label: 'Religadores e Chaves (UNREMT)',
            count: controller.countForType(CandidateAssetType.religador),
            color: const Color(0xFF4F46E5),
            iconData: Icons.crop_square_rounded,
            isChecked: selectedTypes.contains(CandidateAssetType.religador),
            onToggle: () => controller.toggleAssetType(CandidateAssetType.religador),
          ),
          const SizedBox(height: 8),
          _AssetTypeRow(
            type: CandidateAssetType.subestacao,
            label: 'Subestações Elétricas (SUB)',
            count: controller.countForType(CandidateAssetType.subestacao),
            color: const Color(0xFFDC2626),
            iconData: Icons.bolt_rounded,
            isChecked: selectedTypes.contains(CandidateAssetType.subestacao),
            onToggle: () => controller.toggleAssetType(CandidateAssetType.subestacao),
          ),
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
