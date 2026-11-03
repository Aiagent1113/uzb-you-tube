import 'dart:ui';
import 'package:flutter/material.dart';

/// UzDub Luxury Design System & App Theme
/// Combines deep Obsidian black with Neon YouTube red, delicate frosted glass (Glassmorphism),
/// and high-contrast typography.
class AppTheme {
  // Brand Color Palette
  static const Color obsidianBlack = Color(0xFF0A0A0A);
  static const Color surfaceBlack = Color(0xFF141416);
  static const Color cardBlack = Color(0xFF1A1A1E);
  static const Color neonRed = Color(0xFFFF0033);
  static const Color accentRose = Color(0xFFFF2A55);
  static const Color deepCrimson = Color(0xFF99001F);
  
  // Neutral Tones
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9EA7);
  static const Color borderFrosted = Color(0x1FFFFFFF);
  static const Color borderGlowing = Color(0x4DFF0033);

  // Gradients
  static const LinearGradient luxuryRedGradient = LinearGradient(
    colors: [neonRed, accentRose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proBadgeGradient = LinearGradient(
    colors: [Color(0xFFFF0033), Color(0xFFFF7A00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [
      Color(0xCC18181C),
      Color(0x80101014),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Luxury Glassmorphic Container Decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 20.0,
    bool hasGlow = false,
    Color? borderColor,
  }) {
    return BoxDecoration(
      gradient: glassCardGradient,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? (hasGlow ? borderGlowing : borderFrosted),
        width: hasGlow ? 1.5 : 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
        if (hasGlow)
          BoxShadow(
            color: neonRed.withOpacity(0.25),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
      ],
    );
  }

  // Material Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidianBlack,
      primaryColor: neonRed,
      colorScheme: const ColorScheme.dark(
        primary: neonRed,
        secondary: accentRose,
        surface: surfaceBlack,
        background: obsidianBlack,
        onPrimary: textWhite,
        onSurface: textWhite,
      ),
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: textWhite,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        titleMedium: TextStyle(
          color: textWhite,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(
          color: textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          color: textWhite,
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: neonRed,
          foregroundColor: textWhite,
          elevation: 8,
          shadowColor: neonRed.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
