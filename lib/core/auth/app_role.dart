import 'package:supabase_flutter/supabase_flutter.dart';

/// App-Rollen aus `app_metadata` (nicht user_metadata).
class AppRole {
  AppRole._();

  static const String adminRole = 'admin';
  static const String userRole = 'user';

  static bool isAppAdmin(User? user) {
    if (user == null) return false;
    final role = user.appMetadata['app_role'];
    return role == adminRole;
  }
}
