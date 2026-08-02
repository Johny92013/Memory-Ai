import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Dashboard-Farben – an Travel-Dark-Theme angeglichen.
abstract final class HomeDashboardColors {
  static const header = AppColors.background;
  static const pageBackground = AppColors.backgroundDark;
  static const primaryText = AppColors.textPrimary;
  static const secondaryText = AppColors.textSecondary;
  static const white = AppColors.white;

  static const blue = AppColors.primaryBlue;
  static const blueSoft = Color(0xFF1A3350);
  static const green = AppColors.turquoise;
  static const greenSoft = Color(0xFF143A3A);
  static const violet = Color(0xFF8B5CF6);
  static const violetSoft = Color(0xFF2A1F4D);
  static const coral = AppColors.accentOrange;
  static const coralSoft = Color(0xFF3A2A14);
  static const navActive = AppColors.turquoise;
  static const navInactive = AppColors.textMuted;
  static const plusButton = AppColors.turquoise;
  static const link = AppColors.cyan;

  static const cardShadow = Color(0x40000000);
}
