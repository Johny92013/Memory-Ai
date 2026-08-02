import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/album_model.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// CRUD für persistierte Alben (`albums` / `album_items`).
class AlbumRepository {
  static final _client = SupabaseService.client;

  static const _albumSelect =
      '*, album_items(id, album_id, position, media_item_id, memory_id, added_by, media_items(*))';

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<AlbumModel>> listAlbums({
    String? familyId,
    String? tripId,
  }) async {
    try {
      var query = _client.from('albums').select(_albumSelect);
      if (familyId != null) {
        query = query.eq('family_id', familyId);
      } else if (tripId != null) {
        query = query.eq('trip_id', tripId);
      } else {
        query = query.eq('owner_id', _userId);
      }
      final rows = await query.order('created_at', ascending: false);
      return (rows as List)
          .map((r) => AlbumModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList();
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<AlbumModel?> getAlbum(String id) async {
    try {
      final row = await _client
          .from('albums')
          .select(_albumSelect)
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return AlbumModel.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<AlbumModel> createAlbum({
    required String title,
    String? description,
    String? familyId,
    String? tripId,
    String? coverMediaId,
    String? coverPath,
    String albumType = 'manual',
    String layout = 'mixed',
    List<String> mediaItemIds = const [],
  }) async {
    try {
      final uid = _userId;
      final inserted = await _client
          .from('albums')
          .insert({
            'title': title,
            'description': description,
            'created_by': uid,
            'owner_id': uid,
            if (familyId != null) 'family_id': familyId,
            if (tripId != null) 'trip_id': tripId,
            if (coverMediaId != null) 'cover_media_id': coverMediaId,
            if (coverPath != null) 'cover_path': coverPath,
            'album_type': albumType,
            'layout': layout,
          })
          .select()
          .single();

      final albumId = inserted['id'] as String;
      if (mediaItemIds.isNotEmpty) {
        await _insertItems(albumId, mediaItemIds);
      }
      final full = await getAlbum(albumId);
      if (full == null) {
        throw const AppException(message: 'Album konnte nicht geladen werden.');
      }
      return full;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<AlbumModel> updateAlbum(
    String id, {
    String? title,
    String? description,
    String? coverMediaId,
    String? coverPath,
    String? layout,
    bool clearCover = false,
  }) async {
    try {
      final patch = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (layout != null) 'layout': layout,
        if (coverPath != null) 'cover_path': coverPath,
        if (coverMediaId != null) 'cover_media_id': coverMediaId,
        if (clearCover) ...{'cover_media_id': null, 'cover_path': null},
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };
      await _client.from('albums').update(patch).eq('id', id);
      final full = await getAlbum(id);
      if (full == null) {
        throw const AppException(message: 'Album nicht gefunden.');
      }
      return full;
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> deleteAlbum(String id) async {
    try {
      await _client.from('albums').delete().eq('id', id);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> addMediaToAlbum(
    String albumId,
    String mediaItemId, {
    int? position,
  }) async {
    try {
      final pos = position ?? await _nextPosition(albumId);
      await _client.from('album_items').insert({
        'album_id': albumId,
        'media_item_id': mediaItemId,
        'position': pos,
        'added_by': _userId,
      });
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<void> removeMediaFromAlbum(String albumId, String mediaItemId) async {
    try {
      await _client
          .from('album_items')
          .delete()
          .eq('album_id', albumId)
          .eq('media_item_id', mediaItemId);
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  /// Ersetzt die Sortierung / Medienliste eines Albums.
  Future<void> setAlbumItems(String albumId, List<String> mediaItemIds) async {
    try {
      await _client.from('album_items').delete().eq('album_id', albumId);
      if (mediaItemIds.isNotEmpty) {
        await _insertItems(albumId, mediaItemIds);
      }
    } catch (e) {
      throw ErrorMapper.map(e);
    }
  }

  Future<MemoryAlbumSession> toSession(
    AlbumModel album, {
    String? locationLabel,
  }) async {
    final items = <MediaItemModel>[];
    for (final item in album.items) {
      if (item.media != null) {
        items.add(MediaItemModel.fromJson(item.media!));
      } else if (item.mediaItemId != null) {
        final row = await _client
            .from('media_items')
            .select()
            .eq('id', item.mediaItemId!)
            .maybeSingle();
        if (row != null) {
          items.add(MediaItemModel.fromJson(Map<String, dynamic>.from(row)));
        }
      }
    }
    return MemoryAlbumSession(
      title: album.title,
      items: items,
      coverMediaId: album.coverMediaId,
      locationLabel: locationLabel ?? album.description,
      layout: _parseLayout(album.layout),
      albumId: album.id,
    );
  }

  Future<void> _insertItems(String albumId, List<String> mediaItemIds) async {
    final uid = _userId;
    final rows = [
      for (var i = 0; i < mediaItemIds.length; i++)
        {
          'album_id': albumId,
          'media_item_id': mediaItemIds[i],
          'position': i,
          'added_by': uid,
        },
    ];
    await _client.from('album_items').insert(rows);
  }

  Future<int> _nextPosition(String albumId) async {
    final rows = await _client
        .from('album_items')
        .select('position')
        .eq('album_id', albumId)
        .order('position', ascending: false)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return 0;
    return ((list.first['position'] as num?)?.toInt() ?? -1) + 1;
  }

  static AlbumLayout _parseLayout(String value) {
    return switch (value) {
      'single' => AlbumLayout.single,
      'doublePage' => AlbumLayout.doublePage,
      'collage' => AlbumLayout.collage,
      _ => AlbumLayout.mixed,
    };
  }

  static String layoutToDb(AlbumLayout layout) {
    return switch (layout) {
      AlbumLayout.single => 'single',
      AlbumLayout.doublePage => 'doublePage',
      AlbumLayout.collage => 'collage',
      AlbumLayout.mixed => 'mixed',
    };
  }
}
