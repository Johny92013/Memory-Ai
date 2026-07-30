import 'dart:async';

import 'package:memory_ai/features/map/data/coordinate_key.dart';
import 'package:memory_ai/features/map/data/location_place_model.dart';

/// Warteschlange mit mindestens 1100 ms zwischen echten Nominatim-Anfragen.
class NominatimRateLimitQueue {
  NominatimRateLimitQueue({required this._executor, this.minDelayMs = 1100});

  final Future<LocationPlace?> Function(double lat, double lon) _executor;
  final int minDelayMs;

  final Map<String, Future<LocationPlace?>> _inFlight = {};
  final List<_QueueTask> _queue = [];
  bool _processing = false;
  DateTime? _lastRequestAt;

  Future<LocationPlace?> reverse(double latitude, double longitude) {
    final rounded = CoordinateKey.roundedPair(latitude, longitude);
    final key = CoordinateKey.fromLatLon(rounded.lat, rounded.lon);

    final existing = _inFlight[key];
    if (existing != null) return existing;

    final future = _enqueue(rounded.lat, rounded.lon, key);
    _inFlight[key] = future;
    future.whenComplete(() => _inFlight.remove(key));
    return future;
  }

  Future<LocationPlace?> _enqueue(double lat, double lon, String key) {
    final completer = Completer<LocationPlace?>();
    _queue.add(_QueueTask(key: key, lat: lat, lon: lon, completer: completer));
    _processQueue();
    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_processing) return;
    _processing = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeAt(0);

      if (_lastRequestAt != null) {
        final elapsed = DateTime.now()
            .difference(_lastRequestAt!)
            .inMilliseconds;
        if (elapsed < minDelayMs) {
          await Future<void>.delayed(
            Duration(milliseconds: minDelayMs - elapsed),
          );
        }
      }

      try {
        final result = await _executor(task.lat, task.lon);
        if (!task.completer.isCompleted) task.completer.complete(result);
      } catch (_) {
        if (!task.completer.isCompleted) task.completer.complete(null);
      }
      _lastRequestAt = DateTime.now();
    }

    _processing = false;
  }
}

class _QueueTask {
  _QueueTask({
    required this.key,
    required this.lat,
    required this.lon,
    required this.completer,
  });

  final String key;
  final double lat;
  final double lon;
  final Completer<LocationPlace?> completer;
}
