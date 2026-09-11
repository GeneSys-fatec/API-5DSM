import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BdgdBase {
  final String distribuidora;
  final String versaoBase;
  final int ativosMapeados;
  final String projecao;
  final Color tagColor;

  const BdgdBase({
    required this.distribuidora,
    required this.versaoBase,
    required this.ativosMapeados,
    required this.projecao,
    required this.tagColor,
  });
}

final List<BdgdBase> kMockBases = [
  const BdgdBase(
    distribuidora: 'CPFL Paulista (Regional Leste)',
    versaoBase: '2024.Q3 (Módulo 8)',
    ativosMapeados: 142850,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.warning,
  ),
  const BdgdBase(
    distribuidora: 'Enel Distribuição SP (Centro-Oeste)',
    versaoBase: '2024.Q2 (Consolidada)',
    ativosMapeados: 128430,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.success,
  ),
  const BdgdBase(
    distribuidora: 'Neoenergia Elektro (Mogi Mirim)',
    versaoBase: '2023.Q4 (Auditoria)',
    ativosMapeados: 91200,
    projecao: 'SIRGAS 2000 / UTM 23S',
    tagColor: AppColors.info,
  ),
];