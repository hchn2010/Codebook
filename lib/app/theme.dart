import 'package:flutter/material.dart';

abstract final class CodebookColors {
  static const background = Color(0xFF050914);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF172033);
  static const primary = Color(0xFF6674FF);
  static const primary2 = Color(0xFF4158D8);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF9AA6BD);
  static const success = Color(0xFF5CE1A5);
  static const danger = Color(0xFFFF626B);
}

ThemeData buildCodebookTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CodebookColors.primary,
    brightness: Brightness.dark,
    surface: CodebookColors.surface,
  );

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: CodebookColors.background,
    fontFamilyFallback: const ['Noto Sans CJK SC', 'Microsoft YaHei', 'sans-serif'],
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: CodebookColors.text),
      headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: CodebookColors.text),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CodebookColors.text),
      bodyLarge: TextStyle(fontSize: 16, color: CodebookColors.text),
      bodyMedium: TextStyle(fontSize: 14, color: CodebookColors.muted),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: CodebookColors.surface.withValues(alpha: .82),
      hintStyle: const TextStyle(color: CodebookColors.muted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: CodebookColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0B1120).withValues(alpha: .96),
      indicatorColor: CodebookColors.primary.withValues(alpha: .18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        color: states.contains(WidgetState.selected) ? CodebookColors.primary : CodebookColors.muted,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
      )),
    ),
  );
}
