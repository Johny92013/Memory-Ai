import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Gepunktete Perforationslinie (Bordkarten-Stil).
class PerforatedDivider extends StatelessWidget {
  const PerforatedDivider({super.key, this.color, this.height = 12});

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _PerforatedPainter(color: color ?? AppColors.textSecondary),
      ),
    );
  }
}

class _PerforatedPainter extends CustomPainter {
  _PerforatedPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final centerY = size.height / 2;
    const dash = 4.0;
    const gap = 5.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, centerY), Offset(x + dash, centerY), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
