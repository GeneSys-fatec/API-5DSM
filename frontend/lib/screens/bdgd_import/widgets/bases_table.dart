import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../models/bdgd_base.dart';

class BasesTable extends StatelessWidget {
  final List<BdgdBase> bases;
  const BasesTable({super.key, required this.bases});

  static const _flexDistribuidora = 3;
  static const _flexVersao = 2;
  static const _flexAtivos = 2;
  static const _flexProjecao = 2;
  static const _flexAcoes = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.surfaceAlt,
          child: const Row(
            children: [
              Expanded(
                  flex: _flexDistribuidora,
                  child: Text('DISTRIBUIDORA / REGIONAL',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                  flex: _flexVersao,
                  child: Text('VERSÃO BASE',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                  flex: _flexAtivos,
                  child: Text('ATIVOS MAPEADOS',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                  flex: _flexProjecao,
                  child: Text('PROJEÇÃO / DATUM',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
              Expanded(
                  flex: _flexAcoes,
                  child:
                      Text('AÇÕES', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ],
          ),
        ),
        ...bases.map((b) => Container(
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
                        Expanded(child: Text(b.distribuidora, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  Expanded(flex: _flexVersao, child: Text(b.versaoBase)),
                  Expanded(flex: _flexAtivos, child: Text('${formatThousands(b.ativosMapeados)} pts')),
                  Expanded(flex: _flexProjecao, child: Text(b.projecao)),
                  Expanded(
                    flex: _flexAcoes,
                    child: Row(
                      children: const [
                        Icon(Icons.map_outlined, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 10),
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}