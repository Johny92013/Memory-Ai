import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Leichter Stub, damit Routing-Tests ohne Supabase laufen.
class _InviteStub extends StatelessWidget {
  const _InviteStub({required this.familyId});

  final String familyId;

  @override
  Widget build(BuildContext context) {
    if (familyId.trim().isEmpty) {
      return const Scaffold(body: Text('Ungültige Familien-ID.'));
    }
    return Scaffold(body: Text('invite:$familyId'));
  }
}

void main() {
  GoRouter buildInviteRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        GoRoute(
          path: '/family/invite',
          builder: (context, state) {
            final familyId = state.uri.queryParameters['familyId'] ?? '';
            return _InviteStub(familyId: familyId);
          },
        ),
        GoRoute(
          path: '/family/:familyId/invite',
          name: 'familyInvite',
          builder: (context, state) {
            final familyId = state.pathParameters['familyId'] ?? '';
            return _InviteStub(familyId: familyId);
          },
        ),
        GoRoute(
          path: '/family',
          builder: (_, _) => const Scaffold(body: Text('FamilyOverview')),
        ),
        GoRoute(
          path: '/family-tree',
          builder: (_, _) => const Scaffold(body: Text('FamilyTree')),
        ),
      ],
    );
  }

  testWidgets('Pfad /family/:familyId/invite liefert familyId an Screen', (
    tester,
  ) async {
    final router = buildInviteRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    const familyId = '9d88f326-df69-4a6f-9b8b-219ce1b6b1fb';
    router.go('/family/$familyId/invite');
    await tester.pumpAndSettle();

    expect(find.text('invite:$familyId'), findsOneWidget);
  });

  testWidgets('Named Route familyInvite übergibt familyId', (tester) async {
    final router = buildInviteRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    const familyId = 'test-family-id';
    router.goNamed('familyInvite', pathParameters: {'familyId': familyId});
    await tester.pumpAndSettle();

    expect(find.text('invite:$familyId'), findsOneWidget);
  });

  testWidgets('Query-Route /family/invite?familyId= bleibt gültig', (
    tester,
  ) async {
    final router = buildInviteRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/family/invite?familyId=legacy-id');
    await tester.pumpAndSettle();

    expect(find.text('invite:legacy-id'), findsOneWidget);
  });

  testWidgets('leere familyId zeigt Fehlerzustand ohne Absturz', (
    tester,
  ) async {
    final router = buildInviteRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/family/%20/invite');
    await tester.pumpAndSettle();
    // Leer nach trim → Stub zeigt Fehlertext
    // Alternativ: Named mit leerem String
    router.goNamed('familyInvite', pathParameters: {'familyId': 'x'});
    await tester.pumpAndSettle();
    expect(find.text('invite:x'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(home: _InviteStub(familyId: '')));
    expect(find.text('Ungültige Familien-ID.'), findsOneWidget);
  });

  testWidgets('Family-Übersicht und Stammbaum-Routen bleiben erreichbar', (
    tester,
  ) async {
    final router = buildInviteRouter();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/family');
    await tester.pumpAndSettle();
    expect(find.text('FamilyOverview'), findsOneWidget);

    router.go('/family-tree');
    await tester.pumpAndSettle();
    expect(find.text('FamilyTree'), findsOneWidget);

    router.push('/family/abc/invite');
    await tester.pumpAndSettle();
    expect(find.text('invite:abc'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('FamilyTree'), findsOneWidget);
  });

  test('Route-Konfiguration enthält familyInvite Name', () {
    final router = buildInviteRouter();
    final named = router.configuration.namedLocation(
      'familyInvite',
      pathParameters: {'familyId': 'demo-id'},
    );
    expect(named, '/family/demo-id/invite');
  });
}
