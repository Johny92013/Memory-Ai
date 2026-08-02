import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';

/// Aktive Filter als einzeln entfernbare Chips.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final MapFilterState filter;
  final ValueChanged<MapFilterState> onChanged;

  @override
  Widget build(BuildContext context) {
    final chips = filter.toChips();
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          ...chips.map(
            (c) => InputChip(
              label: Text(
                c.label,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              backgroundColor: AppColors.turquoise.withValues(alpha: 0.18),
              onDeleted: () => onChanged(filter.removeChip(c.id)),
              deleteIconColor: AppColors.turquoise,
              side: BorderSide(
                color: AppColors.turquoise.withValues(alpha: 0.45),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
          ),
          ActionChip(
            label: const Text('Alle Filter löschen'),
            onPressed: () => onChanged(const MapFilterState()),
            avatar: const Icon(Icons.clear_all, size: 16),
            backgroundColor: AppColors.cardElevated,
            side: BorderSide(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
