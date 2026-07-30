import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:memory_ai/features/memories/data/metadata_status_helper.dart';
import 'package:memory_ai/features/upload/services/mp4_metadata_reader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Extrahierte Video-Metadaten (Datum, GPS, Dauer, Auflösung, Thumbnail).
class VideoMetadata {
  const VideoMetadata({
    this.takenAt,
    this.dateSource = 'unknown',
    this.latitude,
    this.longitude,
    this.locationSource = 'unknown',
    this.durationSeconds,
    this.width,
    this.height,
    this.orientation,
    this.thumbnailJpeg,
  });

  final DateTime? takenAt;
  final String dateSource;
  final double? latitude;
  final double? longitude;
  final String locationSource;
  final int? durationSeconds;
  final int? width;
  final int? height;
  final int? orientation;
  final Uint8List? thumbnailJpeg;

  bool get hasGps => latitude != null && longitude != null;

  String get metadataStatus => MetadataStatusHelper.compute(
    hasDate: takenAt != null,
    hasLocation: hasGps,
  );
}

/// Liest Video-Container-Metadaten und erzeugt ein JPEG-Thumbnail.
/// Fehlende Metadaten sind kein Fehler – Upload darf fortgesetzt werden.
class VideoMetadataExtractor {
  VideoMetadataExtractor({
    Future<Uint8List?> Function(String videoPath)? thumbnailGenerator,
  }) : _thumbnailGenerator = thumbnailGenerator ?? _defaultThumbnail;

  final Future<Uint8List?> Function(String videoPath) _thumbnailGenerator;

  /// Max. Bytes, die für Atom-Parsing gelesen werden (moov oft am Ende →
  /// bei Pfad zusätzlich Tail lesen).
  static const int prefixScanBytes = 2 * 1024 * 1024;
  static const int tailScanBytes = 2 * 1024 * 1024;

  Future<VideoMetadata> extract({
    String? filePath,
    Uint8List? bytes,
    DateTime? fileLastModified,
  }) async {
    try {
      final container = await _readContainer(filePath: filePath, bytes: bytes);

      DateTime? takenAt = container.creationTime;
      var dateSource = takenAt != null ? 'video_metadata' : 'unknown';
      if (takenAt == null && fileLastModified != null) {
        takenAt = fileLastModified;
        dateSource = 'file';
      }

      final hasGps = container.latitude != null && container.longitude != null;

      Uint8List? thumb;
      final pathForThumb = filePath ?? await _materializeTempFile(bytes);
      if (pathForThumb != null) {
        try {
          thumb = await _thumbnailGenerator(pathForThumb);
        } catch (_) {
          thumb = null;
        } finally {
          if (filePath == null) {
            try {
              await File(pathForThumb).delete();
            } catch (_) {}
          }
        }
      } else if (bytes != null) {
        // Ohne Dateipfad (z. B. Tests/Web): Generator optional aufrufen
        try {
          thumb = await _thumbnailGenerator('');
        } catch (_) {
          thumb = null;
        }
      }

      return VideoMetadata(
        takenAt: takenAt,
        dateSource: dateSource,
        latitude: hasGps ? container.latitude : null,
        longitude: hasGps ? container.longitude : null,
        locationSource: hasGps ? 'video_metadata' : 'unknown',
        durationSeconds: container.durationSeconds,
        width: container.width,
        height: container.height,
        orientation: null,
        thumbnailJpeg: thumb,
      );
    } catch (_) {
      return VideoMetadata(
        takenAt: fileLastModified,
        dateSource: fileLastModified != null ? 'file' : 'unknown',
      );
    }
  }

  Future<Mp4ContainerMetadata> _readContainer({
    String? filePath,
    Uint8List? bytes,
  }) async {
    if (filePath != null && !kIsWeb) {
      return _parseFromPath(filePath);
    }
    if (bytes != null) {
      // Bei In-Memory-Upload: Prefix + ggf. Tail des Buffers scannen
      final prefixLen = bytes.length < prefixScanBytes
          ? bytes.length
          : prefixScanBytes;
      var meta = Mp4MetadataReader.parse(bytes.sublist(0, prefixLen));
      if (_isIncomplete(meta) && bytes.length > prefixScanBytes) {
        final tailStart = (bytes.length - tailScanBytes).clamp(0, bytes.length);
        final tailMeta = Mp4MetadataReader.parse(bytes.sublist(tailStart));
        meta = _merge(meta, tailMeta);
      } else if (_isIncomplete(meta) && bytes.length <= prefixScanBytes) {
        meta = Mp4MetadataReader.parse(bytes);
      }
      return meta;
    }
    return Mp4ContainerMetadata();
  }

  Future<Mp4ContainerMetadata> _parseFromPath(String path) async {
    final file = File(path);
    final length = await file.length();
    final raf = await file.open();
    try {
      final prefixLen = length < prefixScanBytes ? length : prefixScanBytes;
      final prefix = await raf.read(prefixLen);
      var meta = Mp4MetadataReader.parse(prefix);

      if (_isIncomplete(meta) && length > prefixScanBytes) {
        final tailLen = length < tailScanBytes ? length : tailScanBytes;
        await raf.setPosition(length - tailLen);
        final tail = await raf.read(tailLen);
        meta = _merge(meta, Mp4MetadataReader.parse(tail));
      }
      return meta;
    } finally {
      await raf.close();
    }
  }

  bool _isIncomplete(Mp4ContainerMetadata m) =>
      m.creationTime == null || m.durationSeconds == null || m.width == null;

  Mp4ContainerMetadata _merge(Mp4ContainerMetadata a, Mp4ContainerMetadata b) {
    return Mp4ContainerMetadata()
      ..creationTime = a.creationTime ?? b.creationTime
      ..durationSeconds = a.durationSeconds ?? b.durationSeconds
      ..width = a.width ?? b.width
      ..height = a.height ?? b.height
      ..latitude = a.latitude ?? b.latitude
      ..longitude = a.longitude ?? b.longitude;
  }

  Future<String?> _materializeTempFile(Uint8List? bytes) async {
    if (bytes == null || kIsWeb) return null;
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        p.join(
          dir.path,
          'vid_meta_${DateTime.now().microsecondsSinceEpoch}.mp4',
        ),
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _defaultThumbnail(String videoPath) async {
    if (kIsWeb) return null;
    try {
      final path = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        quality: 75,
      );
      if (path == null) return null;
      final bytes = await File(path).readAsBytes();
      try {
        await File(path).delete();
      } catch (_) {}
      return bytes;
    } catch (_) {
      return null;
    }
  }
}
