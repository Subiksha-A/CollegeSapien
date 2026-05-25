import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Neo-Brutalism Theme Configuration
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Public Sans',
      scaffoldBackgroundColor: AppColors.background,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: 'Lexend Mega',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -3.6,
          color: AppColors.textPrimary,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: AppColors.border, width: 2),
          ),
          shadowColor: AppColors.shadow,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.border, width: 3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Public Sans',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppColors.border, width: 2),
        ),
        shadowColor: AppColors.shadow,
      ),
    );
  }

  // Custom Box Decoration for Neo-Brutalism Cards
  static BoxDecoration cardDecoration({
    Color? color,
    double borderWidth = 2,
    Offset shadowOffset = const Offset(4, 4),
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primaryYellow,
      border: Border.all(color: AppColors.border, width: borderWidth),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          offset: shadowOffset,
          color: AppColors.shadow,
        ),
      ],
    );
  }

  // Button Decoration
  static BoxDecoration buttonDecoration({
    Color? color,
    Offset shadowOffset = const Offset(2, 2),
  }) {
    return BoxDecoration(
      color: color ?? AppColors.primaryYellow,
      border: Border.all(color: AppColors.border, width: 2),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          offset: shadowOffset,
          color: AppColors.shadow,
        ),
      ],
    );
  }

  // Badge Decoration
  static BoxDecoration badgeDecoration({
    Color? color,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      border: Border.all(color: AppColors.border, width: 1),
      borderRadius: BorderRadius.circular(6),
      boxShadow: [
        BoxShadow(
          offset: const Offset(2, 2),
          color: AppColors.shadow,
        ),
      ],
    );
  }
}
