import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/home/data/home_dashboard_data.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';

/// Statistik und Bereiche für die Startseite (echte Supabase-Daten).
class HomeStats {
  const HomeStats({
    required this.photoCount,
    required this.videoCount,
    required this.countryCount,
    required this.tripCount,
  });

  final int photoCount;
  final int videoCount;
  final int countryCount;
  final int tripCount;
}

class HomeRepository {
  HomeRepository({
    MediaRepository? mediaRepository,
    TripRepository? tripRepository,
    FamilyRepository? familyRepository,
    ProfileRepository? profileRepository,
  }) : _mediaRepository = mediaRepository ?? MediaRepository(),
       _tripRepository = tripRepository ?? TripRepository(),
       _familyRepository = familyRepository ?? FamilyRepository(),
       _profileRepository = profileRepository ?? ProfileRepository();

  final MediaRepository _mediaRepository;
  final TripRepository _tripRepository;
  final FamilyRepository _familyRepository;
  final ProfileRepository _profileRepository;
  static final _client = SupabaseService.client;

  /// Lädt Dashboard-Daten fehlertolerant (einzelne Bereiche dürfen scheitern).
  Future<HomeDashboardData> loadDashboard() async {
    final profile = await _safeProfile();
    final stats = await _safeStats();
    final family = await _safeFamily();
    final locations = await _safeLocationCount();
    final recent = await _safeRecent();

    return HomeDashboardData(
      profile: profile,
      photoCount: stats?.photoCount ?? 0,
      videoCount: stats?.videoCount ?? 0,
      familyMemberCount: family?.memberCount,
      hasFamily: family?.hasFamily ?? false,
      visitedLocationCount: locations?.count ?? 0,
      unreadMessageCount: null,
      chatAvailable: false,
      recentMemories: recent?.items ?? const [],
      statsFailed: stats == null,
      familyFailed: family == null,
      memoriesFailed: recent == null,
      locationsFailed: locations == null,
    );
  }

  Future<ProfileModel?> _safeProfile() async {
    try {
      return await _profileRepository.getMyProfile();
    } catch (_) {
      return null;
    }
  }

  Future<HomeStats?> _safeStats() async {
    try {
      return await getStats();
    } catch (_) {
      return null;
    }
  }

  Future<_FamilyDash?> _safeFamily() async {
    try {
      final families = await _familyRepository.listMyFamilies();
      if (families.isEmpty) {
        return const _FamilyDash(hasFamily: false, memberCount: 0);
      }
      final members = await _familyRepository.listMembers(families.first.id);
      return _FamilyDash(hasFamily: true, memberCount: members.length);
    } catch (_) {
      return null;
    }
  }

  Future<_CountDash?> _safeLocationCount() async {
    try {
      final media = await _mediaRepository.listMyMediaWithGps(limit: 2000);
      final groups = MapAggregationHelper.groupByCoordinates(media);
      return _CountDash(groups.length);
    } catch (_) {
      return null;
    }
  }

  Future<_RecentDash?> _safeRecent() async {
    try {
      final items = await getRecentlyUploaded(limit: 12);
      return _RecentDash(items);
    } catch (_) {
      return null;
    }
  }

  Future<HomeStats> getStats() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const HomeStats(
          photoCount: 0,
          videoCount: 0,
          countryCount: 0,
          tripCount: 0,
        );
      }

      final photos = await _client
          .from('media_items')
          .select('id')
          .eq('owner_id', userId)
          .eq('media_type', 'image');
      final videos = await _client
          .from('media_items')
          .select('id')
          .eq('owner_id', userId)
          .eq('media_type', 'video');

      final gpsMedia = await _mediaRepository.listMyMediaWithGps(limit: 2000);
      final countries = gpsMedia
          .map((m) => m.countryName?.trim())
          .whereType<String>()
          .where((c) => c.isNotEmpty)
          .toSet();

      final trips = await _tripRepository.listMyTrips();

      return HomeStats(
        photoCount: (photos as List).length,
        videoCount: (videos as List).length,
        countryCount: countries.length,
        tripCount: trips.length,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<bool> hasAnyMedia() async {
    final stats = await getStats();
    return stats.photoCount + stats.videoCount > 0;
  }

  Future<TripModel?> getLatestTrip() async {
    final trips = await _tripRepository.listMyTrips();
    if (trips.isEmpty) return null;
    return trips.first;
  }

  Future<List<MediaItemModel>> getRecentlyUploaded({int limit = 6}) async {
    return _mediaRepository.listMyMedia(limit: limit, offset: 0);
  }

  Future<List<MediaItemModel>> getOnThisDay() async {
    final all = await _mediaRepository.listMyMedia(limit: 200, offset: 0);
    final now = DateTime.now();
    return all.where((item) {
      final date = item.takenAt ?? item.createdAt;
      if (date == null) return false;
      return date.month == now.month &&
          date.day == now.day &&
          date.year < now.year;
    }).toList();
  }

  Future<List<CountryStats>> getCountryOverview() async {
    final media = await _mediaRepository.listMyMediaWithGps(limit: 500);
    return MapAggregationHelper.aggregateCountries(media).take(6).toList();
  }

  Future<List<MapLocationGroup>> getRecentLocations({int limit = 6}) async {
    final media = await _mediaRepository.listMyMediaWithGps(limit: 200);
    final groups = MapAggregationHelper.groupByCoordinates(media);
    groups.sort((a, b) {
      final da = a.latestTakenAt ?? DateTime(1970);
      final db = b.latestTakenAt ?? DateTime(1970);
      return db.compareTo(da);
    });
    return groups.take(limit).toList();
  }
}

class _FamilyDash {
  const _FamilyDash({required this.hasFamily, required this.memberCount});
  final bool hasFamily;
  final int memberCount;
}

class _CountDash {
  const _CountDash(this.count);
  final int count;
}

class _RecentDash {
  const _RecentDash(this.items);
  final List<MediaItemModel> items;
}
