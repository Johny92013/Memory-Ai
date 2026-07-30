import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Löst den Anzeigenamen für die Start-Begrüßung auf.
abstract final class HomeGreeting {
  /// Gibt den Vornamen/Anzeigenamen zurück oder `null` für Fallback „Hallo! 👋“.
  static String? resolveDisplayName({
    ProfileModel? profile,
    Map<String, dynamic>? userMetadata,
    String? email,
  }) {
    final first = profile?.firstName?.trim();
    if (first != null && first.isNotEmpty) return first;

    final combined = [profile?.firstName, profile?.lastName]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(' ');
    if (combined.isNotEmpty) {
      return combined.split(RegExp(r'\s+')).first;
    }

    final meta = userMetadata ?? const <String, dynamic>{};
    final metaFirst = meta['first_name']?.toString().trim();
    if (metaFirst != null && metaFirst.isNotEmpty) return metaFirst;

    final metaFull =
        meta['full_name']?.toString().trim() ?? meta['name']?.toString().trim();
    if (metaFull != null && metaFull.isNotEmpty) {
      final parts = metaFull.split(RegExp(r'\s+'));
      if (parts.isNotEmpty && !parts.first.contains('@')) {
        return parts.first;
      }
    }

    final mail = email ?? profile?.email;
    if (mail != null && mail.contains('@')) {
      final local = mail.split('@').first.trim();
      if (local.isNotEmpty) return local;
    }

    return null;
  }

  static String greetingLine({
    ProfileModel? profile,
    Map<String, dynamic>? userMetadata,
    String? email,
  }) {
    final name = resolveDisplayName(
      profile: profile,
      userMetadata: userMetadata,
      email: email,
    );
    if (name == null || name.isEmpty) return 'Hallo! 👋';
    return 'Hallo, $name! 👋';
  }

  /// Aktuelle Auth-Metadaten aus Supabase (falls verfügbar).
  static Map<String, dynamic>? currentUserMetadata() {
    return SupabaseService.client.auth.currentUser?.userMetadata;
  }

  static String? currentUserEmail() {
    return SupabaseService.client.auth.currentUser?.email;
  }
}
