/// Persistiertes Album (`public.albums`) inkl. optionaler Medienliste.
class AlbumModel {
  const AlbumModel({
    required this.id,
    required this.title,
    required this.createdBy,
    this.familyId,
    this.ownerId,
    this.tripId,
    this.description,
    this.coverPath,
    this.coverMediaId,
    this.albumType = 'manual',
    this.layout = 'mixed',
    this.createdAt,
    this.updatedAt,
    this.items = const [],
  });

  final String id;
  final String title;
  final String createdBy;
  final String? familyId;
  final String? ownerId;
  final String? tripId;
  final String? description;
  final String? coverPath;
  final String? coverMediaId;
  final String albumType;
  final String layout;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<AlbumItemModel> items;

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['album_items'];
    final items = <AlbumItemModel>[];
    if (rawItems is List) {
      for (final row in rawItems) {
        if (row is Map) {
          items.add(AlbumItemModel.fromJson(Map<String, dynamic>.from(row)));
        }
      }
      items.sort((a, b) => a.position.compareTo(b.position));
    }

    return AlbumModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      createdBy: json['created_by'] as String? ?? '',
      familyId: json['family_id'] as String?,
      ownerId: json['owner_id'] as String?,
      tripId: json['trip_id'] as String?,
      description: json['description'] as String?,
      coverPath: json['cover_path'] as String?,
      coverMediaId: json['cover_media_id'] as String?,
      albumType: json['album_type'] as String? ?? 'manual',
      layout: json['layout'] as String? ?? 'mixed',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'created_by': createdBy,
    if (familyId != null) 'family_id': familyId,
    if (ownerId != null) 'owner_id': ownerId,
    if (tripId != null) 'trip_id': tripId,
    if (description != null) 'description': description,
    if (coverPath != null) 'cover_path': coverPath,
    if (coverMediaId != null) 'cover_media_id': coverMediaId,
    'album_type': albumType,
    'layout': layout,
  };
}

/// Einzelnes Album-Element (`public.album_items`).
class AlbumItemModel {
  const AlbumItemModel({
    required this.id,
    required this.albumId,
    required this.position,
    this.mediaItemId,
    this.memoryId,
    this.addedBy,
    this.media,
  });

  final String id;
  final String albumId;
  final int position;
  final String? mediaItemId;
  final String? memoryId;
  final String? addedBy;
  final Map<String, dynamic>? media;

  factory AlbumItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? media;
    final raw = json['media_items'];
    if (raw is Map) {
      media = Map<String, dynamic>.from(raw);
    }
    return AlbumItemModel(
      id: json['id'] as String,
      albumId: json['album_id'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      mediaItemId: json['media_item_id'] as String?,
      memoryId: json['memory_id'] as String?,
      addedBy: json['added_by'] as String?,
      media: media,
    );
  }
}
