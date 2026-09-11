import 'package:flutter/material.dart';

abstract class AppColors {
  // Cores principais
  static const Color primary = Color(0xFF6224E3);          // Roxo principal
  static const Color primaryLight = Color(0xFF5E22E2);     // Roxo claro
  static const Color accentYellow = Color(0xFFFFCC00);     // Amarelo

  // Banner lateral
  static const Color bannerBackground = Color(0xFF1D1335); // Roxo escuro
  static const Color bannerCard = Color(0xFF281C46);       // Roxo escuro
  static const Color bannerCardBorder = Color(0xFF3B2A63); // Roxo acinzentado
  static const Color bannerTextMuted = Color(0xFFA69CBF);  // Lilas claro

  // Fundo e superficies
  static const Color background = Color(0xFFF4F6FB);         // Cinza azulado bem claro
  static const Color surface = Colors.white;                 // Branco
  static const Color inputBackground = Color(0xFFFCFDFF);    // Branco gelo
  static const Color tabBackground = Color(0xFFF1F3F9);      // Cinza bem claro

  // Bordas
  static const Color borderLight = Color(0xFFEAECF0);        // Cinza claro
  static const Color inputBorder = Color(0xFFE2E8F0);        // Cinza suave

  // Textos
  static const Color textPrimary = Color(0xFF111827);        // Cinza quase preto (titulos)
  static const Color textSecondary = Color(0xFF374151);      // Cinza chumbo (labels)
  static const Color textMuted = Color(0xFF6B7280);          // Cinza medio
  static const Color textPlaceholder = Color(0xFF9CA3AF);    // Cinza claro
  static const Color textSlate = Color(0xFF64748B);          // Cinza azulado

  // Feedback (alerta de sucesso e erro)
  static const Color error = Color(0xFFEF4444);            // Vermelho
  static const Color success = Color(0xFF16A34A);          // Verde
  static const Color successDark = Color(0xFF166534);      // Verde escuro
  static const Color successLight = Color(0xFFE8F8EE);     // Verde claro
  static const Color successBorder = Color(0xFFBBE6C5);    // Verde suave
}
