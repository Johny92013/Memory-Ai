import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memory_ai/app/app_colors.dart';

/// ThemeExtension für Stats-Mono und Akzentfarben.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.statsMono,
    required this.accentWarm,
    required this.accentCool,
  });

  final TextStyle statsMono;
  final Color accentWarm;
  final Color accentCool;

  static AppThemeExtension light = AppThemeExtension(
    statsMono: GoogleFonts.jetBrainsMono(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    accentWarm: AppColors.accentWarm,
    accentCool: AppColors.accentCool,
  );

  @override
  AppThemeExtension copyWith({
    TextStyle? statsMono,
    Color? accentWarm,
    Color? accentCool,
  }) {
    return AppThemeExtension(
      statsMono: statsMono ?? this.statsMono,
      accentWarm: accentWarm ?? this.accentWarm,
      accentCool: accentCool ?? this.accentCool,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      statsMono: TextStyle.lerp(statsMono, other.statsMono, t)!,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t)!,
      accentCool: Color.lerp(accentCool, other.accentCool, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>() ?? AppThemeExtension.light;
}
