import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Onboarding: Familie erstellen oder beitreten.
class FamilySetupScreen extends StatelessWidget {
  const FamilySetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Deine Familie',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                size: 80,
                color: AppColors.turquoise,
              ),
              const SizedBox(height: 24),
              Text(
                'Willkommen bei MemoryAi',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Erstelle deine Familie oder tritt mit einem Einladungscode bei.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),
              AppButton(
                label: 'Familie erstellen',
                icon: Icons.add_home_outlined,
                onPressed: () => context.go('/family/create'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/family/join'),
                icon: const Icon(Icons.vpn_key_outlined),
                label: const Text('Mit Einladungscode beitreten'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
