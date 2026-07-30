import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/core/utils/auth_identifier_resolver.dart';

void main() {
  group('AuthIdentifierResolver', () {
    test('mappt admin auf admin@memoryai.app', () {
      expect(
        AuthIdentifierResolver.resolve('admin'),
        AuthIdentifierResolver.adminEmail,
      );
      expect(
        AuthIdentifierResolver.resolve(' Admin '),
        AuthIdentifierResolver.adminEmail,
      );
    });

    test('mappt test auf test@memoryai.app', () {
      expect(
        AuthIdentifierResolver.resolve('test'),
        AuthIdentifierResolver.testEmail,
      );
    });

    test('lässt E-Mail unverändert', () {
      expect(
        AuthIdentifierResolver.resolve('user@example.com'),
        'user@example.com',
      );
    });

    test('unbekannter Benutzername bleibt erhalten', () {
      expect(AuthIdentifierResolver.resolve('custom'), 'custom');
    });
  });
}
