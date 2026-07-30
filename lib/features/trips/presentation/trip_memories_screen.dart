import 'package:flutter/material.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/widgets/media_thumbnail_grid.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

class TripMemoriesScreen extends StatefulWidget {
  const TripMemoriesScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripMemoriesScreen> createState() => _TripMemoriesScreenState();
}

class _TripMemoriesScreenState extends State<TripMemoriesScreen> {
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
    return AppScaffold(
      title: 'Reise-Galerie',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _items.isEmpty
          ? const EmptyState(
              icon: Icons.photo_library_outlined,
              title: 'Keine Fotos',
              subtitle: 'In dieser Reise sind noch keine Fotos.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: MediaThumbnailGrid(items: _items),
              ),
            ),
    );
  }
}
