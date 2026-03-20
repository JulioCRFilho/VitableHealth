import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design/theme/app_theme.dart';
import 'core/routing/app_router.dart';

import 'features/identity/application/auth_notifier.dart';

void main() {
  runApp(const ProviderScope(child: VitableHealthApp()));
}

class VitableHealthApp extends ConsumerWidget {
  const VitableHealthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state to ensure it's initialized from secure storage on startup
    ref.watch(authProvider);

    return MaterialApp.router(
      title: 'Vitable Health',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Dynamically responds to system theme
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
