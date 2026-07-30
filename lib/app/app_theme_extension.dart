import 'package:flutter/material.dart';

/// Design-Tokens als ThemeExtension (kein Konflikt mit Material Theme).
class AppThemeTokens extends ThemeExtension<AppThemeTokens> {
  const AppThemeTokens({
    required this.mono,
    required this.display,
    required this.accentWarm,
    required this.accentCool,
    required this.radiusChip,
    required this.radiusCard,
    required this.radiusPhoto,
  });

  final TextStyle mono;
  final TextStyle display;
  final Color accentWarm;
  final Color accentCool;
  final double radiusChip;
  final double radiusCard;
  final double radiusPhoto;

  @override
  AppThemeTokens copyWith({
    TextStyle? mono,
    TextStyle? display,
    Color? accentWarm,
    Color? accentCool,
    double? radiusChip,
    double? radiusCard,
    double? radiusPhoto,
  }) {
    return AppThemeTokens(
      mono: mono ?? this.mono,
      display: display ?? this.display,
      accentWarm: accentWarm ?? this.accentWarm,
      accentCool: accentCool ?? this.accentCool,
      radiusChip: radiusChip ?? this.radiusChip,
      radiusCard: radiusCard ?? this.radiusCard,
      radiusPhoto: radiusPhoto ?? this.radiusPhoto,
    );
  }

  @override
  AppThemeTokens lerp(ThemeExtension<AppThemeTokens>? other, double t) {
    if (other is! AppThemeTokens) return this;
    return AppThemeTokens(
      mono: TextStyle.lerp(mono, other.mono, t) ?? mono,
      display: TextStyle.lerp(display, other.display, t) ?? display,
      accentWarm: Color.lerp(accentWarm, other.accentWarm, t) ?? accentWarm,
      accentCool: Color.lerp(accentCool, other.accentCool, t) ?? accentCool,
      radiusChip: radiusChip,
      radiusCard: radiusCard,
      radiusPhoto: radiusPhoto,
    );
  }

  static AppThemeTokens of(BuildContext context) {
    return Theme.of(context).extension<AppThemeTokens>()!;
  }
}
