import 'package:memory_ai/core/services/location_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';

/// Ergänzt `media_items` mit Standortnamen im Hintergrund (nicht blockierend für Upload).
class MediaLocationEnrichmentService {
  MediaLocationEnrichmentService({
    MediaRepository? mediaRepository,
    LocationService? locationService,
  }) : _mediaRepository = mediaRepository ?? MediaRepository(),
       _locationService = locationService ?? LocationService();

  final MediaRepository _mediaRepository;
  final LocationService _locationService;

  /// Startet Hintergrund-Aktualisierung aller offenen Einträge.
  Future<void> enrichPendingInBackground() async {
    try {
      final pending = await _mediaRepository.listPendingLocationEnrichment();
      for (final item in pending) {
        await enrichMediaItem(item);
      }
    } catch (_) {
      // Hintergrund – kein Abbruch
    }
  }

  /// Einzelnes Medium anreichern; Fehler werden ignoriert.
  /// Koordinaten bleiben erhalten, auch wenn Geocoding fehlschlägt.
  Future<void> enrichMediaItem(MediaItemModel item) async {
    if (item.latitude == null || item.longitude == null) return;
    if (_hasLocationLabels(item) &&
        item.continent != null &&
        item.continent!.trim().isNotEmpty) {
      return;
    }

    final place = await _locationService.resolveCoordinates(
      item.latitude!,
      item.longitude!,
    );
    if (place == null || !place.hasAnyPlaceData) return;

    await _mediaRepository.updateLocationFromPlace(
      mediaId: item.id,
      place: place,
    );
  }

  bool _hasLocationLabels(MediaItemModel item) {
    final hasCountry =
        item.countryName != null && item.countryName!.trim().isNotEmpty;
    final hasCity = item.city != null && item.city!.trim().isNotEmpty;
    return hasCountry && hasCity;
  }

  /// Manuelle Standortaktualisierung (inkl. Reverse-Geocoding wenn GPS gesetzt).
  Future<void> updateManualLocation({
    required String mediaId,
    required double latitude,
    required double longitude,
    String? locationName,
    bool removeGps = false,
  }) async {
    if (removeGps) {
      await _mediaRepository.clearLocation(mediaId);
      return;
    }

    final place = await _locationService.resolveCoordinates(
      latitude,
      longitude,
    );
    await _mediaRepository.updateLocationManual(
      mediaId: mediaId,
      latitude: latitude,
      longitude: longitude,
      place: place,
      locationName: locationName,
    );
  }
}
