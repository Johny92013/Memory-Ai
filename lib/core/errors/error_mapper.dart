import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mappt technische Fehler auf verständliche deutsche Meldungen.
class ErrorMapper {
  ErrorMapper._();

  /// Mappt einen Fehler auf eine [AppException] (für bestehende Repositories).
  static AppException map(Object error) => toAppException(error);

  static String toUserMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is AuthException) {
      return _mapAuthException(error);
    }

    if (error is PostgrestException) {
      return _mapPostgrestException(error);
    }

    if (error is StorageException) {
      return _mapStorageException(error);
    }

    final text = error.toString().toLowerCase();
    if (text.contains('socket') ||
        text.contains('network') ||
        text.contains('failed host lookup') ||
        text.contains('connection') ||
        text.contains('clientexception') ||
        text.contains('xmlhttprequest')) {
      return 'Keine Internetverbindung. Bitte prüfe dein Netz und versuche es erneut.';
    }

    return 'Ein unerwarteter Fehler ist aufgetreten. Bitte versuche es erneut.';
  }

  static AppException toAppException(Object error) {
    return AppException(
      message: toUserMessage(error),
      code: _extractCode(error),
      originalError: error,
    );
  }

  static String? _extractCode(Object error) {
    if (error is AppException) return error.code;
    if (error is AuthException) return error.code;
    if (error is PostgrestException) return error.code;
    if (error is StorageException) return error.statusCode;
    return null;
  }

  static String _mapAuthException(AuthException error) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'E-Mail oder Passwort ist falsch.';
      case 'email_not_confirmed':
        return 'Bitte bestätige zuerst deine E-Mail-Adresse.';
      case 'user_not_found':
        return 'Kein Konto mit dieser E-Mail-Adresse gefunden.';
      case 'email_exists':
      case 'user_already_exists':
        return 'Diese E-Mail-Adresse ist bereits registriert.';
      case 'weak_password':
        return 'Das Passwort ist zu schwach. Bitte wähle ein sicheres Passwort.';
      case 'over_request_rate_limit':
      case '429':
        return 'Zu viele Anfragen. Bitte warte einen Moment und versuche es erneut.';
      case 'otp_expired':
        return 'Der Bestätigungscode ist abgelaufen. Bitte fordere einen neuen an.';
      case 'same_password':
        return 'Das neue Passwort darf nicht mit dem alten identisch sein.';
      default:
        final message = error.message.trim();
        if (message.isNotEmpty) {
          return message;
        }
        return 'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';
    }
  }

  static String _mapPostgrestException(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return 'Dieser Eintrag existiert bereits.';
      case '42501':
        return 'Du hast keine Berechtigung für diese Aktion.';
      case 'PGRST116':
        return 'Der angeforderte Eintrag wurde nicht gefunden.';
      default:
        final message = error.message.trim();
        if (message.isNotEmpty) {
          return message;
        }
        return 'Daten konnten nicht geladen werden.';
    }
  }

  static String _mapStorageException(StorageException error) {
    final message = error.message.toLowerCase();

    if (message.contains('payload too large') ||
        message.contains('file size') ||
        message.contains('too large')) {
      return 'Das Bild ist zu groß. Maximal 20 MB erlaubt.';
    }

    switch (error.statusCode) {
      case '404':
        return 'Die Datei wurde nicht gefunden.';
      case '403':
        return 'Kein Zugriff auf diese Datei.';
      case '413':
        return 'Das Bild ist zu groß. Maximal 20 MB erlaubt.';
      default:
        return 'Datei konnte nicht verarbeitet werden.';
    }
  }
}
