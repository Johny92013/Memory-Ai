import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

class TripTimelineScreen extends StatefulWidget {
  const TripTimelineScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripTimelineScreen> createState() => _TripTimelineScreenState();
}

class _TripTimelineScreenState extends State<TripTimelineScreen> {
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
        _items = items;
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
    final dateFormat = DateFormat('dd.MM.yyyy');
    return AppScaffold(
      title: 'Reise-Timeline',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.timeline,
              title: 'Keine Einträge',
              subtitle: 'Noch keine Fotos in dieser Reise.',
            )
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final date = item.takenAt ?? item.createdAt;
                return ListTile(
                  leading: const Icon(Icons.photo_outlined),
                  title: Text(item.title ?? item.locationName ?? 'Foto'),
                  subtitle: Text(
                    date != null
                        ? '${dateFormat.format(date)} · ${item.city ?? item.countryName ?? ''}'
                        : '',
                  ),
                );
              },
            ),
    );
  }
}
