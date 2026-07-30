/// Speichert verworfene Reisevorschläge (Session-basiert).
class TripSuggestionDismissalStore {
  TripSuggestionDismissalStore._();

  static final Set<String> _dismissedKeys = {};

  static String clusterKey(List<String> mediaIds) => mediaIds.join('|');

  static void dismiss(List<String> mediaIds) {
    _dismissedKeys.add(clusterKey(mediaIds));
  }

  static bool isDismissed(List<String> mediaIds) =>
      _dismissedKeys.contains(clusterKey(mediaIds));
}
