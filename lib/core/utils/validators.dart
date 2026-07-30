import 'package:memory_ai/core/constants/app_constants.dart';

/// Formular-Validatoren mit deutschen Fehlermeldungen.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Bitte gib deine E-Mail-Adresse ein.';
    }
    if (!_emailPattern.hasMatch(input)) {
      return 'Bitte gib eine gültige E-Mail-Adresse ein.';
    }
    return null;
  }

  static String? password(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Bitte gib dein Passwort ein.';
    }
    if (input.length < AppConstants.minPasswordLength) {
      return 'Das Passwort muss mindestens ${AppConstants.minPasswordLength} Zeichen lang sein.';
    }
    return null;
  }

  /// Login: Benutzername oder E-Mail (kein strenges E-Mail-Format).
  static String? loginIdentifier(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Bitte gib deinen Benutzername oder E-Mail ein.';
    }
    return null;
  }

  /// Login: kurze Demo-Passwörter erlaubt (min. 4 Zeichen).
  static String? loginPassword(String? value) {
    final input = value ?? '';
    if (input.isEmpty) {
      return 'Bitte gib dein Passwort ein.';
    }
    if (input.length < AppConstants.minLoginPasswordLength) {
      return 'Das Passwort muss mindestens ${AppConstants.minLoginPasswordLength} Zeichen lang sein.';
    }
    return null;
  }

  static String? required(String? value, {String fieldName = 'Dieses Feld'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ist erforderlich.';
    }
    return null;
  }

  static String? requiredName(String? value, {String label = 'Name'}) {
    return required(value, fieldName: label);
  }

  static String? passwordsMatch(String? password, String? confirmPassword) {
    if (confirmPassword == null || confirmPassword.isEmpty) {
      return 'Bitte bestätige dein Passwort.';
    }
    if (password != confirmPassword) {
      return 'Die Passwörter stimmen nicht überein.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) =>
      passwordsMatch(password, value);
}
