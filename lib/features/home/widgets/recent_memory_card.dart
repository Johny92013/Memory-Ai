import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Kompakte Erinnerungskarte für die horizontale Liste.
class RecentMemoryCard extends StatelessWidget {
  const RecentMemoryCard({super.key, required this.item, required this.onTap});

  final MediaItemModel item;
  final VoidCallback onTap;

  static const _months = [
    'Januar',
    'Februar',
    'März',
    'April',
    'Mai',
    'Juni',
    'Juli',
    'August',
    'September',
    'Oktober',
    'November',
    'Dezember',
  ];

  String get _title {
    final location =
        item.locationName?.trim() ??
        item.city?.trim() ??
        item.countryName?.trim();
    if (location != null && location.isNotEmpty) return location;
    final title = item.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return 'Erinnerung';
  }

  String get _dateLabel {
    final date = item.takenAt ?? item.createdAt;
    if (date == null) return '–';
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Heute';
    }
    return '${date.day}. ${_months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 110,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 88,
                  width: 110,
                  child: FutureBuilder<String?>(
                    future: SignedUrlService.mediaGridUrl(item),
                    builder: (context, snapshot) {
                      final url = snapshot.data;
                      if (url == null) {
                        return Container(
                          color: HomeDashboardColors.blueSoft,
                          child: const Icon(
                            Icons.image_outlined,
                            color: HomeDashboardColors.secondaryText,
                          ),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: HomeDashboardColors.blueSoft),
                        errorWidget: (_, _, _) => Container(
                          color: HomeDashboardColors.blueSoft,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeDashboardColors.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: HomeDashboardColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
