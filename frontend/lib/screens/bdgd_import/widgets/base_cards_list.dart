import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/bdgd_base.dart';

class BaseCardsList extends StatelessWidget {
  final List<BdgdBase> bases;
  const BaseCardsList({super.key, required this.bases});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: bases
          .map((b) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: b.tagColor, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.distribuidora,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text('${b.versaoBase} · ${formatThousands(b.ativosMapeados)} pts',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    Text(b.projecao,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: const [
                        Icon(Icons.map_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 16),
                        Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 16),
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      ],
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}