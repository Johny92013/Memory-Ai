import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Runder Filter-Button für die Karten-Suchleiste.
class TravelMapFilterButton extends StatelessWidget {
  const TravelMapFilterButton({
    super.key,
    required this.onPressed,
    this.hasActiveFilters = false,
  });

  final VoidCallback onPressed;
  final bool hasActiveFilters;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.cardElevated.withValues(alpha: 0.9),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          ),
          child: Badge(
            isLabelVisible: hasActiveFilters,
            backgroundColor: AppColors.turquoise,
            smallSize: 8,
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

/// Schwebende Glas-Suchleiste für die Weltkarte.
class TravelMapSearchBar extends StatelessWidget {
  const TravelMapSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterPressed,
    this.hasActiveFilters = false,
    this.hintText = 'Suche nach Orten, Tagen oder Reisen',
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterPressed;
  final bool hasActiveFilters;
  final String hintText;

  static const _radius = 22.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.backgroundDark.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardElevated.withValues(alpha: 0.85),
                    border: Border.all(
                      color: AppColors.divider.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    isDense: true,
                  ),
                ),
              ),
              if (onFilterPressed != null)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TravelMapFilterButton(
                    onPressed: onFilterPressed!,
                    hasActiveFilters: hasActiveFilters,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
