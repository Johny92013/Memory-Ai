import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/features/upload/data/batch_metadata_ops.dart';
import 'package:memory_ai/features/upload/presentation/capture_date_editor.dart';
import 'package:memory_ai/features/upload/presentation/location_picker.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

/// Batch-Editor: Datum/Standort auf mehrere Upload-Einträge anwenden.
class BatchMetadataEditor extends StatefulWidget {
  const BatchMetadataEditor({
    super.key,
    required this.items,
    required this.onApply,
  });

  final List<UploadQueueItem> items;
  final ValueChanged<List<UploadQueueItem>> onApply;

  static Future<void> show(
    BuildContext context, {
    required List<UploadQueueItem> items,
    required ValueChanged<List<UploadQueueItem>> onApply,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => BatchMetadataEditor(items: items, onApply: onApply),
    );
  }

  @override
  State<BatchMetadataEditor> createState() => _BatchMetadataEditorState();
}

class _BatchMetadataEditorState extends State<BatchMetadataEditor> {
  late final Set<String> _selected;
  DateTime? _date;
  PickedLocation? _location;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.map((e) => e.id).toSet();
  }

  void _toggle(String id) {
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
      } else {
        _selected.add(id);
      }
    });
  }

  Future<void> _pickDate() async {
    final date = await CaptureDateEditor.show(
      context,
      initialDate: _date ?? DateTime.now(),
    );
    if (date != null) setState(() => _date = date);
  }

  Future<void> _pickLocation() async {
    final loc = await LocationPicker.show(context);
    if (loc != null) setState(() => _location = loc);
  }

  void _apply() {
    var items = List<UploadQueueItem>.from(widget.items);
    if (_date != null) {
      items = BatchMetadataOps.applyDateToItems(
        items: items,
        itemIds: _selected,
        idOf: (i) => i.id,
        date: _date!,
        update: (item, date) =>
            item.copyWith(manualTakenAt: date, wasEdited: true),
      );
    }
    if (_location != null) {
      items = BatchMetadataOps.applyLocationToItems(
        items: items,
        itemIds: _selected,
        idOf: (i) => i.id,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        locationName: _location!.locationName,
        update: (item, {required latitude, required longitude, locationName}) {
          return item.copyWith(
            manualLatitude: latitude,
            manualLongitude: longitude,
            manualLocationName: locationName,
            removeGps: false,
            wasEdited: true,
          );
        },
      );
    }
    widget.onApply(items);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Mehrere Medien bearbeiten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView(
                shrinkWrap: true,
                children: widget.items.map((item) {
                  return CheckboxListTile(
                    value: _selected.contains(item.id),
                    onChanged: (_) => _toggle(item.id),
                    title: Text(
                      item.title ?? item.file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                _date == null
                    ? 'Datum setzen'
                    : _date!.toLocal().toString().substring(0, 16),
              ),
              onTap: _pickDate,
            ),
            ListTile(
              leading: const Icon(Icons.place_outlined),
              title: Text(_location?.locationName ?? 'Standort setzen'),
              onTap: _pickLocation,
            ),
            AppButton(
              label: 'Auf Auswahl anwenden',
              onPressed:
                  _selected.isEmpty || (_date == null && _location == null)
                  ? null
                  : _apply,
            ),
          ],
        ),
      ),
    );
  }
}
