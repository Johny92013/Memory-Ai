import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';

/// Hilfsmethoden für Bestätigungsdialoge.
class AppDialog {
  AppDialog._();

  /// Zeigt einen Bestätigungsdialog. Gibt `true` bei Bestätigung zurück.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Bestätigen',
    String cancelLabel = 'Abbrechen',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.card + 2),
          ),
          title: Text(title),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.accentPink,
                    )
                  : null,
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
