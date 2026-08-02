import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Video-Overlay: Play-Icon und Dauer.
class VideoThumbnailOverlay extends StatelessWidget {
  const VideoThumbnailOverlay({super.key, this.durationSeconds});

  final int? durationSeconds;

  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        if (durationSeconds != null && durationSeconds! > 0)
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                formatDuration(durationSeconds!),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Einzelnes Galerie-Kachel mit optionalem Video-Overlay.
class MemoryGridTile extends StatelessWidget {
  const MemoryGridTile({
    super.key,
    required this.item,
    this.onTap,
    this.showNoGpsBadge = false,
    this.borderRadius = 10,
  });

  final MediaItemModel item;
  final VoidCallback? onTap;
  final bool showNoGpsBadge;
  final double borderRadius;

  bool get _isVideo => item.mediaType == 'video';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            FutureBuilder<String?>(
              future: SignedUrlService.mediaGridUrl(item),
              builder: (context, snapshot) {
                final url = snapshot.data;
                if (url == null) {
                  return Container(
                    color: AppColors.cardBackground,
                    child: Icon(
                      _isVideo ? Icons.videocam_outlined : Icons.image_outlined,
                      color: AppColors.textSecondary,
                    ),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      Container(color: AppColors.cardBackground),
                  errorWidget: (_, _, _) => Container(
                    color: AppColors.cardBackground,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                );
              },
            ),
            if (_isVideo)
              VideoThumbnailOverlay(durationSeconds: item.durationSeconds),
            if (showNoGpsBadge)
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.location_off,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
