import 'package:supabase_flutter/supabase_flutter.dart';

/// Stellt den globalen Supabase-Client bereit.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;
}
