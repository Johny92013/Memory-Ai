import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_router.dart';
import 'package:memory_ai/app/app_theme.dart';
import 'package:memory_ai/core/constants/app_constants.dart';
import 'package:memory_ai/core/services/theme_controller.dart';

/// Root-Widget der Memory-AI App.
class FamilyMemoriesApp extends StatelessWidget {
  const FamilyMemoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeController.instance.mode,
          routerConfig: appRouter,
        );
      },
    );
  }
}
