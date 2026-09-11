import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

export '../core/constants/app_colors.dart';

abstract class AppColorsLegacy {
  static const Color roxoPrincipal = AppColors.primaryPurple;
  static const Color roxoClaro = AppColors.primaryPurple;
  static const Color amarelo = AppColors.iconGold;
  static const Color fundoBanner = AppColors.darkPurple;
  static const Color cardBanner = AppColors.cardPurple;
  static const Color bordaCardBanner = AppColors.borderPurple;
  static const Color textoBanner = AppColors.textLilac;
  static const Color fundoTela = AppColors.backgroundLight;
  static const Color branco = AppColors.surfaceWhite;
  static const Color fundoInput = AppColors.inputBackground;
  static const Color fundoAbas = AppColors.pillBackground;
  static const Color bordaCard = AppColors.inputBorder;
  static const Color bordaInput = AppColors.inputBorder;
  static const Color textoTitulo = AppColors.textDark;
  static const Color textoRotulo = AppColors.textDark;
  static const Color textoSecundario = AppColors.textMuted;
  static const Color textoPlaceholder = AppColors.textLight;
  static const Color cinzaAzulado = AppColors.textGray;
  static const Color vermelhoErro = AppColors.errorRed;
  static const Color verdeSucesso = AppColors.successGreen;
  static const Color textoSucesso = AppColors.successText;
  static const Color fundoSucesso = AppColors.successBackground;
  static const Color bordaSucesso = AppColors.successBorder;
}

typedef Cores = AppColorsLegacy;
