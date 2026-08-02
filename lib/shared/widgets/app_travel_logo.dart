import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Memory-AI Travel-Logo: Pin + Weltkugel + Flugzeug (vektorisch, austauschbar).
class AppTravelLogo extends StatelessWidget {
  const AppTravelLogo({
    super.key,
    this.size = 56,
    this.showWordmark = false,
    this.subtitle,
  });

  final double size;
  final bool showWordmark;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: AppColors.brandGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.35),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: CustomPaint(painter: _TravelLogoPainter()),
    );

    if (!showWordmark) return icon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: size * 0.22),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MemoryAiWordmark(),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: size * 0.18,
                    height: 1.25,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class MemoryAiWordmark extends StatelessWidget {
  const MemoryAiWordmark({super.key, this.fontSize = 20});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Memory-AI',
      style: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    );
  }
}

class GradientIconContainer extends StatelessWidget {
  const GradientIconContainer({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: AppColors.white, size: iconSize),
    );
  }
}

class _TravelLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final white = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    // Orbit
    final orbit = Rect.fromCenter(
      center: Offset(w * 0.5, h * 0.42),
      width: w * 0.62,
      height: h * 0.38,
    );
    canvas.drawOval(orbit, white..strokeWidth = w * 0.028);

    // Pin body
    final pinCenter = Offset(w * 0.5, h * 0.42);
    final pinRadius = w * 0.22;
    canvas.drawCircle(pinCenter, pinRadius, fill);

    // Pin tip
    final tip = Path()
      ..moveTo(w * 0.38, h * 0.55)
      ..lineTo(w * 0.5, h * 0.78)
      ..lineTo(w * 0.62, h * 0.55)
      ..close();
    canvas.drawPath(tip, fill);

    // Globe inside pin
    final globePaint = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.03;
    canvas.drawCircle(pinCenter, pinRadius * 0.55, globePaint);
    canvas.drawArc(
      Rect.fromCircle(center: pinCenter, radius: pinRadius * 0.55),
      -math.pi / 2,
      math.pi,
      false,
      globePaint,
    );
    canvas.drawLine(
      Offset(pinCenter.dx - pinRadius * 0.5, pinCenter.dy),
      Offset(pinCenter.dx + pinRadius * 0.5, pinCenter.dy),
      globePaint,
    );

    // Airplane (simple triangle)
    final plane = Path()
      ..moveTo(w * 0.68, h * 0.22)
      ..lineTo(w * 0.82, h * 0.28)
      ..lineTo(w * 0.70, h * 0.34)
      ..lineTo(w * 0.72, h * 0.28)
      ..close();
    canvas.drawPath(plane, fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
