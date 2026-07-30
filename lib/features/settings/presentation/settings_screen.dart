import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/auth/app_role.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// App-Einstellungen.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Einstellungen',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (AppRole.isAppAdmin(SupabaseService.client.auth.currentUser)) ...[
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              tileColor: AppColors.card,
              leading: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.accentOrange,
              ),
              title: const Text('Admin-Verwaltung'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/admin'),
            ),
            const SizedBox(height: 12),
          ],
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppColors.card,
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Datenschutz'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/privacy'),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppColors.card,
            leading: const Icon(Icons.manage_accounts_outlined),
            title: const Text('Konto'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account'),
          ),
        ],
      ),
    );
  }
}
