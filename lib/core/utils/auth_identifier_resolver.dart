/// Mappt Benutzername-Logins auf Supabase-E-Mail-Adressen.
class AuthIdentifierResolver {
  AuthIdentifierResolver._();

  static const String adminEmail = 'admin@memoryai.app';
  static const String testEmail = 'test@memoryai.app';

  static const Map<String, String> _usernameToEmail = {
    'admin': adminEmail,
    'test': testEmail,
  };

  /// Wandelt Benutzername oder E-Mail in die Auth-E-Mail um.
  static String resolve(String identifier) {
    final trimmed = identifier.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    final mapped = _usernameToEmail[trimmed.toLowerCase()];
    return mapped ?? trimmed;
  }
}
