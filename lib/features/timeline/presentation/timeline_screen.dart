import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/widgets/media_thumbnail_grid.dart';
import 'package:memory_ai/features/timeline/data/timeline_sorting.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Globale Timeline: Jahr → Monat → Tag.
class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final _repo = MediaRepository();
  List<TimelineYearGroup> _years = [];
  bool _loading = true;
  String? _error;
  int? _yearFilter;

  @override
  void initState() {
    super.initState();
    MediaChangeNotifier.instance.addListener(_onMediaChanged);
    _load();
  }

  @override
  void dispose() {
    MediaChangeNotifier.instance.removeListener(_onMediaChanged);
    super.dispose();
  }

  void _onMediaChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.listMyMedia(limit: 500, offset: 0);
      final years = TimelineSorting.groupChronologically(items);
      if (!mounted) return;
      setState(() {
        _years = years;
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
    final filtered = _yearFilter == null
        ? _years
        : _years.where((y) => y.year == _yearFilter).toList();

    return AppScaffold(
      title: 'Timeline',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _years.isEmpty
          ? const EmptyState(
              icon: Icons.timeline,
              title: 'Noch keine Erinnerungen',
              subtitle: 'Lade Fotos hoch, um deine Timeline zu füllen.',
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Alle'),
                        selected: _yearFilter == null,
                        onSelected: (_) => setState(() => _yearFilter = null),
                      ),
                      ..._years.map(
                        (y) => FilterChip(
                          label: Text('${y.year}'),
                          selected: _yearFilter == y.year,
                          onSelected: (_) =>
                              setState(() => _yearFilter = y.year),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final year in filtered) ...[
                    Text(
                      '${year.year}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    for (final month in year.months) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4),
                        child: Text(
                          DateFormat.MMMM().format(
                            DateTime(year.year, month.month),
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      for (final day in month.days) ...[
                        Text(
                          dateFormat.format(day.date),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        MediaThumbnailGrid(items: day.items, crossAxisCount: 4),
                        const SizedBox(height: 12),
                      ],
                    ],
                  ],
                ],
              ),
            ),
    );
  }
}
