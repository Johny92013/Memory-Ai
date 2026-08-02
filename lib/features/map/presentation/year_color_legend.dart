import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';

/// Ein-/ausklappbare Jahresfarben-Legende.
class YearColorLegend extends StatefulWidget {
  const YearColorLegend({super.key, required this.years});

  final List<int> years;

  @override
  State<YearColorLegend> createState() => _YearColorLegendState();
}

class _YearColorLegendState extends State<YearColorLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.years.isEmpty) return const SizedBox.shrink();
    return Material(
      color: AppColors.cardBackground.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Jahre',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: AppSpacing.xs),
                ...widget.years.map((y) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: YearColorPalette.forYear(y),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$y',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ] else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.years.take(5).map((y) {
                    return Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(right: 4, top: 4),
                      decoration: BoxDecoration(
                        color: YearColorPalette.forYear(y),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
