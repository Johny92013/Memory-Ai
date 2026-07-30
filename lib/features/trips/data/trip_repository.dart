import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_detection_service.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/data/trip_model.dart';
import 'package:memory_ai/features/trips/data/trip_suggestion_dismissal_store.dart';
import 'package:memory_ai/features/trips/data/trip_suggestion_model.dart';

/// CRUD und Vorschläge für Reisen.
class TripRepository {
  TripRepository({TripDetectionService? detectionService})
    : _detection = detectionService ?? TripDetectionService();

  final TripDetectionService _detection;
  static final _client = SupabaseService.client;

  String get _userId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw const AppException(message: 'Du bist nicht angemeldet.');
    }
    return id;
  }

  Future<List<TripModel>> listMyTrips() async {
    try {
      final rows = await _client
          .from('trips')
          .select()
          .order('start_date', ascending: false)
          .order('created_at', ascending: false);

      final trips = (rows as List)
          .map(
            (row) => TripModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();

      final roles = await _myRoles();
      final mediaByTrip = await _mediaCountsByTrip();

      return trips.map((trip) {
        final stats = mediaByTrip[trip.id];
        return TripModel(
          id: trip.id,
          ownerId: trip.ownerId,
          familyId: trip.familyId,
          title: trip.title,
          description: trip.description,
          status: trip.status,
          startDate: trip.startDate,
          endDate: trip.endDate,
          coverMediaId: trip.coverMediaId,
          createdAt: trip.createdAt,
          updatedAt: trip.updatedAt,
          photoCount: stats?.photoCount ?? 0,
          locationCount: stats?.locationCount ?? 0,
          countries: stats?.countries.toList() ?? const [],
          myRole: roles[trip.id] ?? (trip.ownerId == _userId ? 'owner' : null),
        );
      }).toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<TripModel?> getTrip(String tripId) async {
    try {
      final row = await _client
          .from('trips')
          .select()
          .eq('id', tripId)
          .maybeSingle();
      if (row == null) return null;
      final trip = TripModel.fromJson(Map<String, dynamic>.from(row));
      final roles = await _myRoles();
      final stats = await _mediaCountsByTrip();
      final s = stats[tripId];
      return TripModel(
        id: trip.id,
        ownerId: trip.ownerId,
        familyId: trip.familyId,
        title: trip.title,
        description: trip.description,
        status: trip.status,
        startDate: trip.startDate,
        endDate: trip.endDate,
        coverMediaId: trip.coverMediaId,
        createdAt: trip.createdAt,
        updatedAt: trip.updatedAt,
        photoCount: s?.photoCount ?? 0,
        locationCount: s?.locationCount ?? 0,
        countries: s?.countries.toList() ?? const [],
        myRole: roles[tripId] ?? (trip.ownerId == _userId ? 'owner' : null),
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<TripSuggestion>> listSuggestions() async {
    final allMedia = await _loadAllMyMediaForDetection();
    final trips = await listMyTrips();
    final suggestions = _detection.detectSuggestions(
      media: allMedia,
      existingTrips: trips,
    );
    return suggestions
        .where(
          (s) => !TripSuggestionDismissalStore.isDismissed(
            s.mediaItems.map((m) => m.id).toList(),
          ),
        )
        .toList();
  }

  Future<List<MediaItemModel>> _loadAllMyMediaForDetection() async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('owner_id', _userId)
          .order('taken_at', ascending: false)
          .limit(2000);
      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<TripModel> createTrip({
    required String title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String status = 'completed',
    List<String>? mediaIds,
    String? coverMediaId,
  }) async {
    try {
      final insert = <String, dynamic>{
        'owner_id': _userId,
        'title': title,
        'description': ?description,
        'status': status,
        if (startDate != null) 'start_date': _formatDate(startDate),
        if (endDate != null) 'end_date': _formatDate(endDate),
        'cover_media_id': ?coverMediaId,
      };

      final row = await _client.from('trips').insert(insert).select().single();
      final trip = TripModel.fromJson(Map<String, dynamic>.from(row));

      if (mediaIds != null && mediaIds.isNotEmpty) {
        await assignMediaToTrip(tripId: trip.id, mediaIds: mediaIds);
      }

      return trip;
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<TripModel> createFromSuggestion(TripSuggestion suggestion) async {
    final cover = suggestion.mediaItems.isNotEmpty
        ? suggestion.mediaItems.first.id
        : null;
    return createTrip(
      title: suggestion.suggestedTitle,
      startDate: suggestion.startDate,
      endDate: suggestion.endDate,
      status: 'completed',
      mediaIds: suggestion.mediaItems.map((m) => m.id).toList(),
      coverMediaId: cover,
    );
  }

  Future<void> assignMediaToTrip({
    required String tripId,
    required List<String> mediaIds,
  }) async {
    try {
      for (final mediaId in mediaIds) {
        await _client
            .from('media_items')
            .update({'trip_id': tripId})
            .eq('id', mediaId)
            .eq('owner_id', _userId);
      }
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> dismissSuggestion(TripSuggestion suggestion) {
    TripSuggestionDismissalStore.dismiss(
      suggestion.mediaItems.map((m) => m.id).toList(),
    );
    return Future.value();
  }

  Future<TripModel> updateTrip(TripModel trip) async {
    try {
      final row = await _client
          .from('trips')
          .update(trip.toUpdateJson())
          .eq('id', trip.id)
          .select()
          .single();
      return TripModel.fromJson(Map<String, dynamic>.from(row));
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<MediaItemModel>> listTripMedia(String tripId) async {
    try {
      final rows = await _client
          .from('media_items')
          .select()
          .eq('trip_id', tripId)
          .order('taken_at', ascending: false)
          .order('created_at', ascending: false);
      return (rows as List)
          .map(
            (row) =>
                MediaItemModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<List<TripMemberModel>> listTripMembers(String tripId) async {
    try {
      final rows = await _client
          .from('trip_members')
          .select('*, profiles(display_name, email)')
          .eq('trip_id', tripId);
      return (rows as List)
          .map(
            (row) =>
                TripMemberModel.fromJson(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> inviteMember({
    required String tripId,
    required String email,
    String role = 'viewer',
  }) async {
    try {
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();
      if (profile == null) {
        throw const AppException(message: 'Nutzer nicht gefunden.');
      }
      await _client.from('trip_members').upsert({
        'trip_id': tripId,
        'user_id': profile['id'],
        'role': role,
        'invitation_status': 'accepted',
        'invited_by': _userId,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<Map<String, String>> _myRoles() async {
    final map = <String, String>{};
    final rows = await _client
        .from('trip_members')
        .select('trip_id, role')
        .eq('user_id', _userId)
        .eq('invitation_status', 'accepted');
    for (final row in rows as List) {
      final data = Map<String, dynamic>.from(row as Map);
      map[data['trip_id'] as String] = data['role'] as String;
    }
    return map;
  }

  Future<Map<String, _TripMediaStats>> _mediaCountsByTrip() async {
    try {
      final rows = await _client
          .from('media_items')
          .select('trip_id, country_name, latitude, longitude')
          .not('trip_id', 'is', null);
      final map = <String, _TripMediaStats>{};
      for (final row in rows as List) {
        final data = Map<String, dynamic>.from(row as Map);
        final tripId = data['trip_id'] as String?;
        if (tripId == null) continue;
        final stats = map.putIfAbsent(tripId, () => _TripMediaStats());
        stats.photoCount++;
        final country = data['country_name'] as String?;
        if (country != null && country.trim().isNotEmpty) {
          stats.countries.add(country.trim());
        }
        final lat = data['latitude'] as num?;
        final lon = data['longitude'] as num?;
        if (lat != null && lon != null) {
          stats.locationKeys.add(
            '${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}',
          );
        }
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _TripMediaStats {
  int photoCount = 0;
  final Set<String> countries = {};
  final Set<String> locationKeys = {};

  int get locationCount => locationKeys.length;
}
