import 'package:flutter/material.dart';

/// Zentrale Farbpalette – Premium Travel Memory Design.
abstract final class AppColors {
  // Hintergründe
  static const backgroundDark = Color(0xFF071624);
  static const background = Color(0xFF0D1B2A);
  static const backgroundSecondary = Color(0xFF102438);
  static const cardBackground = Color(0xFF122A40);
  static const cardElevated = Color(0xFF18354D);

  // Markenfarben
  static const primaryBlue = Color(0xFF2563EB);
  static const turquoise = Color(0xFF14B8A6);
  static const cyan = Color(0xFF11C5C9);
  static const accentOrange = Color(0xFFF59E0B);

  // Text
  static const textPrimary = Color(0xFFF1F5F9);
  static const textSecondary = Color(0xFFA8B6C7);
  static const textMuted = Color(0xFF718096);
  static const divider = Color(0xFF20384D);

  // Status
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);

  // Legacy-Aliase (bestehende Screens)
  static const surface = cardBackground;
  static const card = cardBackground;
  static const accentWarm = accentOrange;
  static const accentCool = turquoise;
  static const primary = turquoise;
  static const accentPink = error;
  static const white = Color(0xFFFFFFFF);
  static const cardLight = Color(0xFFF1F5F9);

  // Light Mode Vorbereitung
  static const lightBackground = Color(0xFFF1F5F9);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0D1B2A);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [turquoise, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBlueGradient = LinearGradient(
    colors: [Color(0xFF102A43), backgroundDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient coverFadeGradient = LinearGradient(
    colors: [Colors.transparent, Color(0xE6071624)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [accentOrange, Color(0xFFE88B3A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coolGradient = brandGradient;
  static const LinearGradient primaryGradient = brandGradient;

  static const LinearGradient ticketCoverGradient = LinearGradient(
    colors: [cardElevated, background],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
