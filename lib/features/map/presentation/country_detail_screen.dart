import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/map/data/map_repository.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/widgets/media_thumbnail_grid.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Detailansicht für ein Land auf der Weltkarte.
class CountryDetailScreen extends StatefulWidget {
  const CountryDetailScreen({super.key, required this.countryName});

  final String countryName;

  @override
  State<CountryDetailScreen> createState() => _CountryDetailScreenState();
}

class _CountryDetailScreenState extends State<CountryDetailScreen> {
  final _repo = MapRepository();
  List<MediaItemModel> _items = [];
  List<CityStats> _cities = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.loadCountryMedia(
        countryName: widget.countryName,
      );
      final cities = _repo.cityStats(items, widget.countryName);
      if (!mounted) return;
      setState(() {
        _items = items;
        _cities = cities;
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
    final trips = _items.map((i) => i.tripId).whereType<String>().toSet();
    final years =
        _items
            .map((i) => i.takenAt?.year ?? i.createdAt?.year)
            .whereType<int>()
            .toSet()
            .toList()
          ..sort();

    return AppScaffold(
      title: widget.countryName,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.public_off_outlined,
              title: 'Keine Fotos',
              subtitle: 'In diesem Land gibt es noch keine Fotos mit Standort.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _StatsCard(
                    photoCount: _items.length,
                    tripCount: trips.length,
                    years: years,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Vorschau',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MediaThumbnailGrid(items: _items.take(6).toList()),
                  if (_cities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Häufige Orte',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._cities.map(
                      (city) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_city_outlined),
                        title: Text(city.cityName),
                        subtitle: Text('${city.photoCount} Fotos'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          '/map/location?country=${Uri.encodeComponent(widget.countryName)}&city=${Uri.encodeComponent(city.cityName)}',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.photoCount,
    required this.tripCount,
    required this.years,
  });

  final int photoCount;
  final int tripCount;
  final List<int> years;

  @override
  Widget build(BuildContext context) {
    final yearText = years.isEmpty
        ? '–'
        : years.map((y) => y.toString()).join(', ');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatRow(label: 'Fotos', value: '$photoCount'),
          _StatRow(label: 'Reisen', value: '$tripCount'),
          _StatRow(label: 'Jahre', value: yearText),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
