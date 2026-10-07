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

  double get defaultLatitude {
    final lower = '${distribuidora.toLowerCase()} ${(regiao ?? '').toLowerCase()}';
    if (lower.contains('sulgipe')) {
      return -11.2683;
    }
    if (lower.contains('brasilia') || lower.contains('brasília') || lower.contains('ceb')) {
      return -15.7975;
    }
    if (lower.contains('energisa') || lower.contains('sergipe') || lower.contains('sul / se')) {
      return -10.9095;
    }
    if (lower.contains('enel') || lower.contains('são paulo') || lower.contains('capital')) {
      return -23.5505;
    }
    if (lower.contains('edp') || lower.contains('vale') || lower.contains('sjc') || lower.contains('jacareí')) {
      return -23.2010;
    }
    if (lower.contains('light') || lower.contains('rio')) {
      return -22.9068;
    }
    if (lower.contains('cemig') || lower.contains('minas') || lower.contains('bh')) {
      return -19.9208;
    }
    if (lower.contains('copel') || lower.contains('paraná') || lower.contains('curitiba')) {
      return -25.4284;
    }
    if (lower.contains('equatorial') || lower.contains('pará') || lower.contains('maranhão')) {
      return -1.4558;
    }
    if (lower.contains('neoenergia') || lower.contains('bahia') || lower.contains('coelba')) {
      return -12.9777;
    }
    return -22.9068;
  }

  double get defaultLongitude {
    final lower = '${distribuidora.toLowerCase()} ${(regiao ?? '').toLowerCase()}';
    if (lower.contains('sulgipe')) {
      return -37.4383;
    }
    if (lower.contains('brasilia') || lower.contains('brasília') || lower.contains('ceb')) {
      return -47.8919;
    }
    if (lower.contains('energisa') || lower.contains('sergipe') || lower.contains('sul / se')) {
      return -37.0674;
    }
    if (lower.contains('enel') || lower.contains('são paulo') || lower.contains('capital')) {
      return -46.6333;
    }
    if (lower.contains('edp') || lower.contains('vale') || lower.contains('sjc') || lower.contains('jacareí')) {
      return -45.8890;
    }
    if (lower.contains('light') || lower.contains('rio')) {
      return -43.1729;
    }
    if (lower.contains('cemig') || lower.contains('minas') || lower.contains('bh')) {
      return -43.9378;
    }
    if (lower.contains('copel') || lower.contains('paraná') || lower.contains('curitiba')) {
      return -49.2733;
    }
    if (lower.contains('equatorial') || lower.contains('pará') || lower.contains('maranhão')) {
      return -48.4902;
    }
    if (lower.contains('neoenergia') || lower.contains('bahia') || lower.contains('coelba')) {
      return -38.5016;
    }
    return -47.0616;
  }

  String get defaultAddress {
    final lower = '${distribuidora.toLowerCase()} ${(regiao ?? '').toLowerCase()}';
    if (lower.contains('sulgipe')) {
      return 'Estância - SE ($distribuidora)';
    }
    if (lower.contains('brasilia') || lower.contains('brasília') || lower.contains('ceb')) {
      return 'Brasília - DF ($distribuidora)';
    }
    if (lower.contains('energisa') || lower.contains('sergipe') || lower.contains('sul / se')) {
      return 'Aracaju - SE ($distribuidora)';
    }
    if (lower.contains('enel') || lower.contains('são paulo') || lower.contains('capital')) {
      return 'São Paulo - SP ($distribuidora)';
    }
    if (lower.contains('edp') || lower.contains('vale') || lower.contains('sjc') || lower.contains('jacareí')) {
      return 'São José dos Campos - SP ($distribuidora)';
    }
    return '$distribuidora${regiao != null ? " ($regiao)" : ""}';
  }
}

