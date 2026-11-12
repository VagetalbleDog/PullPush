import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF6F6F0);
  static const paper = Color(0xFFFFFEFA);
  static const ink = Color(0xFF243D32);
  static const forest = Color(0xFF284D3B);
  static const muted = Color(0xFF858B80);
  static const line = Color(0xFFE6E8DD);
  static const lime = Color(0xFFD7EB93);
  static const pale = Color(0xFFEEF2E7);
  static const danger = Color(0xFFAD5045);
}

TextStyle numberStyle(double size, {Color? color, FontWeight? weight}) {
  return TextStyle(
    fontFamily: 'Manrope',
    fontSize: size,
    fontWeight: weight ?? FontWeight.w600,
    color: color ?? AppColors.ink,
    letterSpacing: -size * .035,
    height: 1.15,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.forest,
    primary: AppColors.forest,
    surface: AppColors.paper,
    error: AppColors.danger,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'NotoSansSC',
    textTheme: const TextTheme(
      bodyMedium: TextStyle(fontSize: 13, height: 1.65, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 11, height: 1.6, color: AppColors.muted),
      titleMedium: TextStyle(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    ),
    dividerColor: AppColors.line,
    splashFactory: InkSparkle.splashFactory,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 11,
        color: Colors.white,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: const TextStyle(
          fontFamily: 'NotoSansSC',
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        minimumSize: const Size(44, 46),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8F9F3),
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
      labelStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.forest,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentTextStyle: const TextStyle(
        fontFamily: 'NotoSansSC',
        fontSize: 13,
        color: Colors.white,
      ),
    ),
  );
}
