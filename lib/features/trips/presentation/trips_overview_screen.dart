import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/boarding_pass_trip_card.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Übersicht: aktive/vergangene Reisen, Vorschläge, nach Jahr gruppiert.
class TripsOverviewScreen extends StatefulWidget {
  const TripsOverviewScreen({super.key});

  @override
  State<TripsOverviewScreen> createState() => _TripsOverviewScreenState();
}

class _TripsOverviewScreenState extends State<TripsOverviewScreen> {
  final _repo = TripRepository();
  List<TripModel> _trips = [];
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
      final trips = await _repo.listMyTrips();
      if (!mounted) return;
      setState(() {
        _trips = trips;
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

  Map<int, List<TripModel>> _groupByYear(List<TripModel> trips) {
    final map = <int, List<TripModel>>{};
    for (final trip in trips) {
      final year = trip.startDate?.year ?? trip.createdAt?.year ?? 0;
      map.putIfAbsent(year, () => []).add(trip);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final active = _trips.where((t) => t.isActive).toList();
    final past = _trips.where((t) => t.isPast).toList();
    final grouped = _groupByYear(_trips);
    final years = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accentWarm,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Reisen',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.lightbulb_outline),
                        tooltip: 'Vorschläge',
                        onPressed: () => context.push('/trips/suggestions'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Reise erstellen',
                        onPressed: () => context.push('/trips/create'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Reisevorschläge anzeigen',
                    onPressed: () => context.push('/trips/suggestions'),
                  ),
                  if (active.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Aktive Reisen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...active.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BoardingPassTripCard(trip: t),
                      ),
                    ),
                  ],
                  if (past.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Vergangene Reisen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ...past.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: BoardingPassTripCard(trip: t),
                      ),
                    ),
                  ],
                  if (years.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Nach Jahr',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final year in years) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '$year',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accentCool,
                          letterSpacing: 1.4,
                        ),
                      ),
                      ...grouped[year]!.map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: BoardingPassTripCard(trip: t),
                        ),
                      ),
                    ],
                  ],
                  if (_trips.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xxxl),
                      child: EmptyState(
                        icon: Icons.flight_takeoff,
                        title: 'Noch keine Reisen',
                        subtitle: 'Erstelle eine Reise oder prüfe Vorschläge.',
                        buttonLabel: 'Reise erstellen',
                        onButtonPressed: () => context.push('/trips/create'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
