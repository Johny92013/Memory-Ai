import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/app_card.dart';

/// Zeigt den Einladungscode mit Kopierfunktion.
class InvitationCodeCard extends StatelessWidget {
  const InvitationCodeCard({
    super.key,
    required this.inviteCode,
    this.title = 'Einladungscode',
    this.subtitle =
        'Teile diesen Code mit Familienmitgliedern, damit sie beitreten können.',
  });

  final String inviteCode;
  final String title;
  final String subtitle;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: inviteCode));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Einladungscode kopiert')));
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    inviteCode,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 2,
                      color: AppColors.turquoise,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Kopieren',
                  onPressed: () => _copy(context),
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
