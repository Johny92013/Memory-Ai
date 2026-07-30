import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';

/// Übersicht der Chat-Räume (Phase 6).
class ChatOverviewScreen extends StatelessWidget {
  const ChatOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Familien-Chat – kommt in Phase 6.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const Expanded(
              child: EmptyState(
                icon: Icons.chat_bubble_outline,
                title: 'Noch keine Unterhaltungen',
                subtitle: 'Hier kannst du bald mit deiner Familie schreiben.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
