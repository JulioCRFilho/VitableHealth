import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/theme/app_theme.dart';
import 'core/routing/app_router.dart';

import 'core/design/typography/text_scale_provider.dart';
import 'core/design/theme/high_contrast_provider.dart';

void main() {
  runApp(const ProviderScope(child: VitableHealthApp()));
}

class VitableHealthApp extends ConsumerWidget {
  const VitableHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the custom text scale factor
    final textScaleFactor = ref.watch(textScaleProvider);
    
    // Watch high contrast manual override
    final isHighContrast = ref.watch(highContrastProvider);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: MaterialApp.router(
        title: 'Vitable Health',
        theme: isHighContrast ? AppTheme.highContrastLightTheme : AppTheme.lightTheme,
        darkTheme: isHighContrast ? AppTheme.highContrastDarkTheme : AppTheme.darkTheme,
        highContrastTheme: AppTheme.highContrastLightTheme,
        highContrastDarkTheme: AppTheme.highContrastDarkTheme,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
