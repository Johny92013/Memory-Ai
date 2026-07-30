/// Verknüpfung zwischen zwei Medien (`public.media_links`).
class MediaLinkModel {
  const MediaLinkModel({
    required this.id,
    required this.sourceMediaId,
    required this.relatedMediaId,
    required this.relationType,
    this.confidence,
    this.status = 'suggested',
    this.createdBy,
    this.createdAt,
  });

  final String id;
  final String sourceMediaId;
  final String relatedMediaId;
  final String relationType;
  final double? confidence;
  final String status;
  final String? createdBy;
  final DateTime? createdAt;

  bool get isSuggested => status == 'suggested';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';

  factory MediaLinkModel.fromJson(Map<String, dynamic> json) {
    return MediaLinkModel(
      id: json['id'] as String,
      sourceMediaId: json['source_media_id'] as String,
      relatedMediaId: json['related_media_id'] as String,
      relationType: json['relation_type'] as String,
      confidence: (json['confidence'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'suggested',
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'source_media_id': sourceMediaId,
    'related_media_id': relatedMediaId,
    'relation_type': relationType,
    if (confidence != null) 'confidence': confidence,
    'status': status,
    if (createdBy != null) 'created_by': createdBy,
  };
}

/// Kandidat für eine Verknüpfung (vor Persistenz).
class RelatedMediaCandidate {
  const RelatedMediaCandidate({
    required this.sourceMediaId,
    required this.relatedMediaId,
    required this.relationType,
    required this.confidence,
    this.sharedPersonCount = 0,
    this.sameLocation = false,
    this.similarTime = false,
  });

  final String sourceMediaId;
  final String relatedMediaId;
  final String relationType;
  final double confidence;
  final int sharedPersonCount;
  final bool sameLocation;
  final bool similarTime;
}
