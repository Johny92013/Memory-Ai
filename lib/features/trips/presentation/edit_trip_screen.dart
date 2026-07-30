import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';

class EditTripScreen extends StatefulWidget {
  const EditTripScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends State<EditTripScreen> {
  final _repo = TripRepository();
  TripModel? _trip;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final trip = await _repo.getTrip(widget.tripId);
      _trip = trip;
      _titleController.text = trip?.title ?? '';
      _descController.text = trip?.description ?? '';
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final trip = _trip;
    if (trip == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repo.updateTrip(
        TripModel(
          id: trip.id,
          ownerId: trip.ownerId,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          status: trip.status,
          startDate: trip.startDate,
          endDate: trip.endDate,
        ),
      );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(() {
        _saving = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Reise bearbeiten',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  AppTextField(controller: _titleController, label: 'Titel'),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _descController,
                    label: 'Beschreibung',
                    maxLines: 3,
                  ),
                  if (_error != null) Text(_error!),
                  const Spacer(),
                  AppButton(
                    label: _saving ? 'Speichern …' : 'Speichern',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}
