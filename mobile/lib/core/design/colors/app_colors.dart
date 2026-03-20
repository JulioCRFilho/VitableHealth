import 'package:flutter/material.dart';

class AppColors {
  // Vibrant Teal/Green palette inspired by Vitable Health
  static const Color primary = Color(0xFF0B6358); 
  static const Color secondary = Color(0xFFE2F3F0);
  static const Color accent = Color(0xFFF9A825); // For call to actions
  
  // Light Mode
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  
  // Dark Mode
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // High Contrast
  static const Color primaryHighContrast = Color(0xFF063B35);
  static const Color backgroundHighContrastLight = Colors.white;
  static const Color backgroundHighContrastDark = Colors.black;
  static const Color textPrimaryHighContrastLight = Colors.black;
  static const Color textPrimaryHighContrastDark = Colors.white;
}
