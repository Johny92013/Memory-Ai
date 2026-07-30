import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/features/memories/data/exif_metadata_service.dart';
import 'package:memory_ai/features/memories/data/metadata_status_helper.dart';

/// Status einer Datei in der Upload-Warteschlange.
enum UploadQueueStatus {
  waiting,
  readingMetadata,
  ready,
  uploading,
  saving,
  completed,
  failed,
}

/// Ein Eintrag in der Mehrfach-Upload-Warteschlange.
class UploadQueueItem {
  UploadQueueItem({
    required this.id,
    required this.file,
    this.previewBytes,
    this.exif = const PhotoExifMetadata(),
    this.status = UploadQueueStatus.waiting,
    this.progress = 0,
    this.errorMessage,
    this.manualTakenAt,
    this.manualLatitude,
    this.manualLongitude,
    this.manualLocationName,
    this.title,
    this.description,
    this.removeGps = false,
    this.wasEdited = false,
    this.uploadedMediaId,
  });

  final String id;
  final XFile file;
  Uint8List? previewBytes;
  PhotoExifMetadata exif;
  UploadQueueStatus status;
  double progress;
  String? errorMessage;
  DateTime? manualTakenAt;
  double? manualLatitude;
  double? manualLongitude;
  String? manualLocationName;
  String? title;
  String? description;
  bool removeGps;
  bool wasEdited;
  String? uploadedMediaId;

  bool get isCompleted => status == UploadQueueStatus.completed;
  bool get isFailed => status == UploadQueueStatus.failed;
  bool get canRetry => isFailed;
  bool get canUpload =>
      status == UploadQueueStatus.ready && uploadedMediaId == null;

  bool get hasManualGps =>
      !removeGps && manualLatitude != null && manualLongitude != null;

  bool get hasGps =>
      hasManualGps ||
      (!removeGps && exif.latitude != null && exif.longitude != null);

  double? get effectiveLatitude =>
      removeGps ? null : (manualLatitude ?? exif.latitude);

  double? get effectiveLongitude =>
      removeGps ? null : (manualLongitude ?? exif.longitude);

  DateTime effectiveTakenAt(DateTime fallback) {
    if (manualTakenAt != null) return manualTakenAt!;
    return exif.resolveTakenAt() ?? fallback;
  }

  String get metadataStatusLabel {
    if (wasEdited || manualTakenAt != null || hasManualGps) {
      return MetadataStatusHelper.compute(
        hasDate: true,
        hasLocation: hasGps,
        manualOverride: true,
      );
    }
    return MetadataStatusHelper.compute(
      hasDate: exif.resolveTakenAt() != null,
      hasLocation: hasGps,
    );
  }

  String get dateSourceLabel {
    if (manualTakenAt != null) return 'manual';
    return exif.resolveDateSource();
  }

  String get locationSourceLabel {
    if (removeGps) return 'unknown';
    if (hasManualGps) return 'manual';
    return exif.resolveLocationSource();
  }

  String get displayLocationLabel {
    if (manualLocationName != null && manualLocationName!.trim().isNotEmpty) {
      return manualLocationName!.trim();
    }
    if (hasGps) {
      return '${effectiveLatitude!.toStringAsFixed(4)}, '
          '${effectiveLongitude!.toStringAsFixed(4)}';
    }
    return 'Kein Standort';
  }

  UploadQueueItem copyWith({
    Uint8List? previewBytes,
    PhotoExifMetadata? exif,
    UploadQueueStatus? status,
    double? progress,
    String? errorMessage,
    DateTime? manualTakenAt,
    double? manualLatitude,
    double? manualLongitude,
    String? manualLocationName,
    String? title,
    String? description,
    bool? removeGps,
    bool? wasEdited,
    String? uploadedMediaId,
    bool clearError = false,
    bool clearManualLocation = false,
    bool clearManualDate = false,
  }) {
    return UploadQueueItem(
      id: id,
      file: file,
      previewBytes: previewBytes ?? this.previewBytes,
      exif: exif ?? this.exif,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      manualTakenAt: clearManualDate
          ? null
          : (manualTakenAt ?? this.manualTakenAt),
      manualLatitude: clearManualLocation
          ? null
          : (manualLatitude ?? this.manualLatitude),
      manualLongitude: clearManualLocation
          ? null
          : (manualLongitude ?? this.manualLongitude),
      manualLocationName: clearManualLocation
          ? null
          : (manualLocationName ?? this.manualLocationName),
      title: title ?? this.title,
      description: description ?? this.description,
      removeGps: removeGps ?? this.removeGps,
      wasEdited: wasEdited ?? this.wasEdited,
      uploadedMediaId: uploadedMediaId ?? this.uploadedMediaId,
    );
  }
}
