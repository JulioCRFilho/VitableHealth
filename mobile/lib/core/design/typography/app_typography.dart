import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Inter'; 

  // Direct styles for backward compatibility or specialized use
  static const TextStyle heading1Style = TextStyle(
    fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1.0,
  );
  
  static const TextStyle heading2Style = TextStyle(
    fontFamily: fontFamily, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5,
  );
  
  static const TextStyle bodyLargeStyle = TextStyle(
    fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMediumStyle = TextStyle(
    fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.normal,
  );

  // Responsive getters using context
  static TextStyle headlineLarge(BuildContext context) => Theme.of(context).textTheme.headlineLarge!;
  static TextStyle headlineMedium(BuildContext context) => Theme.of(context).textTheme.headlineMedium!;
  static TextStyle titleLarge(BuildContext context) => Theme.of(context).textTheme.titleLarge!;
  static TextStyle bodyLarge(BuildContext context) => Theme.of(context).textTheme.bodyLarge!;
  static TextStyle bodyMedium(BuildContext context) => Theme.of(context).textTheme.bodyMedium!;
  static TextStyle bodySmall(BuildContext context) => Theme.of(context).textTheme.bodySmall!;
  static TextStyle labelMedium(BuildContext context) => Theme.of(context).textTheme.labelMedium!;
}
