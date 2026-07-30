import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Kontoeinstellungen.
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await SupabaseService.client.auth.signOut();
    if (context.mounted) context.go('/welcome');
  }

  @override
  Widget build(BuildContext context) {
    final email = SupabaseService.client.auth.currentUser?.email;

    return AppScaffold(
      title: 'Konto',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: AppColors.card,
              leading: const Icon(Icons.email_outlined),
              title: const Text('E-Mail'),
              subtitle: Text(email ?? 'Nicht verfügbar'),
            ),
            const Spacer(),
            AppButton(
              label: 'Abmelden',
              icon: Icons.logout,
              onPressed: () => _signOut(context),
            ),
          ],
        ),
      ),
    );
  }
}
