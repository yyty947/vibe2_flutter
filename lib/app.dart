import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/game_screen.dart';
import 'theme/app_theme.dart';
import 'state/theme_provider.dart';

class FrontendSurvivalApp extends ConsumerWidget {
  const FrontendSurvivalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: '前端生死劫 | Frontend Survival',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark, // base theme; dynamic portions overridden below
      builder: (context, child) {
        return AnimatedTheme(
          data: theme.themeData,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          child: DefaultTextStyle.merge(
            style: const TextStyle(decoration: TextDecoration.none),
            child: child!,
          ),
        );
      },
      home: const GameScreen(),
    );
  }
}
