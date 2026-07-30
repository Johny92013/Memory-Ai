/// Relative Bounding Box (0–1) bezogen auf die Originalbildgröße.
class FaceBoundingBox {
  const FaceBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
  };

  factory FaceBoundingBox.fromJson(Map<String, dynamic> json) {
    return FaceBoundingBox(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }
}

/// Eintrag in `public.media_face_detections`.
class MediaFaceDetectionModel {
  const MediaFaceDetectionModel({
    required this.id,
    required this.mediaId,
    required this.ownerId,
    required this.boundingBox,
    this.confidence,
    this.detectedAt,
    this.linkedPersonId,
    this.source = 'ml_kit',
    this.embedding,
  });

  final String id;
  final String mediaId;
  final String ownerId;
  final FaceBoundingBox boundingBox;
  final double? confidence;
  final DateTime? detectedAt;
  final String? linkedPersonId;
  final String source;

  /// On-Device-Merkmalsvektor – nie öffentlich freigeben.
  final List<double>? embedding;

  bool get isLinked => linkedPersonId != null && linkedPersonId!.isNotEmpty;

  factory MediaFaceDetectionModel.fromJson(Map<String, dynamic> json) {
    final boxRaw = json['bounding_box'];
    final boxMap = boxRaw is Map
        ? Map<String, dynamic>.from(boxRaw)
        : <String, dynamic>{};
    return MediaFaceDetectionModel(
      id: json['id'] as String,
      mediaId: json['media_id'] as String,
      ownerId: json['owner_id'] as String,
      boundingBox: FaceBoundingBox.fromJson(boxMap),
      confidence: (json['confidence'] as num?)?.toDouble(),
      detectedAt: json['detected_at'] != null
          ? DateTime.tryParse(json['detected_at'].toString())
          : null,
      linkedPersonId: json['linked_person_id'] as String?,
      source: json['source'] as String? ?? 'ml_kit',
      embedding: _parseEmbedding(json['embedding']),
    );
  }

  static List<double>? _parseEmbedding(Object? raw) {
    if (raw is! List) return null;
    return raw.map((e) => (e as num).toDouble()).toList();
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'media_id': mediaId,
      'owner_id': ownerId,
      'bounding_box': boundingBox.toJson(),
      if (confidence != null) 'confidence': confidence,
      'source': source,
      if (linkedPersonId != null) 'linked_person_id': linkedPersonId,
      if (embedding != null) 'embedding': embedding,
    };
  }

  MediaFaceDetectionModel copyWith({
    String? linkedPersonId,
    bool clearLinkedPerson = false,
    List<double>? embedding,
  }) {
    return MediaFaceDetectionModel(
      id: id,
      mediaId: mediaId,
      ownerId: ownerId,
      boundingBox: boundingBox,
      confidence: confidence,
      detectedAt: detectedAt,
      linkedPersonId: clearLinkedPerson
          ? null
          : (linkedPersonId ?? this.linkedPersonId),
      source: source,
      embedding: embedding ?? this.embedding,
    );
  }
}
