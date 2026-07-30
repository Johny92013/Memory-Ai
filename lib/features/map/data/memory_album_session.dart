import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// In-App-Album (Session, keine serverseitige Dateikopie).
class MemoryAlbumSession {
  const MemoryAlbumSession({
    required this.title,
    required this.items,
    this.coverMediaId,
    this.locationLabel,
    this.layout = AlbumLayout.single,
    this.captionsEnabled = true,
  });

  final String title;
  final List<MediaItemModel> items;
  final String? coverMediaId;
  final String? locationLabel;
  final AlbumLayout layout;
  final bool captionsEnabled;

  MediaItemModel? get cover {
    if (coverMediaId == null) return items.isEmpty ? null : items.first;
    for (final i in items) {
      if (i.id == coverMediaId) return i;
    }
    return items.isEmpty ? null : items.first;
  }

  DateTime? get dateFrom {
    final dates =
        items
            .map((i) => i.takenAt ?? i.createdAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    return dates.isEmpty ? null : dates.first;
  }

  DateTime? get dateTo {
    final dates =
        items
            .map((i) => i.takenAt ?? i.createdAt)
            .whereType<DateTime>()
            .toList()
          ..sort();
    return dates.isEmpty ? null : dates.last;
  }
}

enum AlbumLayout { single, doublePage, collage, mixed }

/// Slideshow-Konfiguration (reine In-App-Wiedergabe).
class SlideshowSession {
  const SlideshowSession({
    required this.items,
    this.secondsPerImage = 3,
    this.showCaptions = true,
    this.locationLabel,
  });

  final List<MediaItemModel> items;
  final int secondsPerImage;
  final bool showCaptions;
  final String? locationLabel;
}
