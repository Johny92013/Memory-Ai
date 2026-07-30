/// Rollenbasierte Berechtigungen je Reise (spiegelt RLS-Logik für UI).
class TripRolePermissions {
  TripRolePermissions._();

  static bool canViewTrip(String? role) =>
      role == 'owner' ||
      role == 'editor' ||
      role == 'contributor' ||
      role == 'viewer';

  static bool canEditTrip(String? role) => role == 'owner' || role == 'editor';

  static bool canUploadMedia(String? role) =>
      role == 'owner' || role == 'editor' || role == 'contributor';

  static bool canEditMedia(String? role, {required bool isOwnMedia}) {
    if (role == 'owner' || role == 'editor') return true;
    if (role == 'contributor' && isOwnMedia) return true;
    return false;
  }

  static bool canManageMembers(String? role) => role == 'owner';

  static bool canDeleteTrip(String? role) => role == 'owner';
}
