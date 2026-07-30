import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/features/trips/data/trip_suggestion_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Reisevorschläge – Nutzer muss jeden Vorschlag explizit bestätigen.
class TripSuggestionsScreen extends StatefulWidget {
  const TripSuggestionsScreen({super.key});

  @override
  State<TripSuggestionsScreen> createState() => _TripSuggestionsScreenState();
}

class _TripSuggestionsScreenState extends State<TripSuggestionsScreen> {
  final _repo = TripRepository();
  List<TripSuggestion> _suggestions = [];
  List<TripModel> _existingTrips = [];
  bool _loading = true;
  String? _error;
  String? _actionError;

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
      final suggestions = await _repo.listSuggestions();
      final trips = await _repo.listMyTrips();
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
        _existingTrips = trips;
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

  Future<void> _createTrip(TripSuggestion suggestion) async {
    setState(() => _actionError = null);
    try {
      final trip = await _repo.createFromSuggestion(suggestion);
      if (!mounted) return;
      context.pushReplacement('/trips/${trip.id}');
    } catch (e) {
      setState(() => _actionError = ErrorMapper.map(e).message);
    }
  }

  Future<void> _addToTrip(TripSuggestion suggestion) async {
    if (_existingTrips.isEmpty) {
      setState(() => _actionError = 'Keine bestehende Reise vorhanden.');
      return;
    }
    final trip = await showModalBottomSheet<TripModel>(
      context: context,
      builder: (context) => _TripPickerSheet(trips: _existingTrips),
    );
    if (trip == null) return;
    try {
      await _repo.assignMediaToTrip(
        tripId: trip.id,
        mediaIds: suggestion.mediaItems.map((m) => m.id).toList(),
      );
      await _repo.dismissSuggestion(suggestion);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fotos zur Reise hinzugefügt.')),
      );
      _load();
    } catch (e) {
      setState(() => _actionError = ErrorMapper.map(e).message);
    }
  }

  Future<void> _dismiss(TripSuggestion suggestion) async {
    await _repo.dismissSuggestion(suggestion);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reisevorschläge',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _suggestions.isEmpty
          ? const EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'Keine Vorschläge',
              subtitle:
                  'Sobald genügend Fotos mit Standortdaten vorhanden sind, schlagen wir Reisen vor.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return Card(
                  color: AppColors.card,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          suggestion.suggestedTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          suggestion.descriptionText(),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (_actionError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _actionError!,
                            style: const TextStyle(color: AppColors.accentPink),
                          ),
                        ],
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Reise erstellen',
                          onPressed: () => _createTrip(suggestion),
                        ),
                        const SizedBox(height: 8),
                        AppButton(
                          label: 'Zu bestehender Reise hinzufügen',
                          onPressed: () => _addToTrip(suggestion),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => _dismiss(suggestion),
                          child: const Text('Nicht jetzt'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TripPickerSheet extends StatelessWidget {
  const _TripPickerSheet({required this.trips});

  final List<TripModel> trips;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Reise auswählen',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ),
          ...trips.map(
            (trip) => ListTile(
              title: Text(trip.title),
              onTap: () => Navigator.pop(context, trip),
            ),
          ),
        ],
      ),
    );
  }
}
