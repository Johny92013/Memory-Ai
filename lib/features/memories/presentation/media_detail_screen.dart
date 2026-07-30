import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/location_service.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/map/data/media_location_enrichment_service.dart';
import 'package:memory_ai/features/memories/data/face_crop_helper.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_model.dart';
import 'package:memory_ai/features/memories/data/media_face_detection_repository.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/memories/data/metadata_status_helper.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/features/memories/presentation/family_media_section.dart';
import 'package:memory_ai/features/memories/presentation/related_media_suggestions.dart';
import 'package:memory_ai/features/people/presentation/media_people_editor.dart';
import 'package:memory_ai/features/people/presentation/person_picker.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_repository.dart';
import 'package:memory_ai/features/upload/presentation/capture_date_editor.dart';
import 'package:memory_ai/features/upload/presentation/location_picker.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Medien-Detail: Aufnahmedaten, Personen, verwandte Medien.
class MediaDetailScreen extends StatefulWidget {
  const MediaDetailScreen({super.key, required this.mediaId});

  final String mediaId;

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  final _mediaRepo = MediaRepository();
  final _faceRepo = MediaFaceDetectionRepository();
  final _peopleRepo = PeopleRepository();
  final _consentRepo = BiometricConsentRepository();
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');

  MediaItemModel? _item;
  List<MediaFaceDetectionModel> _faces = [];
  List<PersonModel> _taggedPeople = [];
  List<PersonModel> _suggestedPeople = [];
  Uint8List? _imageBytes;
  bool _hasConsent = false;
  bool _loading = true;
  String? _error;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final item = await _mediaRepo.getAccessibleMediaItem(widget.mediaId);
      if (item == null) {
        setState(() {
          _loading = false;
          _error = 'Foto nicht gefunden.';
        });
        return;
      }

      final consent = await _consentRepo.hasFaceRecognitionConsent(
        item.ownerId,
      );
      var faces = <MediaFaceDetectionModel>[];
      if (consent) {
        faces = await _faceRepo.listForMedia(widget.mediaId);
      }
      final tagged = await _peopleRepo.listPeopleForMedia(widget.mediaId);
      final suggested = await _peopleRepo.listPeopleForMedia(
        widget.mediaId,
        status: 'suggested',
      );

      Uint8List? bytes;
      final url = await SignedUrlService.mediaPhotoUrl(item.storagePath);
      if (url != null && (consent && faces.isNotEmpty)) {
        bytes = await FaceCropHelper.loadImageBytes(url);
      }

      if (!mounted) return;
      setState(() {
        _item = item;
        _hasConsent = consent;
        _faces = faces;
        _taggedPeople = tagged;
        _suggestedPeople = suggested;
        _imageBytes = bytes;
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

  Future<void> _assignFace(MediaFaceDetectionModel face) async {
    final people = await PersonPicker.show(context, familyId: _item?.familyId);
    if (people == null || people.isEmpty || !mounted) return;
    final person = people.first;
    try {
      await _faceRepo.linkPerson(detectionId: face.id, personId: person.id);
      await _peopleRepo.assignPersonToMedia(
        mediaId: widget.mediaId,
        personId: person.id,
        source: 'manual',
      );
      MediaChangeNotifier.instance.notifyMediaChanged();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _editDate() async {
    final item = _item;
    if (item == null) return;
    final date = await CaptureDateEditor.show(
      context,
      initialDate: item.takenAt ?? DateTime.now(),
    );
    if (date == null) return;
    try {
      await _mediaRepo.updateCaptureMetadata(
        mediaId: item.id,
        takenAt: date,
        dateSource: 'manual',
        metadataStatus: MetadataStatusHelper.compute(
          hasDate: true,
          hasLocation: item.hasGps,
          manualOverride: true,
        ),
      );
      MediaChangeNotifier.instance.notifyMediaChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _editLocation() async {
    final item = _item;
    if (item == null) return;
    final loc = await LocationPicker.show(
      context,
      initialLatitude: item.latitude,
      initialLongitude: item.longitude,
    );
    if (loc == null) return;
    try {
      await MediaLocationEnrichmentService().updateManualLocation(
        mediaId: item.id,
        latitude: loc.latitude,
        longitude: loc.longitude,
        locationName: loc.locationName,
      );
      await _mediaRepo.updateCaptureMetadata(
        mediaId: item.id,
        metadataStatus: MetadataStatusHelper.compute(
          hasDate: item.takenAt != null,
          hasLocation: true,
          manualOverride: true,
        ),
      );
      MediaChangeNotifier.instance.notifyMediaChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _clearLocation() async {
    final item = _item;
    if (item == null) return;
    try {
      await _mediaRepo.clearLocation(item.id);
      await _mediaRepo.updateCaptureMetadata(
        mediaId: item.id,
        metadataStatus: MetadataStatusHelper.compute(
          hasDate: item.takenAt != null,
          hasLocation: false,
          manualOverride: true,
        ),
      );
      MediaChangeNotifier.instance.notifyMediaChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _regeocode() async {
    final item = _item;
    if (item == null || !item.hasGps) return;
    try {
      final place = await LocationService().resolveCoordinates(
        item.latitude!,
        item.longitude!,
      );
      if (place == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Geocoding ohne Ergebnis.')),
        );
        return;
      }
      await _mediaRepo.updateLocationFromPlace(mediaId: item.id, place: place);
      MediaChangeNotifier.instance.notifyMediaChanged();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _item?.title?.isNotEmpty == true ? _item!.title! : 'Foto',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _item == null
          ? const SizedBox.shrink()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accentWarm,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.photo),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: FutureBuilder<String?>(
                        future: SignedUrlService.mediaPhotoUrl(
                          _item!.storagePath,
                        ),
                        builder: (context, snap) {
                          final url = snap.data;
                          if (url == null) {
                            return Container(color: AppColors.surface);
                          }
                          return CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _CaptureDataSection(
                    item: _item!,
                    dateFormat: _dateFormat,
                    onEditDate: _editDate,
                    onEditLocation: _editLocation,
                    onClearLocation: _clearLocation,
                    onRegeocode: _regeocode,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MediaPeopleEditor(
                    mediaId: widget.mediaId,
                    people: _taggedPeople,
                    suggestions: _suggestedPeople,
                    familyId: _item!.familyId,
                    onChanged: () {
                      MediaChangeNotifier.instance.notifyMediaChanged();
                    },
                  ),
                  if (_hasConsent) ...[
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      'Erkannte Gesichter',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (_faces.isEmpty)
                      Text(
                        'Keine Gesichter erkannt.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      )
                    else
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _faces.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final face = _faces[index];
                            final crop = _imageBytes == null
                                ? null
                                : FaceCropHelper.cropRelative(
                                    imageBytes: _imageBytes!,
                                    box: face.boundingBox,
                                  );
                            return InkWell(
                              onTap: () => _assignFace(face),
                              borderRadius: BorderRadius.circular(
                                AppRadius.chip,
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.chip,
                                    ),
                                    child: SizedBox(
                                      width: 72,
                                      height: 72,
                                      child: crop != null
                                          ? Image.memory(
                                              crop,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: AppColors.surface,
                                              child: const Icon(
                                                Icons.face_outlined,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    face.isLinked ? 'Zugeordnet' : 'Zuordnen',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  RelatedMediaSuggestions(
                    mediaId: widget.mediaId,
                    familyId: _item!.familyId,
                  ),
                  if (_item!.familyId != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    FamilyMediaSection(
                      familyId: _item!.familyId!,
                      excludeMediaId: widget.mediaId,
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _CaptureDataSection extends StatelessWidget {
  const _CaptureDataSection({
    required this.item,
    required this.dateFormat,
    required this.onEditDate,
    required this.onEditLocation,
    required this.onClearLocation,
    required this.onRegeocode,
  });

  final MediaItemModel item;
  final DateFormat dateFormat;
  final VoidCallback onEditDate;
  final VoidCallback onEditLocation;
  final VoidCallback onClearLocation;
  final VoidCallback onRegeocode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Aufnahmedaten', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _row(
          context,
          'Datum / Uhrzeit',
          item.takenAt != null
              ? dateFormat.format(item.takenAt!.toLocal())
              : 'unbekannt',
        ),
        _row(context, 'Standort', item.locationName ?? '—'),
        _row(context, 'Stadt', item.city ?? '—'),
        _row(context, 'Land', item.countryName ?? '—'),
        _row(context, 'Kontinent', item.continent ?? '—'),
        _row(context, 'date_source', item.dateSource),
        _row(context, 'location_source', item.locationSource),
        _row(context, 'metadata_status', item.metadataStatus),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton(
              onPressed: onEditDate,
              child: const Text('Datum ändern'),
            ),
            OutlinedButton(
              onPressed: onEditLocation,
              child: const Text('Standort ändern'),
            ),
            if (item.hasGps)
              OutlinedButton(
                onPressed: onClearLocation,
                child: const Text('Standort entfernen'),
              ),
            if (item.hasGps)
              OutlinedButton(
                onPressed: onRegeocode,
                child: const Text('Erneut geocodieren'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
