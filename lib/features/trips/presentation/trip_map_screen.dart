import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

class TripMapScreen extends StatefulWidget {
  const TripMapScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripMapScreen> createState() => _TripMapScreenState();
}

class _TripMapScreenState extends State<TripMapScreen> {
  final _repo = TripRepository();
  List<MediaItemModel> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.listTripMedia(widget.tripId);
      if (!mounted) return;
      setState(() {
        _items = items.where((i) => i.hasGps).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = MapAggregationHelper.groupByCoordinates(_items);
    final center = groups.isNotEmpty
        ? LatLng(groups.first.latitude, groups.first.longitude)
        : const LatLng(51.1657, 10.4515);

    return AppScaffold(
      title: 'Reise-Karte',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.map_outlined,
              title: 'Keine Standorte',
              subtitle: 'Diese Reise hat noch keine Fotos mit GPS.',
            )
          : FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 8),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  userAgentPackageName: 'memory_ai',
                ),
                MarkerLayer(
                  markers: groups
                      .map(
                        (g) => Marker(
                          point: LatLng(g.latitude, g.longitude),
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.place, color: Colors.red),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
    );
  }
}
