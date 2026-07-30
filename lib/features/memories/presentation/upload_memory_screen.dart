import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/image_service.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/memories/data/memories_repository.dart';
import 'package:memory_ai/features/memories/data/memory_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';

/// Upload-Bildschirm für Familienfotos inkl. Fortschritt und Bestätigung.
class UploadMemoryScreen extends StatefulWidget {
  const UploadMemoryScreen({super.key, this.familyId});

  final String? familyId;

  @override
  State<UploadMemoryScreen> createState() => _UploadMemoryScreenState();
}

class _UploadMemoryScreenState extends State<UploadMemoryScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memoriesRepo = MemoriesRepository();
  final _familyRepo = FamilyRepository();

  XFile? _selectedFile;
  Uint8List? _previewBytes;
  String? _resolvedFamilyId;
  bool _loadingFamily = true;
  bool _uploading = false;
  double _progress = 0;
  String _progressLabel = '';
  String? _error;
  bool _canRetry = false;

  MemoryModel? _uploadedMemory;
  String? _confirmationUrl;

  @override
  void initState() {
    super.initState();
    _resolveFamilyId();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _resolveFamilyId() async {
    if (widget.familyId != null && widget.familyId!.isNotEmpty) {
      setState(() {
        _resolvedFamilyId = widget.familyId;
        _loadingFamily = false;
      });
      return;
    }

    try {
      final families = await _familyRepo.listMyFamilies();
      if (!mounted) return;
      setState(() {
        _resolvedFamilyId = families.isNotEmpty ? families.first.id : null;
        _loadingFamily = false;
        if (_resolvedFamilyId == null) {
          _error =
              'Keine Familie gefunden. Bitte tritt zuerst einer Familie bei.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingFamily = false;
        _error = ErrorMapper.map(error).message;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final file = await ImageService.pickFamilyImage();
      if (file == null || !mounted) return;

      final bytes = await file.readAsBytes();
      // Frühe Validierung für klare Fehlermeldung bei falschem Typ / >20 MB.
      final mime = ImageService.detectMimeType(file, bytes);
      ImageService.validateImageBytes(bytes, mime);

      setState(() {
        _selectedFile = file;
        _previewBytes = bytes;
        _error = null;
        _canRetry = false;
        _uploadedMemory = null;
        _confirmationUrl = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMapper.map(error).message;
        _canRetry = false;
      });
    }
  }

  Future<void> _upload() async {
    final familyId = _resolvedFamilyId;
    final file = _selectedFile;

    if (familyId == null) {
      setState(() => _error = 'Keine Familie ausgewählt.');
      return;
    }
    if (file == null) {
      setState(() => _error = 'Bitte wähle zuerst ein Foto aus.');
      return;
    }

    setState(() {
      _uploading = true;
      _error = null;
      _canRetry = false;
      _progress = 0;
      _progressLabel = 'Start …';
    });

    try {
      final memory = await _memoriesRepo.uploadFamilyPhoto(
        familyId: familyId,
        file: file,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        onProgress: (value, label) {
          if (!mounted) return;
          setState(() {
            _progress = value;
            _progressLabel = label;
          });
        },
      );

      final url = await SignedUrlService.familyImageUrl(memory.storagePath);
      if (!mounted) return;

      setState(() {
        _uploading = false;
        _uploadedMemory = memory;
        _confirmationUrl = url;
        _progress = 1;
        _progressLabel = 'Fertig';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = ErrorMapper.map(error).message;
        _canRetry = true;
      });
    }
  }

  void _resetForAnother() {
    setState(() {
      _selectedFile = null;
      _previewBytes = null;
      _uploadedMemory = null;
      _confirmationUrl = null;
      _titleController.clear();
      _descriptionController.clear();
      _progress = 0;
      _progressLabel = '';
      _error = null;
      _canRetry = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _uploadedMemory == null ? 'Erinnerung hinzufügen' : 'Hochgeladen',
      body: _loadingFamily
          ? const Center(child: CircularProgressIndicator())
          : _uploadedMemory != null
          ? _buildConfirmation(context)
          : _buildForm(context),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final memory = _uploadedMemory!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Dein Foto wurde gespeichert',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _confirmationUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _confirmationUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const ColoredBox(
                        color: AppColors.card,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (_, _, _) => const ColoredBox(
                        color: AppColors.card,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : const ColoredBox(
                      color: AppColors.card,
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          if (memory.title != null && memory.title!.isNotEmpty)
            Text(
              memory.title!,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
            ),
          if (memory.takenAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Aufnahme: ${DateFormatter.formatDateTime(memory.takenAt!)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (memory.latitude != null && memory.longitude != null) ...[
            const SizedBox(height: 4),
            Text(
              'GPS: ${memory.latitude!.toStringAsFixed(5)}, '
              '${memory.longitude!.toStringAsFixed(5)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Keine GPS-Daten in diesem Foto gefunden.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 28),
          AppButton(
            label: 'Weiteres Foto hochladen',
            icon: Icons.add_a_photo_outlined,
            onPressed: _resetForAnother,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop(true);
              } else {
                context.go('/home');
              }
            },
            child: const Text('Fertig'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.accentPink,
                    ),
                  ),
                  if (_canRetry) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _uploading ? null : _upload,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: _uploading ? null : _pickImage,
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                ),
                child: _previewBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(_previewBytes!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_a_photo_outlined,
                            size: 48,
                            color: AppColors.turquoise,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Foto auswählen',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'JPEG, PNG, WebP, HEIC · wird auf ca. 2 MB optimiert',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _titleController,
            label: 'Titel (optional)',
            hint: 'z. B. Sommerurlaub 2025',
            textCapitalization: TextCapitalization.sentences,
            enabled: !_uploading,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _descriptionController,
            label: 'Beschreibung (optional)',
            hint: 'Was macht diese Erinnerung besonders?',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            enabled: !_uploading,
          ),
          if (_uploading) ...[
            const SizedBox(height: 24),
            LinearProgressIndicator(
              value: _progress.clamp(0.0, 1.0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).round()} % · $_progressLabel',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          AppButton(
            label: _canRetry ? 'Erneut hochladen' : 'Hochladen',
            icon: Icons.cloud_upload_outlined,
            isLoading: _uploading,
            onPressed:
                _resolvedFamilyId != null &&
                    _selectedFile != null &&
                    !_uploading
                ? _upload
                : null,
          ),
        ],
      ),
    );
  }
}
