import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Vorschlag für eine neue Reise (muss explizit bestätigt werden).
class TripSuggestion {
  const TripSuggestion({
    required this.id,
    required this.countryName,
    required this.mediaItems,
    required this.startDate,
    required this.endDate,
    required this.suggestedTitle,
  });

  final String id;
  final String countryName;
  final List<MediaItemModel> mediaItems;
  final DateTime startDate;
  final DateTime endDate;
  final String suggestedTitle;

  int get photoCount => mediaItems.length;

  String descriptionText() {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);
    return 'Wir haben $photoCount Fotos aus $countryName zwischen dem $start und $end gefunden.';
  }

  static String _formatDate(DateTime date) {
    return '${date.day}. ${_monthName(date.month)} ${date.year}';
  }

  static String _monthName(int month) {
    const months = [
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
    return months[month - 1];
  }
}
