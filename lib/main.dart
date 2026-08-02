import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memory_ai/app/app.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/config/supabase_config.dart';
import 'package:memory_ai/core/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
    await SupabaseConfig.initialize();
    await ThemeController.instance.load();
    runApp(const FamilyMemoriesApp());
  } catch (error, stackTrace) {
    FlutterError.dumpErrorToConsole(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
    runApp(ErrorApp(message: error.toString()));
  }
}

/// Fallback-UI, wenn die App-Initialisierung fehlschlägt.
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 56,
                  color: AppColors.accentPink,
                ),
                const SizedBox(height: 20),
                const Text(
                  'App konnte nicht gestartet werden',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
