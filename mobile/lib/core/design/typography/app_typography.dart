import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Inter'; // Defaulting to an elegant sans-serif

  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0,
  );
  
  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.normal,
  );
}
