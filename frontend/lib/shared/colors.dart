import 'package:flutter/material.dart';

abstract class AppColors {
  // Cores principais
  static const Color roxoPrincipal = Color(0xFF6224E3);
  static const Color roxoClaro = Color(0xFF5E22E2);
  static const Color amarelo = Color(0xFFFFCC00);

  // Banner lateral
  static const Color fundoBanner = Color(0xFF1D1335);
  static const Color cardBanner = Color(0xFF281C46);
  static const Color bordaCardBanner = Color(0xFF3B2A63);
  static const Color textoBanner = Color(0xFFA69CBF);

  // Fundo e superficies
  static const Color fundoTela = Color(0xFFF4F6FB);
  static const Color branco = Colors.white;
  static const Color fundoInput = Color(0xFFFCFDFF);
  static const Color fundoAbas = Color(0xFFF1F3F9);

  // Bordas
  static const Color bordaCard = Color(0xFFEAECF0);
  static const Color bordaInput = Color(0xFFE2E8F0);

  // Textos
  static const Color textoTitulo = Color(0xFF111827);
  static const Color textoRotulo = Color(0xFF374151);
  static const Color textoSecundario = Color(0xFF6B7280);
  static const Color textoPlaceholder = Color(0xFF9CA3AF);
  static const Color cinzaAzulado = Color(0xFF64748B);

  // Feedback (alerta de sucesso e erro)
  static const Color vermelhoErro = Color(0xFFEF4444);
  static const Color verdeSucesso = Color(0xFF16A34A);
  static const Color textoSucesso = Color(0xFF166534);
  static const Color fundoSucesso = Color(0xFFE8F8EE);
  static const Color bordaSucesso = Color(0xFFBBE6C5);
}

// Apelido simples em portugues
typedef Cores = AppColors;
