import 'dart:math' as math;

/// Rundet Koordinaten für Cache-Keys und Nominatim-Bündelung.
class CoordinateKey {
  CoordinateKey._();

  /// 4 Nachkommastellen ≈ 11 m – bündelt nahe Koordinaten zu einer Anfrage.
  static const int groupingDecimals = 4;

  /// 5 Nachkommastellen für feinere Cache-Schlüssel (optional identisch).
  static const int cacheDecimals = 4;

  static double roundCoordinate(
    double value, {
    int decimals = groupingDecimals,
  }) {
    final factor = math.pow(10, decimals).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  static String fromLatLon(
    double latitude,
    double longitude, {
    int decimals = cacheDecimals,
  }) {
    final lat = roundCoordinate(latitude, decimals: decimals);
    final lon = roundCoordinate(longitude, decimals: decimals);
    return '${lat.toStringAsFixed(decimals)}_${lon.toStringAsFixed(decimals)}';
  }

  static ({double lat, double lon}) roundedPair(
    double latitude,
    double longitude, {
    int decimals = groupingDecimals,
  }) {
    return (
      lat: roundCoordinate(latitude, decimals: decimals),
      lon: roundCoordinate(longitude, decimals: decimals),
    );
  }
}
