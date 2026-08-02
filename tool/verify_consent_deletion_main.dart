import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memory_ai/features/people/data/face_consent_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Live verification entrypoint (not the app UI).
///
///   flutter run -d chrome -t tool/verify_consent_deletion_main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  final url = dotenv.env['SUPABASE_URL'];
  final key =
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || key == null) {
    debugPrint('SUPABASE_URL / KEY missing');
    return;
  }

  await Supabase.initialize(url: url, publishableKey: key);
  final client = Supabase.instance.client;

  const email = String.fromEnvironment('TEST_CONSENT_EMAIL');
  const password = String.fromEnvironment('TEST_CONSENT_PASSWORD');
  if (email.isEmpty || password.isEmpty) {
    debugPrint(
      'Set --dart-define=TEST_CONSENT_EMAIL=... and TEST_CONSENT_PASSWORD=...',
    );
    return;
  }

  try {
    final auth = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    final userId = auth.user?.id;
    if (userId == null) {
      debugPrint('Sign-in failed');
      return;
    }
    debugPrint('SIGNED_IN=$userId');

    Future<int> countDetections() async {
      final rows = await client
          .from('media_face_detections')
          .select('id')
          .eq('owner_id', userId);
      return (rows as List).length;
    }

    Future<int> countRefs() async {
      final rows = await client
          .from('face_reference_embeddings')
          .select('id')
          .eq('user_id', userId);
      return (rows as List).length;
    }

    Future<({int suggested, int protectedCount})> countPeopleLinks() async {
      final media = await client
          .from('media_items')
          .select('id')
          .eq('owner_id', userId);
      final mediaIds = (media as List)
          .map((r) => (r as Map)['id'] as String)
          .toList();
      if (mediaIds.isEmpty) {
        return (suggested: 0, protectedCount: 0);
      }

      final links = await client
          .from('media_people')
          .select('id, source, status')
          .inFilter('media_item_id', mediaIds);
      var suggested = 0;
      var protectedCount = 0;
      for (final row in links as List) {
        final m = Map<String, dynamic>.from(row as Map);
        final source = m['source'] as String? ?? '';
        final status = m['status'] as String? ?? '';
        if (source == 'face_recognition' && status == 'suggested') {
          suggested++;
        }
        if (status == 'confirmed' || source == 'manual') {
          protectedCount++;
        }
      }
      return (suggested: suggested, protectedCount: protectedCount);
    }

    final consent = FaceConsentService();

    final detBefore = await countDetections();
    debugPrint('BIOMETRIC_BEFORE_DETECTIONS=$detBefore');
    await consent.revokeDetection();
    final detAfter = await countDetections();
    debugPrint('BIOMETRIC_AFTER_DETECTIONS=$detAfter');

    final refsBefore = await countRefs();
    final peopleBeforeRef = await countPeopleLinks();
    debugPrint('FACE_REF_BEFORE_EMBEDDINGS=$refsBefore');
    debugPrint(
      'FACE_REF_BEFORE_SUGGESTED=${peopleBeforeRef.suggested} '
      'PROTECTED=${peopleBeforeRef.protectedCount}',
    );
    await consent.revokeFaceReference();
    final refsAfter = await countRefs();
    final peopleAfterRef = await countPeopleLinks();
    debugPrint('FACE_REF_AFTER_EMBEDDINGS=$refsAfter');
    debugPrint(
      'FACE_REF_AFTER_SUGGESTED=${peopleAfterRef.suggested} '
      'PROTECTED=${peopleAfterRef.protectedCount}',
    );

    final peopleBeforeFam = await countPeopleLinks();
    debugPrint(
      'FAMILY_BEFORE_SUGGESTED=${peopleBeforeFam.suggested} '
      'PROTECTED=${peopleBeforeFam.protectedCount}',
    );
    await consent.revokeFamilyMatching();
    final peopleAfterFam = await countPeopleLinks();
    debugPrint(
      'FAMILY_AFTER_SUGGESTED=${peopleAfterFam.suggested} '
      'PROTECTED=${peopleAfterFam.protectedCount}',
    );

    final ok =
        detBefore > 0 &&
        detAfter == 0 &&
        refsBefore > 0 &&
        refsAfter == 0 &&
        peopleAfterFam.suggested == 0 &&
        peopleAfterFam.protectedCount == peopleBeforeFam.protectedCount &&
        peopleAfterFam.protectedCount > 0;

    debugPrint(ok ? 'VERIFY_RESULT=PASS' : 'VERIFY_RESULT=FAIL');
    await client.auth.signOut();
  } catch (e, st) {
    debugPrint('ERROR=$e');
    debugPrint('$st');
  }
}
