/// Berechnet metadata_status aus vorhandenen Metadaten-Flags.
abstract final class MetadataStatusHelper {
  static String compute({
    required bool hasDate,
    required bool hasLocation,
    bool hasPeople = true,
    bool failed = false,
    bool manualOverride = false,
  }) {
    if (failed) return 'failed';
    if (manualOverride) return 'manual';

    final missingDate = !hasDate;
    final missingLocation = !hasLocation;
    final missingPeople = !hasPeople;

    if (missingDate && missingLocation) return 'missing_location_and_date';
    if (missingLocation) return 'missing_location';
    if (missingDate) return 'missing_date';
    if (missingPeople) return 'missing_people';
    return 'automatic';
  }
}
