import 'package:intl/intl.dart';

/// Datumsformatierung für die deutsche Oberfläche.
///
/// Verwendet feste Muster ohne Locale-Daten, damit Web/Chrome
/// ohne `initializeDateFormatting` zuverlässig funktioniert.
class DateFormatter {
  DateFormatter._();

  static final DateFormat _date = DateFormat('d. MMMM yyyy');
  static final DateFormat _dateTime = DateFormat('d. MMM yyyy, HH:mm');
  static final DateFormat _time = DateFormat('HH:mm');
  static final DateFormat _shortDate = DateFormat('dd.MM.yyyy');

  static String formatDate(DateTime date) => _date.format(date);

  static String formatDateTime(DateTime dateTime) => _dateTime.format(dateTime);

  static String formatTime(DateTime dateTime) => _time.format(dateTime);

  static String formatShortDate(DateTime date) => _shortDate.format(date);

  static String day(DateTime? date) {
    if (date == null) {
      return '–';
    }
    return formatShortDate(date);
  }

  static String formatRelative(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Gerade eben';
    }
    if (difference.inHours < 1) {
      return 'Vor ${difference.inMinutes} Min.';
    }
    if (difference.inDays < 1) {
      return 'Vor ${difference.inHours} Std.';
    }
    if (difference.inDays == 1) {
      return 'Gestern';
    }
    if (difference.inDays < 7) {
      return 'Vor ${difference.inDays} Tagen';
    }
    return formatShortDate(dateTime);
  }
}
