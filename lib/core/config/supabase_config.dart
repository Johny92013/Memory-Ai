import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lädt Supabase-Konfiguration aus `.env` und initialisiert den Client.
class SupabaseConfig {
  SupabaseConfig._();

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.trim().isEmpty) {
      throw StateError('SUPABASE_URL fehlt in der .env-Datei.');
    }
    return value.trim();
  }

  static String get supabasePublishableKey {
    final value = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    if (value == null || value.trim().isEmpty) {
      throw StateError('SUPABASE_PUBLISHABLE_KEY fehlt in der .env-Datei.');
    }
    return value.trim();
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }
}
