import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/core/utils/auth_identifier_resolver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth-Zugriff über Supabase.
class AuthRepository {
  GoTrueClient get _auth => SupabaseService.client.auth;

  User? get currentUser => _auth.currentUser;

  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'first_name': firstName.trim(), 'last_name': lastName.trim()},
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<AuthResponse> signInWithIdentifier({
    required String identifier,
    required String password,
  }) async {
    final email = AuthIdentifierResolver.resolve(identifier);
    return signIn(email: email, password: password);
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email.trim());
    } catch (error) {
      throw ErrorMapper.map(error);
    }
  }
}
