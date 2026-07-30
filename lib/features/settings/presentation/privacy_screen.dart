import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Datenschutz-Einstellungen.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Datenschutz',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              size: 56,
              color: AppColors.turquoise,
            ),
            const SizedBox(height: 20),
            Text(
              'Deine Familie, deine Daten',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Private Familieninhalte werden nur für Mitglieder deiner Familie '
              'sichtbar gemacht. Kinderfotos und persönliche Erinnerungen '
              'bleiben geschützt.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
