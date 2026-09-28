import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class BdgdBase {
  final String? id;
  final String distribuidora;
  final String? regiao;
  final String? dataReferencia;
  final String? fileName;
  final String? status;
  final String versaoBase;
  final int ativosMapeados;
  final String projecao;
  final Color tagColor;
  final String? errorMessage;

  const BdgdBase({
    this.id,
    required this.distribuidora,
    this.regiao,
    this.dataReferencia,
    this.fileName,
    this.status,
    required this.versaoBase,
    required this.ativosMapeados,
    required this.projecao,
    required this.tagColor,
    this.errorMessage,
  });

  factory BdgdBase.fromJson(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'desconhecido').toLowerCase();
    Color color;
    switch (statusStr) {
      case 'concluido':
      case 'concluído':
      case 'completed':
        color = AppColors.success;
        break;
      case 'falhou':
      case 'failed':
      case 'error':
        color = AppColors.error;
        break;
      case 'processando':
      case 'processing':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.info;
    }

    final distribuidora = json['distribuidora'] as String? ?? 'Desconhecida';
    final regiao = json['regiao'] as String?;
    final dataRef = json['dataReferencia'] as String? ?? json['data'] as String?;
    final fileName = json['fileName'] as String?;

    String versao = 'Módulo 8';
    if (dataRef != null && dataRef.isNotEmpty) {
      versao = 'Data Ref: $dataRef';
    } else if (fileName != null && fileName.isNotEmpty) {
      versao = fileName;
    }

    String distFormatada = distribuidora;
    if (regiao != null && regiao.isNotEmpty) {
      distFormatada = '$distribuidora ($regiao)';
    }

    return BdgdBase(
      id: json['id']?.toString(),
      distribuidora: distFormatada,
      regiao: regiao,
      dataReferencia: dataRef,
      fileName: fileName,
      status: statusStr,
      versaoBase: versao,
      ativosMapeados: (json['ativosMapeados'] as num?)?.toInt() ?? 0,
      projecao: json['projecao'] as String? ?? 'SIRGAS 2000 / UTM 23S',
      tagColor: color,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  String get statusLabel {
    switch (status) {
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'falhou':
        return 'Falhou';
      case 'processando':
        return 'Processando';
      default:
        return status ?? 'Desconhecido';
    }
  }
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