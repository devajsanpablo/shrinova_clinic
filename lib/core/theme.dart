import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const body = 'Inter';
  static const heading = 'Manrope';
}

abstract final class AppColors {
  static const primary = Color(0xFF3265D8);
  static const primaryDark = Color(0xFF123F9B);
  static const teal = Color(0xFF0F9F91);
  static const canvas = Color(0xFFF5F7FA);
  static const ink = Color(0xFF172033);
  static const muted = Color(0xFF667085);
  static const border = Color(0xFFE4E8F0);
  static const success = Color(0xFF178A49);
  static const warning = Color(0xFFE5890A);
  static const danger = Color(0xFFC93636);
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: Colors.white,
      error: AppColors.danger,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      fontFamily: AppTypography.body,
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: AppTypography.heading),
        displayMedium: TextStyle(fontFamily: AppTypography.heading),
        displaySmall: TextStyle(fontFamily: AppTypography.heading),
        headlineSmall: TextStyle(fontFamily: AppTypography.heading),
        headlineLarge: TextStyle(
          fontFamily: AppTypography.heading,
          fontSize: 30,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.7,
        ),
        headlineMedium: TextStyle(
          fontFamily: AppTypography.heading,
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontFamily: AppTypography.heading,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: TextStyle(
          fontFamily: AppTypography.heading,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        bodyLarge: TextStyle(fontSize: 15, color: AppColors.ink, height: 1.45),
        bodyMedium: TextStyle(
          fontSize: 13.5,
          color: AppColors.muted,
          height: 1.4,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: const TextStyle(
          fontFamily: AppTypography.heading,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 450),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: const Color(0xFFEAF0FD),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? Colors.white
              : const Color(0xFFF8FAFC),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        hintStyle: const TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
        hintFadeDuration: const Duration(milliseconds: 120),
        // Units must stay visible even while the placeholder is hidden.
        prefixStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        suffixStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        labelStyle: const TextStyle(
          fontFamily: AppTypography.body,
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: AppColors.muted,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: AppTypography.body,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
          textStyle: const TextStyle(
            fontFamily: AppTypography.body,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerColor: AppColors.border,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: Color(0xFFE8F0FF),
        height: 68,
      ),
    );
  }
}
