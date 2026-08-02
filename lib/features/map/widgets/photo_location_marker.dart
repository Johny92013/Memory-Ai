import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Runder Foto-Standortmarker mit Jahresfarbe.
class PhotoLocationMarker extends StatelessWidget {
  const PhotoLocationMarker({
    super.key,
    required this.items,
    this.count,
    this.selected = false,
    this.onTap,
  });

  final List<MediaItemModel> items;
  final int? count;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 60.0 : 48.0;
    final color = YearColorPalette.forItems(items);
    final cover = items.isEmpty ? null : items.first;
    final label = count ?? items.length;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size + 8,
        height: size + 14,
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipOval(
                child: cover == null
                    ? Container(
                        decoration: const BoxDecoration(
                          gradient: AppColors.brandGradient,
                        ),
                        child: const Icon(
                          Icons.place,
                          color: AppColors.white,
                          size: 20,
                        ),
                      )
                    : FutureBuilder<String?>(
                        future: SignedUrlService.mediaGridUrl(cover),
                        builder: (context, snap) {
                          final url = snap.data;
                          if (url == null) {
                            return Container(color: AppColors.cardElevated);
                          }
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
              ),
            ),
            CustomPaint(
              size: const Size(12, 8),
              painter: _PinTipPainter(color),
            ),
            if (label > 1)
              Text(
                '$label',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TravelMapClusterMarker extends StatelessWidget {
  const TravelMapClusterMarker({
    super.key,
    required this.count,
    required this.color,
    this.onTap,
  });

  final int count;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.75)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 2),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  _PinTipPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
