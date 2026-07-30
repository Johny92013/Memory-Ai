import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

void main() {
  group('ProfileModel', () {
    test('displayName kombiniert Vor- und Nachname', () {
      const profile = ProfileModel(
        id: '1',
        firstName: 'Anna',
        lastName: 'Müller',
      );
      expect(profile.displayName, 'Anna Müller');
    });

    test('displayName fällt auf username zurück', () {
      const profile = ProfileModel(id: '1', username: 'anna_m');
      expect(profile.displayName, 'anna_m');
    });

    test('fromJson parst profile_completed', () {
      final profile = ProfileModel.fromJson({
        'id': 'abc',
        'first_name': 'Tom',
        'profile_completed': true,
      });
      expect(profile.id, 'abc');
      expect(profile.firstName, 'Tom');
      expect(profile.profileCompleted, isTrue);
    });

    test('hasAvatar ist false ohne avatar_path', () {
      const profile = ProfileModel(id: '1');
      expect(profile.hasAvatar, isFalse);
    });

    test('hasAvatar ist true mit avatar_path', () {
      const profile = ProfileModel(id: '1', avatarPath: 'avatars/x.png');
      expect(profile.hasAvatar, isTrue);
    });
  });
}
