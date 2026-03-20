import 'package:flutter/material.dart';
import '../colors/app_colors.dart';
import '../typography/app_typography.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
        error: Colors.redAccent,
      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: AppTypography.heading1Style,
        headlineMedium: AppTypography.heading2Style,
        titleLarge: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 20, fontWeight: FontWeight.bold),
        bodyLarge: AppTypography.bodyLargeStyle,
        bodyMedium: AppTypography.bodyMediumStyle,
        bodySmall: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, fontWeight: FontWeight.normal),
        labelMedium: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 13, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.secondary, 
        secondary: AppColors.primary,
        surface: AppColors.surfaceDark,
        error: Colors.redAccent,
      ),
      useMaterial3: true,
      textTheme: const TextTheme(
        headlineLarge: AppTypography.heading1Style,
        headlineMedium: AppTypography.heading2Style,
        titleLarge: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 20, fontWeight: FontWeight.bold),
        bodyLarge: AppTypography.bodyLargeStyle,
        bodyMedium: AppTypography.bodyMediumStyle,
        bodySmall: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 12, fontWeight: FontWeight.normal),
        labelMedium: TextStyle(fontFamily: AppTypography.fontFamily, fontSize: 13, fontWeight: FontWeight.w600),
      ).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.textPrimaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        ),
      ),
    );
  }

  static ThemeData get highContrastLightTheme {
    return lightTheme.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundHighContrastLight,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryHighContrast,
        secondary: AppColors.primaryHighContrast,
        surface: AppColors.backgroundHighContrastLight,
        error: Colors.redAccent,
      ),
      textTheme: lightTheme.textTheme.apply(
        bodyColor: AppColors.textPrimaryHighContrastLight,
        displayColor: AppColors.textPrimaryHighContrastLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundHighContrastLight,
        foregroundColor: AppColors.textPrimaryHighContrastLight,
        elevation: 1, // Added elevation for better separation
        centerTitle: true,
      ),
    );
  }

  static ThemeData get highContrastDarkTheme {
    return darkTheme.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundHighContrastDark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.textPrimaryHighContrastDark,
        secondary: AppColors.textPrimaryHighContrastDark,
        surface: AppColors.backgroundHighContrastDark,
        error: Colors.redAccent,
      ),
      textTheme: darkTheme.textTheme.apply(
        bodyColor: AppColors.textPrimaryHighContrastDark,
        displayColor: AppColors.textPrimaryHighContrastDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundHighContrastDark,
        foregroundColor: AppColors.textPrimaryHighContrastDark,
        elevation: 1, // Added elevation for better separation
        centerTitle: true,
      ),
    );
  }
}
