import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _repo = TripRepository();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _start;
  DateTime? _end;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Bitte einen Titel eingeben.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final trip = await _repo.createTrip(
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        startDate: _start,
        endDate: _end,
        status: 'planning',
      );
      if (!mounted) return;
      context.pushReplacement('/trips/${trip.id}');
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
      title: 'Reise erstellen',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(controller: _titleController, label: 'Titel'),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descController,
              label: 'Beschreibung (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            ListTile(
              title: const Text('Startdatum'),
              subtitle: Text(
                _start?.toString().split(' ').first ?? 'Auswählen',
              ),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _start = d);
              },
            ),
            ListTile(
              title: const Text('Enddatum'),
              subtitle: Text(_end?.toString().split(' ').first ?? 'Auswählen'),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _start ?? DateTime.now(),
                  firstDate: DateTime(1970),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (d != null) setState(() => _end = d);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            AppButton(
              label: _saving ? 'Speichern …' : 'Reise erstellen',
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
