/// Status einer Personen-Zuordnung auf einem Medium.
abstract final class MediaPersonStatus {
  static const suggested = 'suggested';
  static const pendingConfirmation = 'pending_confirmation';
  static const confirmed = 'confirmed';
  static const rejected = 'rejected';
  static const acceptedToGallery = 'accepted_to_gallery';
  static const linkedOnly = 'linked_only';

  static const openStatuses = <String>[suggested, pendingConfirmation];

  static const confirmedStatuses = <String>[
    confirmed,
    acceptedToGallery,
    linkedOnly,
  ];

  static const rejectedStatuses = <String>[rejected];
}

/// Eintrag „Aufnahmen mit mir“.
class TaggedMediaItem {
  const TaggedMediaItem({
    required this.tagId,
    required this.mediaId,
    required this.status,
    required this.source,
    this.confidence,
    this.taggedBy,
    this.taggedByName,
    required this.createdAt,
    this.confirmedAt,
    this.rejectedAt,
    this.addedToGalleryAt,
    required this.mediaType,
    this.thumbnailPath,
    this.storagePath,
    this.takenAt,
    this.locationName,
    this.city,
    this.countryName,
    this.tripId,
    this.tripTitle,
    this.familyId,
    this.familyName,
    required this.ownerId,
    this.ownerName,
  });

  final String tagId;
  final String mediaId;
  final String status;
  final String source;
  final double? confidence;
  final String? taggedBy;
  final String? taggedByName;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? rejectedAt;
  final DateTime? addedToGalleryAt;
  final String mediaType;
  final String? thumbnailPath;
  final String? storagePath;
  final DateTime? takenAt;
  final String? locationName;
  final String? city;
  final String? countryName;
  final String? tripId;
  final String? tripTitle;
  final String? familyId;
  final String? familyName;
  final String ownerId;
  final String? ownerName;

  bool get isOpen => MediaPersonStatus.openStatuses.contains(status);

  String get placeLabel {
    final parts = <String>[
      if (locationName != null && locationName!.isNotEmpty) locationName!,
      if (city != null && city!.isNotEmpty) city!,
      if (countryName != null && countryName!.isNotEmpty) countryName!,
    ];
    return parts.isEmpty ? 'Ort unbekannt' : parts.join(', ');
  }

  factory TaggedMediaItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return TaggedMediaItem(
      tagId: json['tag_id'] as String,
      mediaId: json['media_id'] as String,
      status: json['status'] as String? ?? MediaPersonStatus.suggested,
      source: json['source'] as String? ?? 'manual',
      confidence: (json['confidence'] as num?)?.toDouble(),
      taggedBy: json['tagged_by'] as String?,
      taggedByName: json['tagged_by_name'] as String?,
      createdAt: parseDt(json['created_at']) ?? DateTime.now().toUtc(),
      confirmedAt: parseDt(json['confirmed_at']),
      rejectedAt: parseDt(json['rejected_at']),
      addedToGalleryAt: parseDt(json['added_to_gallery_at']),
      mediaType: json['media_type'] as String? ?? 'image',
      thumbnailPath: json['thumbnail_path'] as String?,
      storagePath: json['storage_path'] as String?,
      takenAt: parseDt(json['taken_at']),
      locationName: json['location_name'] as String?,
      city: json['city'] as String?,
      countryName: json['country_name'] as String?,
      tripId: json['trip_id'] as String?,
      tripTitle: json['trip_title'] as String?,
      familyId: json['family_id'] as String?,
      familyName: json['family_name'] as String?,
      ownerId: json['owner_id'] as String,
      ownerName: json['owner_name'] as String?,
    );
  }
}

/// In-App-Benachrichtigung.
class InAppNotification {
  const InAppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.payload = const {},
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> payload;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isUnread => readAt == null;

  factory InAppNotification.fromJson(Map<String, dynamic> json) {
    return InAppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String? ?? 'person_tag',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : const {},
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}

/// Galerie-Filter für eigene / geteilte / markierte Medien.
enum GalleryOwnershipFilter { all, own, withMe, shared }
