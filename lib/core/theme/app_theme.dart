import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores Base
  static const Color background = Color(0xFF0D0D0D); // Negro Cibernético
  static const Color surface = Color(0xFF1C1C1C); // Gris Oscuro Translúcido
  static const Color primary = Color(0xFFFF2A2A); // Rojo Neón / Láser
  static const Color textMain = Color(0xFFFFFFFF); // Blanco Puro
  static const Color textSecondary = Color(0xFFB3B3B3); // Gris Platino

  // Tema Principal
  static ThemeData get cyberneticPro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        background: background,
        onSurface: textMain,
        onBackground: textMain,
        onPrimary: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge:
            GoogleFonts.orbitron(color: textMain, fontWeight: FontWeight.bold),
        displayMedium:
            GoogleFonts.orbitron(color: textMain, fontWeight: FontWeight.bold),
        displaySmall:
            GoogleFonts.orbitron(color: textMain, fontWeight: FontWeight.bold),
        headlineMedium:
            GoogleFonts.orbitron(color: textMain, fontWeight: FontWeight.bold),
        titleLarge:
            GoogleFonts.orbitron(color: textMain, fontWeight: FontWeight.w600),
        titleMedium:
            GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.inter(
            color: textSecondary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.inter(color: textMain),
        bodyMedium: GoogleFonts.inter(color: textSecondary),
        bodySmall: GoogleFonts.inter(color: textSecondary),
        labelLarge:
            GoogleFonts.orbitron(color: primary, fontWeight: FontWeight.bold),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor:
            Colors.transparent, // Background será dado por un container blur
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.orbitron(
          color: textMain,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
