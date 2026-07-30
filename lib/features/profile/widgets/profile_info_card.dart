import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';
import 'package:memory_ai/shared/widgets/app_card.dart';

/// Übersichtskarte mit Avatar und Profildaten.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({super.key, required this.profile, this.onEdit});

  final ProfileModel profile;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          ProfileAvatar(
            avatarPath: profile.avatarPath,
            firstName: profile.firstName,
            lastName: profile.lastName,
            displayName: profile.displayName,
            radius: 44,
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          if (profile.username != null && profile.username!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '@${profile.username}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
          if (profile.email != null) ...[
            const SizedBox(height: 4),
            Text(
              profile.email!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (profile.birthDate != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cake_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.day(profile.birthDate),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          if (onEdit != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Profil bearbeiten'),
            ),
          ],
        ],
      ),
    );
  }
}
