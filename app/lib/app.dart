import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/strings/flavor_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

class ChoreBuddyApp extends ConsumerWidget {
  const ChoreBuddyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    final strings = ref.watch(appStringsProvider);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return MaterialApp.router(
          title: strings.appTitle,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.buildLightTheme(
            themeId: themeState.themeId,
            lightDynamicScheme: lightDynamic,
          ),
          darkTheme: AppTheme.buildDarkTheme(
            themeId: themeState.themeId,
            darkDynamicScheme: darkDynamic,
          ),
          themeMode: themeState.themeMode,
          routerConfig: router,
        );
      },
    );
  }
}
