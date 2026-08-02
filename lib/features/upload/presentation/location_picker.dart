import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/services/location_service.dart';
import 'package:memory_ai/features/map/data/nominatim_service.dart';
import 'package:memory_ai/features/upload/data/batch_metadata_ops.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

/// Standortwahl: Ortssuche, Karte, aktueller Standort.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.locationService,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final LocationService? locationService;

  static Future<PickedLocation?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
  }) {
    return showModalBottomSheet<PickedLocation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.85,
        child: LocationPicker(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
        ),
      ),
    );
  }

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final LocationService _locationService;
  late final MapController _mapController;
  late final TextEditingController _searchController;

  LatLng _center = const LatLng(51.1657, 10.4515);
  List<NominatimSearchResult> _results = [];
  bool _searching = false;
  bool _resolving = false;
  String? _error;
  String? _label;

  @override
  void initState() {
    super.initState();
    _locationService = widget.locationService ?? LocationService();
    _mapController = MapController();
    _searchController = TextEditingController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _center = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() {
      _searching = true;
      _error = null;
    });
    final results = await _locationService.searchPlaces(_searchController.text);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      if (results.isEmpty) _error = 'Keine Orte gefunden.';
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _resolving = true;
      _error = null;
    });
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _resolving = false;
          _error = 'Standortberechtigung fehlt.';
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await _selectLatLon(pos.latitude, pos.longitude);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = 'Aktueller Standort nicht verfügbar.';
      });
    }
  }

  Future<void> _selectLatLon(double lat, double lon, {String? hint}) async {
    setState(() {
      _center = LatLng(lat, lon);
      _resolving = true;
      _error = null;
      _label = hint;
    });
    _mapController.move(_center, 14);
    final place = await _locationService.resolveCoordinates(lat, lon);
    if (!mounted) return;
    setState(() {
      _resolving = false;
      _label =
          place?.locationName ??
          place?.city ??
          hint ??
          '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
    });
  }

  void _confirm() {
    Navigator.pop(
      context,
      PickedLocation(
        latitude: _center.latitude,
        longitude: _center.longitude,
        locationName: _label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Standort wählen',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Ort suchen …',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                IconButton(
                  onPressed: _searching ? null : _search,
                  icon: _searching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            if (_results.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final r = _results[i];
                    final title =
                        r.place.locationName ??
                        r.place.city ??
                        r.place.displayName ??
                        'Ort';
                    return ListTile(
                      dense: true,
                      title: Text(title, maxLines: 1),
                      subtitle: Text(r.place.country ?? '', maxLines: 1),
                      onTap: () {
                        _results = [];
                        _selectLatLon(r.latitude, r.longitude, hint: title);
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 5,
                    onTap: (_, latLng) =>
                        _selectLatLon(latLng.latitude, latLng.longitude),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.johny92013.memoryai',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.accentWarm,
                            size: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (_label != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_label!, style: Theme.of(context).textTheme.bodyMedium),
            ],
            if (_error != null)
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _resolving ? null : _useCurrentLocation,
              icon: const Icon(Icons.my_location),
              label: const Text('Aktuellen Standort verwenden'),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: _resolving ? 'Wird ermittelt …' : 'Standort übernehmen',
              onPressed: _resolving ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}
