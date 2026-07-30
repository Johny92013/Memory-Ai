import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/core/utils/continent_from_country.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';
import 'package:memory_ai/features/memories/data/metadata_status_helper.dart';

void main() {
  group('ContinentFromCountry', () {
    test('leitet Kontinent aus country_code ab', () {
      expect(ContinentFromCountry.fromCountryCode('DE'), 'Europe');
      expect(ContinentFromCountry.fromCountryCode('us'), 'North America');
      expect(ContinentFromCountry.fromCountryCode('BR'), 'South America');
      expect(ContinentFromCountry.fromCountryCode('JP'), 'Asia');
      expect(ContinentFromCountry.fromCountryCode('ZA'), 'Africa');
      expect(ContinentFromCountry.fromCountryCode('AU'), 'Oceania');
      expect(ContinentFromCountry.fromCountryCode('AQ'), 'Antarctica');
      expect(ContinentFromCountry.fromCountryCode(null), isNull);
      expect(ContinentFromCountry.fromCountryCode('XX'), isNull);
    });
  });

  group('LocationPlace continent', () {
    test('fromNominatimJson setzt continent aus country_code', () {
      final place = LocationPlace.fromNominatimJson({
        'display_name': 'München',
        'address': {
          'country': 'Deutschland',
          'country_code': 'de',
          'city': 'München',
        },
      });
      expect(place.countryCode, 'DE');
      expect(place.continent, 'Europe');
    });
  });

  group('MetadataStatusHelper', () {
    test('missing_location_and_date', () {
      expect(
        MetadataStatusHelper.compute(hasDate: false, hasLocation: false),
        'missing_location_and_date',
      );
    });

    test('missing_location', () {
      expect(
        MetadataStatusHelper.compute(hasDate: true, hasLocation: false),
        'missing_location',
      );
    });

    test('automatic', () {
      expect(
        MetadataStatusHelper.compute(hasDate: true, hasLocation: true),
        'automatic',
      );
    });
  });
}
