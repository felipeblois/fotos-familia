import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design system do app Neviim.
///
/// Paleta: preto suave + vermelho Neviim.
/// Tipografia: Outfit (moderna, legível, premium)
/// Suporte a tema claro e escuro.
class AppTheme {
  AppTheme._();

  // ---------------------------------------------------------------------------
  // Paleta de cores
  // ---------------------------------------------------------------------------

  // Vermelho Neviim — cor primaria
  static const _primaryLight = Color(0xFFE52B2F);
  static const _primaryDark = Color(0xFFFF3434);

  // Dourado — acento secundario
  static const _gold = Color(0xFFC9973A);
  static const _goldLight = Color(0xFFE5B96A);

  // Backgrounds
  static const _bgLight = Color(0xFFFAF7F5);
  static const _bgDark = Color(0xFF070809);

  // Surfaces
  static const _surfaceLight = Color(0xFFFFFFFF);
  static const _surfaceDark = Color(0xFF171719);

  // Texto
  static const _onPrimaryLight = Color(0xFFFFFFFF);
  static const _onPrimaryDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Tema Claro
  // ---------------------------------------------------------------------------
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryLight,
          brightness: Brightness.light,
          primary: _primaryLight,
          secondary: _gold,
          surface: _surfaceLight,
          onPrimary: _onPrimaryLight,
        ),
        textTheme: _buildTextTheme(Brightness.light),
        appBarTheme: AppBarTheme(
          backgroundColor: _primaryLight,
          foregroundColor: _onPrimaryLight,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: _onPrimaryLight,
          ),
        ),
        scaffoldBackgroundColor: _bgLight,
        cardTheme: CardTheme(
          color: _surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryLight,
            foregroundColor: _onPrimaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryLight,
            side: const BorderSide(color: _primaryLight, width: 1.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Tema Escuro
  // ---------------------------------------------------------------------------
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _primaryDark,
          brightness: Brightness.dark,
          primary: _primaryDark,
          secondary: _goldLight,
          surface: _surfaceDark,
          onPrimary: _onPrimaryDark,
        ),
        textTheme: _buildTextTheme(Brightness.dark),
        appBarTheme: AppBarTheme(
          backgroundColor: _bgDark,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        scaffoldBackgroundColor: _bgDark,
        cardTheme: CardTheme(
          color: _surfaceDark,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryDark,
            foregroundColor: _onPrimaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: _primaryDark,
            side: const BorderSide(color: _primaryDark, width: 1.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: _primaryDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // Tipografia: Outfit (Google Fonts)
  // ---------------------------------------------------------------------------
  static TextTheme _buildTextTheme(Brightness brightness) {
    final baseColor = brightness == Brightness.light
        ? const Color(0xFF1C1B1F)
        : const Color(0xFFE6E1E5);

    return GoogleFonts.outfitTextTheme(
      TextTheme(
        displayLarge: TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: baseColor,
        ),
        displayMedium: TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: baseColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: baseColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: baseColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: baseColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: baseColor,
        ),
      ),
    );
  }

  static TextStyle brandStyle({
    required Color color,
    double? fontSize,
    FontWeight fontWeight = FontWeight.w800,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.montserrat(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ---------------------------------------------------------------------------
  // Constantes de espaçamento e bordas
  // ---------------------------------------------------------------------------
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  static const EdgeInsets paddingPage = EdgeInsets.all(16.0);
  static const EdgeInsets paddingSm = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMd = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLg = EdgeInsets.all(24.0);

  // Cor dourada (acesso direto para widgets que precisam)
  static const Color gold = _gold;
  static const Color goldLight = _goldLight;
  static const Color primaryDark = _bgDark;
}
