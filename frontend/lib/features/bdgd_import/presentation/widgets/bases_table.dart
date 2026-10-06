import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../models/bdgd_base.dart';

class BasesTable extends StatelessWidget {
  final List<BdgdBase> bases;
  final ValueChanged<BdgdBase>? onSelectBase;
  const BasesTable({super.key, required this.bases, this.onSelectBase});

  static const _flexDistribuidora = 3;
  static const _flexVersao = 2;
  static const _flexStatus = 2;
  static const _flexAtivos = 2;
  static const _flexProjecao = 2;
  static const _flexAcao = 2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.backgroundLight,
          child: const Row(
            children: [
              Expanded(
                flex: _flexDistribuidora,
                child: Text(
                  'DISTRIBUIDORA / REGIONAL',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                flex: _flexVersao,
                child: Text(
                  'REFERÊNCIA / ARQUIVO',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                flex: _flexStatus,
                child: Text(
                  'STATUS',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                flex: _flexAtivos,
                child: Text(
                  'ATIVOS MAPEADOS',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                flex: _flexProjecao,
                child: Text(
                  'PROJEÇÃO / DATUM',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              Expanded(
                flex: _flexAcao,
                child: Text(
                  'AÇÃO',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        ...bases.map(
          (b) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: _flexDistribuidora,
                  child: Row(
                    children: [
                      Container(width: 4, height: 32, color: b.tagColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.distribuidora,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (b.fileName != null)
                              Text(
                                b.fileName!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: _flexVersao,
                  child: Text(
                    b.versaoBase,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: _flexStatus,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: b.tagColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: b.tagColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        b.statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: b.tagColor,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexAtivos,
                  child: Text(
                    b.ativosMapeados > 0
                        ? '${formatThousands(b.ativosMapeados)} pts'
                        : (b.status == 'processando'
                              ? 'Em processamento...'
                              : '0 pts'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: b.ativosMapeados > 0
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: b.ativosMapeados > 0
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexProjecao,
                  child: Text(
                    b.projecao,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: _flexAcao,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ElevatedButton.icon(
                      onPressed:
                          (b.status == 'concluido' || b.status == 'concluído')
                          ? () => onSelectBase?.call(b)
                          : null,
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text(
                        'Simular',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.border,
                        disabledForegroundColor: AppColors.textMuted,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
