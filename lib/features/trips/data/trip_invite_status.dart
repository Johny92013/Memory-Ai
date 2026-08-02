import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';

/// Einladungsstatus für [trip_members.invitation_status].
abstract final class TripInviteStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const declined = 'declined';
  static const revoked = 'revoked';

  static bool isPending(String? status) => status == pending;

  static bool isAccepted(String? status) => status == accepted;

  static bool isActiveMembership(String? status) => status == accepted;

  static bool canRespondToInvite(String? status) => status == pending;

  /// Status nach erneuter Einladung: akzeptierte Mitgliedschaft nicht zurücksetzen.
  static String statusAfterReinvite(String? existingStatus) =>
      isAccepted(existingStatus) ? accepted : pending;

  /// Bereits aktives Mitglied → nur Rolle ändern, keine neue Einladung.
  static bool shouldSkipInviteAsPending(String? existingStatus) =>
      isAccepted(existingStatus);

  static List<TripMemberModel> acceptedMembers(
    Iterable<TripMemberModel> members,
  ) => members.where((m) => isAccepted(m.invitationStatus)).toList();

  static List<TripMemberModel> pendingMembers(
    Iterable<TripMemberModel> members,
  ) => members.where((m) => isPending(m.invitationStatus)).toList();

  /// Akzeptierte Mitglieder + optionale Companion-Anzahl für Anzeige.
  static int visibleCompanionCount({
    required int acceptedMemberCount,
    required int companionCount,
  }) => acceptedMemberCount + companionCount;
}

/// Filter für die Reise-Galerie (clientseitig über [listTripMedia]).
enum TripMediaGalleryFilter { all, mine, fromCompanions, photos, videos }

abstract final class TripMediaFilters {
  static List<MediaItemModel> apply({
    required List<MediaItemModel> items,
    required String currentUserId,
    required TripMediaGalleryFilter filter,
  }) {
    switch (filter) {
      case TripMediaGalleryFilter.all:
        return List<MediaItemModel>.from(items);
      case TripMediaGalleryFilter.mine:
        return items.where((m) => m.ownerId == currentUserId).toList();
      case TripMediaGalleryFilter.fromCompanions:
        return items.where((m) => m.ownerId != currentUserId).toList();
      case TripMediaGalleryFilter.photos:
        return items.where((m) => m.mediaType == 'image').toList();
      case TripMediaGalleryFilter.videos:
        return items.where((m) => m.mediaType == 'video').toList();
    }
  }
}
