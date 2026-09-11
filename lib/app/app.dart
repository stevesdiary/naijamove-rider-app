import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

class NaijaMoveApp extends ConsumerWidget {
  const NaijaMoveApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(sessionProvider.select((s) => s.themeMode));
    return MaterialApp.router(
      title: 'NaijaMove',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: appRouter,
      builder: (context, child) {
        // Keep status bar icons legible against light/dark scaffolds.
        final dark = Theme.of(context).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        );
        return child!;
      },
    );
  }
}
