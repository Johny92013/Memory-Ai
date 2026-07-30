import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/features/upload/presentation/batch_metadata_editor.dart';
import 'package:memory_ai/features/upload/presentation/capture_date_editor.dart';
import 'package:memory_ai/features/upload/presentation/location_picker.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Prüft erkannte Metadaten vor dem Upload; unvollständige Daten erlaubt.
class UploadMetadataReviewScreen extends StatefulWidget {
  const UploadMetadataReviewScreen({
    super.key,
    required this.items,
    required this.onContinue,
  });

  final List<UploadQueueItem> items;
  final ValueChanged<List<UploadQueueItem>> onContinue;

  @override
  State<UploadMetadataReviewScreen> createState() =>
      _UploadMetadataReviewScreenState();
}

class _UploadMetadataReviewScreenState
    extends State<UploadMetadataReviewScreen> {
  late List<UploadQueueItem> _items;
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _items = List<UploadQueueItem>.from(widget.items);
  }

  Future<void> _editDate(UploadQueueItem item) async {
    final date = await CaptureDateEditor.show(
      context,
      initialDate: item.effectiveTakenAt(DateTime.now()),
    );
    if (date == null) return;
    _replace(item.copyWith(manualTakenAt: date, wasEdited: true));
  }

  Future<void> _editLocation(UploadQueueItem item) async {
    final loc = await LocationPicker.show(
      context,
      initialLatitude: item.effectiveLatitude,
      initialLongitude: item.effectiveLongitude,
    );
    if (loc == null) return;
    _replace(
      item.copyWith(
        manualLatitude: loc.latitude,
        manualLongitude: loc.longitude,
        manualLocationName: loc.locationName,
        removeGps: false,
        wasEdited: true,
      ),
    );
  }

  void _replace(UploadQueueItem updated) {
    final i = _items.indexWhere((e) => e.id == updated.id);
    if (i == -1) return;
    setState(() => _items[i] = updated);
  }

  void _openBatch() {
    BatchMetadataEditor.show(
      context,
      items: _items
          .where((i) => i.canUpload || i.status == UploadQueueStatus.ready)
          .toList(),
      onApply: (updated) {
        setState(() {
          for (final u in updated) {
            final i = _items.indexWhere((e) => e.id == u.id);
            if (i != -1) _items[i] = u;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomplete = _items.where((i) {
      final hasDate =
          i.manualTakenAt != null || i.exif.resolveTakenAt() != null;
      return !hasDate || !i.hasGps;
    }).length;

    return AppScaffold(
      title: 'Metadaten prüfen',
      body: Column(
        children: [
          if (incomplete > 0)
            Material(
              color: AppColors.surface,
              child: ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(
                  '$incomplete Medium/Medien ohne vollständige Daten – Upload trotzdem möglich.',
                ),
              ),
            ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = _items[index];
                final taken = item.effectiveTakenAt(DateTime.now());
                final hasAutoDate = item.exif.resolveTakenAt() != null;
                return Card(
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                          child: item.previewBytes != null
                              ? Image.memory(
                                  item.previewBytes!,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.backgroundSecondary,
                                  child: const Icon(Icons.image_outlined),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasAutoDate || item.manualTakenAt != null
                                    ? _dateFormat.format(taken)
                                    : 'Datum unbekannt',
                              ),
                              Text(item.displayLocationLabel),
                              Text(
                                'Status: ${item.metadataStatusLabel}',
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                children: [
                                  TextButton(
                                    onPressed: () => _editDate(item),
                                    child: const Text('Datum'),
                                  ),
                                  TextButton(
                                    onPressed: () => _editLocation(item),
                                    child: const Text('Standort'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _openBatch,
                  icon: const Icon(Icons.library_add_check_outlined),
                  label: const Text('Batch: Datum / Standort'),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Weiter zum Upload',
                  icon: Icons.check,
                  onPressed: () => widget.onContinue(_items),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
