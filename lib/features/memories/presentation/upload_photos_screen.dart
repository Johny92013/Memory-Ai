import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/services/image_service.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/data/upload_queue_model.dart';
import 'package:memory_ai/features/upload/presentation/upload_metadata_review_screen.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:uuid/uuid.dart';

/// Mehrfach-Foto-Upload mit Warteschlange und Metadaten-Prüfung.
class UploadPhotosScreen extends StatefulWidget {
  const UploadPhotosScreen({super.key, this.tripId, this.familyId});

  final String? tripId;
  final String? familyId;

  @override
  State<UploadPhotosScreen> createState() => _UploadPhotosScreenState();
}

class _UploadPhotosScreenState extends State<UploadPhotosScreen> {
  final _repo = MediaRepository();
  final _items = <UploadQueueItem>[];
  bool _uploading = false;
  double _overallProgress = 0;
  String? _globalError;

  Future<void> _pickPhotos() async {
    try {
      final files = await ImageService.pickMultipleImages(limit: 20);
      if (files.isEmpty) return;

      for (final file in files) {
        final item = UploadQueueItem(
          id: const Uuid().v4(),
          file: file,
          status: UploadQueueStatus.readingMetadata,
        );
        _items.add(item);
      }
      setState(() {});

      for (final item in _items.where(
        (i) => i.status == UploadQueueStatus.readingMetadata,
      )) {
        await _readMetadata(item);
      }

      if (!mounted) return;
      final ready = _items
          .where((i) => i.status == UploadQueueStatus.ready)
          .toList();
      if (ready.isNotEmpty) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => UploadMetadataReviewScreen(
              items: ready,
              onContinue: (updated) {
                for (final u in updated) {
                  final idx = _items.indexWhere((e) => e.id == u.id);
                  if (idx != -1) _items[idx] = u;
                }
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ),
        );
      }
    } catch (_) {
      setState(() {
        _globalError = 'Das Foto konnte nicht ausgewählt werden.';
      });
    }
  }

  Future<void> _readMetadata(UploadQueueItem item) async {
    try {
      final bytes = await item.file.readAsBytes();
      final exif = await MediaRepository.readExif(item.file);
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index == -1) return;
      _items[index] = item.copyWith(
        previewBytes: Uint8List.fromList(bytes),
        exif: exif,
        status: UploadQueueStatus.ready,
        clearError: true,
      );
      if (mounted) setState(() {});
    } catch (_) {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index == -1) return;
      _items[index] = item.copyWith(
        status: UploadQueueStatus.failed,
        errorMessage: 'Metadaten konnten nicht gelesen werden.',
      );
      if (mounted) setState(() {});
    }
  }

  void _openMetadata(UploadQueueItem item) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => UploadMetadataReviewScreen(
          items: [item],
          onContinue: (updated) {
            for (final u in updated) {
              final index = _items.indexWhere((i) => i.id == u.id);
              if (index != -1) _items[index] = u;
            }
            Navigator.pop(context);
            setState(() {});
          },
        ),
      ),
    );
  }

  Future<void> _uploadAll() async {
    final pending = _items.where((i) => i.canUpload).toList();
    if (pending.isEmpty) return;

    setState(() {
      _uploading = true;
      _globalError = null;
      _overallProgress = 0;
    });

    var completed = 0;
    final total = pending.length;
    var hadFailure = false;

    for (final item in pending) {
      final index = _items.indexWhere((i) => i.id == item.id);
      if (index == -1) continue;

      _items[index] = item.copyWith(
        status: UploadQueueStatus.uploading,
        progress: 0,
        clearError: true,
      );
      setState(() {});

      try {
        final result = await _repo.uploadPhoto(
          item: _items[index],
          tripId: widget.tripId,
          familyId: widget.familyId,
          onProgress: (p, _) {
            if (!mounted) return;
            _items[index] = _items[index].copyWith(
              progress: p,
              status: p < 1
                  ? UploadQueueStatus.uploading
                  : UploadQueueStatus.saving,
            );
            setState(() {
              _overallProgress = (completed + p) / total;
            });
          },
        );
        _items[index] = _items[index].copyWith(
          status: UploadQueueStatus.completed,
          progress: 1,
          uploadedMediaId: result.id,
        );
        completed++;
        MediaChangeNotifier.instance.notifyMediaChanged();
      } on AppException catch (e) {
        hadFailure = true;
        _items[index] = _items[index].copyWith(
          status: UploadQueueStatus.failed,
          errorMessage: e.message,
        );
      } catch (_) {
        hadFailure = true;
        _items[index] = _items[index].copyWith(
          status: UploadQueueStatus.failed,
          errorMessage: 'Einige Fotos konnten nicht hochgeladen werden.',
        );
      }

      if (mounted) {
        setState(() {
          _overallProgress = completed / total;
        });
      }
    }

    if (mounted) {
      setState(() {
        _uploading = false;
        if (hadFailure) {
          _globalError = 'Einige Fotos konnten nicht hochgeladen werden.';
        }
      });
    }
  }

  Widget _statusIcon(UploadQueueStatus status) {
    switch (status) {
      case UploadQueueStatus.completed:
        return const Icon(Icons.check_circle, color: AppColors.accentCool);
      case UploadQueueStatus.failed:
        return const Icon(Icons.error_outline, color: AppColors.error);
      case UploadQueueStatus.uploading:
      case UploadQueueStatus.saving:
        return const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case UploadQueueStatus.readingMetadata:
        return const Icon(Icons.hourglass_top, color: AppColors.textSecondary);
      default:
        return const Icon(Icons.photo_outlined, color: AppColors.textSecondary);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUpload = _items.any((i) => i.canUpload) && !_uploading;
    final allDone =
        _items.isNotEmpty && _items.every((i) => i.isCompleted || i.isFailed);

    return AppScaffold(
      title: 'Fotos hochladen',
      body: Column(
        children: [
          if (_uploading)
            LinearProgressIndicator(
              value: _overallProgress > 0 ? _overallProgress : null,
              color: AppColors.accentWarm,
              backgroundColor: AppColors.surface,
              minHeight: 3,
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                if (_globalError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _globalError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                if (_items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxxl,
                      ),
                      child: Text(
                        'Wähle Fotos aus deiner Galerie.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ..._items.map((item) {
                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      leading: item.previewBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                              child: Image.memory(
                                item.previewBytes!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                            )
                          : _statusIcon(item.status),
                      title: Text(
                        item.title?.isNotEmpty == true
                            ? item.title!
                            : item.file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        item.errorMessage ??
                            item.status.name.replaceAll('_', ' '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.canRetry)
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _uploading
                                  ? null
                                  : () {
                                      final idx = _items.indexWhere(
                                        (i) => i.id == item.id,
                                      );
                                      if (idx != -1) {
                                        _items[idx] = item.copyWith(
                                          status: UploadQueueStatus.ready,
                                          clearError: true,
                                        );
                                        setState(() {});
                                      }
                                    },
                            ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: _uploading
                                ? null
                                : () => _openMetadata(item),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'Fotos auswählen',
                  icon: Icons.photo_library_outlined,
                  onPressed: _uploading ? null : _pickPhotos,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Hochladen',
                  icon: Icons.cloud_upload_outlined,
                  onPressed: canUpload ? _uploadAll : null,
                  isLoading: _uploading,
                ),
                if (allDone && _items.any((i) => i.isCompleted)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'Zur Galerie',
                    onPressed: () => context.go('/media/gallery'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
