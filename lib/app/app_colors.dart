import 'package:flutter/material.dart';

/// Zentrale Farbpalette – Reise & Erinnerungen (dunkel, warm + kühl).
abstract final class AppColors {
  // Kernpalette
  static const background = Color(0xFF141B2E);
  static const surface = Color(0xFF1F2A47);
  static const accentWarm = Color(0xFFF2A34C);
  static const accentCool = Color(0xFF3DDBC4);
  static const textPrimary = Color(0xFFEDEFF5);
  static const textSecondary = Color(0xFF9AA5C0);
  static const error = Color(0xFFE85D6C);

  // Semantische Aliase (Legacy + Theme)
  static const card = surface;
  static const backgroundSecondary = Color(0xFF182238);
  static const primary = accentWarm;
  static const turquoise = accentCool;
  static const accentOrange = accentWarm;
  static const accentPink = error;
  static const white = textPrimary;
  static const cardLight = Color(0xFFF7F8FC);

  static const LinearGradient warmGradient = LinearGradient(
    colors: [accentWarm, Color(0xFFE88B3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolGradient = LinearGradient(
    colors: [accentCool, Color(0xFF2BB8A8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = warmGradient;

  static const LinearGradient ticketCoverGradient = LinearGradient(
    colors: [Color(0xFF1F2A47), Color(0xFF2A3A5C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
