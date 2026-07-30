/// Batch-Hilfen für Upload-Metadaten (testbar ohne UI).
abstract final class BatchMetadataOps {
  /// Setzt manuelles Datum auf alle [itemIds] in [items] (per id).
  static List<T> applyDateToItems<T>({
    required List<T> items,
    required Set<String> itemIds,
    required String Function(T) idOf,
    required T Function(T item, DateTime date) update,
    required DateTime date,
  }) {
    return items.map((item) {
      if (!itemIds.contains(idOf(item))) return item;
      return update(item, date);
    }).toList();
  }

  static List<T> applyLocationToItems<T>({
    required List<T> items,
    required Set<String> itemIds,
    required String Function(T) idOf,
    required T Function(
      T item, {
      required double latitude,
      required double longitude,
      String? locationName,
    })
    update,
    required double latitude,
    required double longitude,
    String? locationName,
  }) {
    return items.map((item) {
      if (!itemIds.contains(idOf(item))) return item;
      return update(
        item,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
      );
    }).toList();
  }
}

/// Ausgewählter Standort aus dem LocationPicker.
class PickedLocation {
  const PickedLocation({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.city,
    this.countryName,
    this.countryCode,
    this.continent,
  });

  final double latitude;
  final double longitude;
  final String? locationName;
  final String? city;
  final String? countryName;
  final String? countryCode;
  final String? continent;
}
