import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';

/// Begrüßung mit Name und Profilbild.
class UserGreeting extends StatelessWidget {
  const UserGreeting({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.profile,
    this.onProfileTap,
  });

  final String greeting;
  final String subtitle;
  final ProfileModel? profile;
  final VoidCallback? onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeDashboardColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: HomeDashboardColors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ProfileAvatar(
          radius: 26,
          avatarPath: profile?.avatarPath,
          firstName: profile?.firstName,
          lastName: profile?.lastName,
          displayName: profile?.displayName,
          onTap: onProfileTap,
        ),
      ],
    );
  }
}
