import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_router.dart';
import 'package:memory_ai/app/app_theme.dart';
import 'package:memory_ai/core/constants/app_constants.dart';

/// Root-Widget der Family Memories AI App.
class FamilyMemoriesApp extends StatelessWidget {
  const FamilyMemoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
