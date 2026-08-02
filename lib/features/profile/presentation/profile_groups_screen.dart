import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Hub für Verbindungen, Familie und Nachrichten (aus Profil).
class ProfileGroupsScreen extends StatelessWidget {
  const ProfileGroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Verbindungen und Familie',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppColors.card,
            leading: const Icon(Icons.family_restroom),
            title: const Text('Familie'),
            subtitle: const Text('Familienübersicht, Stammbaum, Einladungen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/family'),
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            tileColor: AppColors.card,
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text('Familienchat'),
            subtitle: const Text('Textnachrichten in Echtzeit'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/chat'),
          ),
        ],
      ),
    );
  }
}
