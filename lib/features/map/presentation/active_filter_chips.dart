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
              label: Text(c.label),
              onDeleted: () => onChanged(filter.removeChip(c.id)),
              deleteIconColor: AppColors.textSecondary,
              side: BorderSide(
                color: AppColors.accentWarm.withValues(alpha: 0.4),
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
          ),
        ],
      ),
    );
  }
}
