import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/core/constants/app_constants.dart';
import 'package:memory_ai/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('email akzeptiert gültige Adresse', () {
      expect(Validators.email('test@example.com'), isNull);
    });

    test('email lehnt leere Eingabe ab', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('email lehnt ungültiges Format ab', () {
      expect(Validators.email('keine-email'), isNotNull);
    });

    test('password erfordert Mindestlänge', () {
      expect(
        Validators.password('12345'),
        contains('${AppConstants.minPasswordLength}'),
      );
      expect(Validators.password('12345678'), isNull);
    });

    test('loginPassword erlaubt kurze Demo-Passwörter', () {
      expect(Validators.loginPassword('test'), isNull);
      expect(Validators.loginPassword('admin'), isNull);
      expect(Validators.loginPassword('abc'), isNotNull);
      expect(Validators.loginPassword('ab'), isNotNull);
    });

    test('loginIdentifier akzeptiert Benutzername ohne @', () {
      expect(Validators.loginIdentifier('admin'), isNull);
      expect(Validators.loginIdentifier(''), isNotNull);
    });

    test('passwordsMatch erkennt Abweichung', () {
      expect(Validators.passwordsMatch('abc', 'xyz'), isNotNull);
      expect(Validators.passwordsMatch('abc', 'abc'), isNull);
    });

    test('requiredName meldet fehlenden Namen', () {
      expect(Validators.requiredName(''), isNotNull);
      expect(Validators.requiredName('Anna'), isNull);
    });
  });
}
