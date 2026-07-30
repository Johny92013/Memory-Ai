import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/features/family/data/family_model.dart';
import 'package:memory_ai/shared/widgets/app_card.dart';

/// Karte für eine Familie in Listen.
class FamilyCard extends StatelessWidget {
  const FamilyCard({
    super.key,
    required this.family,
    this.onTap,
    this.memberCount,
  });

  final FamilyModel family;
  final VoidCallback? onTap;
  final int? memberCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.warmGradient,
            ),
            child: const Icon(Icons.home_outlined, color: AppColors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  family.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  memberCount != null
                      ? '$memberCount Mitglieder · Code ${family.inviteCode}'
                      : 'Code ${family.inviteCode}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (family.description != null &&
                    family.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    family.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
