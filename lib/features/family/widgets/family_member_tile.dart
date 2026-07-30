import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';

/// Listeneintrag für ein Familienmitglied.
class FamilyMemberTile extends StatelessWidget {
  const FamilyMemberTile({
    super.key,
    required this.member,
    this.onTap,
    this.trailing,
  });

  final FamilyMemberModel member;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: ProfileAvatar(
        avatarPath: member.avatarPath,
        firstName: member.firstName,
        lastName: member.lastName,
        displayName: member.displayName,
        radius: 24,
      ),
      title: Text(member.displayName),
      subtitle: Text(
        member.email ?? member.role.labelDe,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing:
          trailing ??
          Chip(
            label: Text(member.role.labelDe),
            backgroundColor: member.isAdminOrOwner
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.card,
            side: BorderSide.none,
            labelStyle: TextStyle(
              color: member.isAdminOrOwner
                  ? AppColors.turquoise
                  : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
    );
  }
}
