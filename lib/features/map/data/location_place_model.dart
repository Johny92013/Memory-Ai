import 'package:memory_ai/core/utils/continent_from_country.dart';

/// Ergebnis eines Reverse-Geocoding (Nominatim).
class LocationPlace {
  const LocationPlace({
    this.country,
    this.countryCode,
    this.region,
    this.city,
    this.locationName,
    this.displayName,
    this.continent,
  });

  final String? country;
  final String? countryCode;
  final String? region;
  final String? city;
  final String? locationName;
  final String? displayName;
  final String? continent;

  bool get hasAnyPlaceData =>
      (country != null && country!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      (locationName != null && locationName!.isNotEmpty);

  factory LocationPlace.fromJson(Map<String, dynamic> json) {
    final code = json['country_code'] as String?;
    return LocationPlace(
      country: json['country'] as String?,
      countryCode: code,
      region: json['region'] as String?,
      city: json['city'] as String?,
      locationName: json['location_name'] as String?,
      displayName: json['display_name'] as String?,
      continent:
          json['continent'] as String? ??
          ContinentFromCountry.fromCountryCode(code),
    );
  }

  Map<String, dynamic> toJson() => {
    if (country != null) 'country': country,
    if (countryCode != null) 'country_code': countryCode,
    if (region != null) 'region': region,
    if (city != null) 'city': city,
    if (locationName != null) 'location_name': locationName,
    if (displayName != null) 'display_name': displayName,
    if (continent != null) 'continent': continent,
  };

  factory LocationPlace.fromNominatimJson(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    final country = _firstNonEmpty([address['country'] as String?]);
    final countryCode = _firstNonEmpty([address['country_code'] as String?]);
    final region = _firstNonEmpty([
      address['state'] as String?,
      address['region'] as String?,
      address['county'] as String?,
    ]);
    final city = _firstNonEmpty([
      address['city'] as String?,
      address['town'] as String?,
      address['village'] as String?,
      address['municipality'] as String?,
      address['hamlet'] as String?,
    ]);
    final locationName = _firstNonEmpty([
      address['suburb'] as String?,
      address['neighbourhood'] as String?,
      address['road'] as String?,
      city,
      region,
    ]);
    final displayName = json['display_name'] as String?;
    final code = countryCode?.toUpperCase();

    return LocationPlace(
      country: country,
      countryCode: code,
      region: region,
      city: city,
      locationName: locationName ?? displayName,
      displayName: displayName,
      continent: ContinentFromCountry.fromCountryCode(code),
    );
  }

  LocationPlace withContinentFromCode() {
    if (continent != null && continent!.isNotEmpty) return this;
    return LocationPlace(
      country: country,
      countryCode: countryCode,
      region: region,
      city: city,
      locationName: locationName,
      displayName: displayName,
      continent: ContinentFromCountry.fromCountryCode(countryCode),
    );
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }
}
