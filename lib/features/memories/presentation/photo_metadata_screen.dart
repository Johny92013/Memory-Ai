import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/app/theme_extensions.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';

/// Metadaten eines Fotos vor dem Upload bearbeiten.
class PhotoMetadataScreen extends StatefulWidget {
  const PhotoMetadataScreen({
    super.key,
    required this.item,
    required this.onSave,
  });

  final UploadQueueItem item;
  final ValueChanged<UploadQueueItem> onSave;

  @override
  State<PhotoMetadataScreen> createState() => _PhotoMetadataScreenState();
}

class _PhotoMetadataScreenState extends State<PhotoMetadataScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  bool _removeGps = false;
  bool _noExifGps = false;

  @override
  void initState() {
    super.initState();
    final taken = widget.item.effectiveTakenAt(DateTime.now());
    _selectedDate = DateTime(taken.year, taken.month, taken.day);
    _selectedTime = TimeOfDay.fromDateTime(taken);
    _titleController = TextEditingController(text: widget.item.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.item.description ?? '',
    );
    _latController = TextEditingController(
      text: widget.item.exif.latitude?.toStringAsFixed(6) ?? '',
    );
    _lonController = TextEditingController(
      text: widget.item.exif.longitude?.toStringAsFixed(6) ?? '',
    );
    _removeGps = widget.item.removeGps;
    _noExifGps = !widget.item.exif.hasGps;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1970),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _save() {
    final manualTakenAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    double? lat = double.tryParse(_latController.text.trim());
    double? lon = double.tryParse(_lonController.text.trim());

    var exif = widget.item.exif;
    if (_removeGps) {
      lat = null;
      lon = null;
      exif = exif.copyWith(clearLatitude: true, clearLongitude: true);
    } else if (lat != null && lon != null) {
      exif = exif.copyWith(latitude: lat, longitude: lon);
    }

    final updated = widget.item.copyWith(
      manualTakenAt: manualTakenAt,
      title: _titleController.text,
      description: _descriptionController.text,
      removeGps: _removeGps,
      exif: exif,
      wasEdited: true,
      status: UploadQueueStatus.ready,
    );
    widget.onSave(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Foto-Metadaten',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          if (widget.item.previewBytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.photo),
              child: Image.memory(
                widget.item.previewBytes!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          if (_noExifGps) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.accentCool),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Dieses Foto enthält keine Standortdaten.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            title: const Text('Datum'),
            subtitle: Text(
              DateFormatter.formatShortDate(_selectedDate),
              style: context.appTheme.statsMono.copyWith(fontSize: 13),
            ),
            trailing: const Icon(Icons.calendar_today_outlined),
            onTap: _pickDate,
          ),
          const SizedBox(height: AppSpacing.sm),
          ListTile(
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            title: const Text('Uhrzeit'),
            subtitle: Text(
              DateFormatter.formatTime(
                DateTime(2000, 1, 1, _selectedTime.hour, _selectedTime.minute),
              ),
              style: context.appTheme.statsMono.copyWith(fontSize: 13),
            ),
            trailing: const Icon(Icons.access_time),
            onTap: _pickTime,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _titleController,
            label: 'Titel (optional)',
            prefixIcon: Icons.title,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _descriptionController,
            label: 'Beschreibung (optional)',
            prefixIcon: Icons.notes_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _latController,
            label: 'GPS Breite',
            prefixIcon: Icons.location_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            enabled: !_removeGps,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _lonController,
            label: 'GPS Länge',
            prefixIcon: Icons.location_on_outlined,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            enabled: !_removeGps,
          ),
          CheckboxListTile(
            value: _removeGps,
            onChanged: (v) => setState(() => _removeGps = v ?? false),
            title: const Text('GPS-Daten entfernen'),
            tileColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: 'Speichern', onPressed: _save),
        ],
      ),
    );
  }
}
