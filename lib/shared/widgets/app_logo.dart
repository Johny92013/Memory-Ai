import 'package:flutter/material.dart';

/// App-Logo aus `assets/logos/logo.png`.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96, this.showShadow = true});

  /// Breite und Höhe des Logos.
  final double size;

  /// Leichter Schatten unter dem Logo.
  final bool showShadow;

  static const assetPath = 'assets/logos/logo.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showShadow
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                ),
              ],
            )
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
