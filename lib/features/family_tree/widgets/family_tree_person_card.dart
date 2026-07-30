import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/utils/initials_helper.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';

/// Personenkarte im Stammbaum-Canvas.
class FamilyTreePersonCard extends StatelessWidget {
  const FamilyTreePersonCard({
    super.key,
    required this.person,
    this.onTap,
    this.width = 160,
  });

  final FamilyTreePersonModel person;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsHelper.fromNames(
      person.firstName,
      person.lastName,
    );

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.textSecondary.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                person.displayName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (person.birthDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${person.birthDate!.year}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
