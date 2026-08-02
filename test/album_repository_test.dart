import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/memories/data/album_model.dart';
import 'package:memory_ai/features/memories/data/album_repository.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';

void main() {
  test('AlbumModel.fromJson parst Items sortiert', () {
    final album = AlbumModel.fromJson({
      'id': 'a1',
      'title': 'Bali',
      'created_by': 'u1',
      'owner_id': 'u1',
      'layout': 'mixed',
      'album_type': 'manual',
      'cover_media_id': 'm2',
      'album_items': [
        {
          'id': 'i2',
          'album_id': 'a1',
          'position': 1,
          'media_item_id': 'm2',
          'media_items': {'id': 'm2', 'owner_id': 'u1', 'media_type': 'image'},
        },
        {
          'id': 'i1',
          'album_id': 'a1',
          'position': 0,
          'media_item_id': 'm1',
          'media_items': {'id': 'm1', 'owner_id': 'u1', 'media_type': 'image'},
        },
      ],
    });
    expect(album.title, 'Bali');
    expect(album.coverMediaId, 'm2');
    expect(album.items.length, 2);
    expect(album.items.first.mediaItemId, 'm1');
    expect(album.items.last.mediaItemId, 'm2');
  });

  test('layoutToDb roundtrip', () {
    expect(AlbumRepository.layoutToDb(AlbumLayout.single), 'single');
    expect(AlbumRepository.layoutToDb(AlbumLayout.collage), 'collage');
  });
}
