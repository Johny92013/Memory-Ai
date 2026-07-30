import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Wiederverwendetes Foto-Grid mit Thumbnails.
class MediaThumbnailGrid extends StatelessWidget {
  const MediaThumbnailGrid({
    super.key,
    required this.items,
    this.onTap,
    this.crossAxisCount = 3,
  });

  final List<MediaItemModel> items;
  final void Function(MediaItemModel item)? onTap;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: onTap != null ? () => onTap!(item) : null,
          child: _ThumbTile(item: item),
        );
      },
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({required this.item});

  final MediaItemModel item;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: SignedUrlService.mediaGridUrl(item),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url == null) {
          return Container(
            color: AppColors.card,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary,
            ),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.card),
            errorWidget: (_, _, _) => Container(
              color: AppColors.card,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        );
      },
    );
  }
}
