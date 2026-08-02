import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_ai/features/home/data/home_dashboard_data.dart';
import 'package:memory_ai/features/home/data/home_greeting.dart';
import 'package:memory_ai/features/home/widgets/create_action_bottom_sheet.dart';
import 'package:memory_ai/features/home/widgets/empty_memories_state.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';
import 'package:memory_ai/features/home/widgets/home_feature_grid.dart';
import 'package:memory_ai/features/home/widgets/home_header.dart';
import 'package:memory_ai/features/home/widgets/recent_memories_section.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

void main() {
  group('HomeGreeting', () {
    test('nutzt first_name aus Profil', () {
      const profile = ProfileModel(id: '1', firstName: 'Anna');
      expect(HomeGreeting.greetingLine(profile: profile), 'Hallo, Anna! 👋');
    });

    test('kein fest codierter Name Dennis', () {
      expect(
        HomeGreeting.greetingLine(profile: const ProfileModel(id: '1')),
        isNot(contains('Dennis')),
      );
    });

    test('Fallback ohne Name', () {
      expect(HomeGreeting.greetingLine(), 'Hallo! 👋');
    });

    test('nutzt E-Mail-Lokalteil', () {
      expect(
        HomeGreeting.greetingLine(email: 'michael@example.com'),
        'Hallo, michael! 👋',
      );
    });

    test('nutzt user_metadata first_name', () {
      expect(
        HomeGreeting.greetingLine(userMetadata: {'first_name': 'Michael'}),
        'Hallo, Michael! 👋',
      );
    });
  });

  group('HomeDashboardData Untertitel', () {
    test('Erinnerungen ohne Medien', () {
      const data = HomeDashboardData();
      expect(data.memoriesSubtitle, 'Noch keine Erinnerungen');
    });

    test('Erinnerungen nur Fotos', () {
      const data = HomeDashboardData(photoCount: 234);
      expect(data.memoriesSubtitle, '234 Fotos');
    });

    test('Erinnerungen Fotos und Videos', () {
      const data = HomeDashboardData(photoCount: 234, videoCount: 12);
      expect(data.memoriesSubtitle, '234 Fotos, 12 Videos');
    });

    test('Familie ohne Familie', () {
      const data = HomeDashboardData();
      expect(data.familySubtitle, 'Familie einrichten');
    });

    test('Familie mit Mitgliedern', () {
      const data = HomeDashboardData(hasFamily: true, familyMemberCount: 6);
      expect(data.familySubtitle, '6 Mitglieder');
    });

    test('Chat ohne Zählung', () {
      const data = HomeDashboardData();
      expect(data.chatSubtitle, 'Neue Nachrichten');
    });

    test('Karten-Orte', () {
      const data = HomeDashboardData(visitedLocationCount: 18);
      expect(data.mapSubtitle, '18 Orte bereist');
    });
  });

  group('Home Dashboard Widgets', () {
    testWidgets('Header zeigt Start und Begrüßung', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HomeHeader(greeting: 'Hallo, Anna! 👋')),
        ),
      );
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Hallo, Anna! 👋'), findsOneWidget);
      expect(find.text('Schön, dass du da bist.'), findsOneWidget);
      expect(find.textContaining('Dennis'), findsNothing);
    });

    testWidgets('vier Funktionskarten sichtbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeFeatureGrid(
              memoriesSubtitle: '10 Fotos',
              familySubtitle: '2 Mitglieder',
              mapSubtitle: '3 Orte bereist',
              chatSubtitle: 'Neue Nachrichten',
              onMemories: () {},
              onFamily: () {},
              onMap: () {},
              onChat: () {},
            ),
          ),
        ),
      );
      expect(find.text('Erinnerungen'), findsOneWidget);
      expect(find.text('Familie'), findsOneWidget);
      expect(find.text('Weltkarte'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
    });

    testWidgets('Karten-Callbacks funktionieren', (tester) async {
      var memories = false;
      var family = false;
      var map = false;
      var chat = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeFeatureGrid(
              memoriesSubtitle: 'x',
              familySubtitle: 'x',
              mapSubtitle: 'x',
              chatSubtitle: 'x',
              onMemories: () => memories = true,
              onFamily: () => family = true,
              onMap: () => map = true,
              onChat: () => chat = true,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Erinnerungen'));
      await tester.tap(find.text('Familie'));
      await tester.tap(find.text('Weltkarte'));
      await tester.tap(find.text('Chat'));
      expect(memories && family && map && chat, isTrue);
    });

    testWidgets('leerer Erinnerungszustand', (tester) async {
      var added = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmptyMemoriesState(onAdd: () => added = true)),
        ),
      );
      expect(find.text('Noch keine Erinnerungen'), findsOneWidget);
      await tester.tap(find.text('Erinnerung hinzufügen'));
      expect(added, isTrue);
    });

    testWidgets('neueste Erinnerungen und Alle anzeigen', (tester) async {
      var showAll = false;
      final item = MediaItemModel(
        id: 'm1',
        ownerId: 'u1',
        mediaType: 'image',
        title: 'Barcelona',
        takenAt: DateTime(2024, 5, 20),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentMemoriesSection(
              items: [item],
              onShowAll: () => showAll = true,
              onItemTap: (_) {},
              onAddMemory: () {},
            ),
          ),
        ),
      );
      expect(find.text('Neueste Erinnerungen'), findsOneWidget);
      expect(find.text('Barcelona'), findsOneWidget);
      await tester.tap(find.text('Alle anzeigen'));
      expect(showAll, isTrue);
    });

    testWidgets('Bottom Navigation Labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: HomeBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              onPlusPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('Erinnerungen'), findsOneWidget);
      expect(find.text('Karte'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.text('Chat'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('Plus öffnet Bottom Sheet Aktionen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              floatingActionButton: FloatingActionButton(
                onPressed: () => CreateActionBottomSheet.show(context),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text('Foto hinzufügen'), findsOneWidget);
      expect(find.text('Reise erstellen'), findsOneWidget);
      expect(find.text('Video hinzufügen'), findsNothing);
      expect(find.text('Album erstellen'), findsNothing);
    });

    testWidgets('kein Overflow bei 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const HomeHeader(
                  greeting: 'Hallo, Sehrlangername! 👋',
                  height: 180,
                ),
                Expanded(
                  child: HomeFeatureGrid(
                    memoriesSubtitle: 'Noch keine Erinnerungen',
                    familySubtitle: 'Familie einrichten',
                    mapSubtitle: 'Noch keine Orte',
                    chatSubtitle: 'Neue Nachrichten',
                    onMemories: () {},
                    onFamily: () {},
                    onMap: () {},
                    onChat: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('Teilfehler Erinnerungen zeigt Retry', (tester) async {
      var retry = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentMemoriesSection(
              items: const [],
              failed: true,
              onRetry: () => retry = true,
              onShowAll: () {},
              onItemTap: (_) {},
              onAddMemory: () {},
            ),
          ),
        ),
      );
      expect(find.textContaining('nicht geladen'), findsOneWidget);
      await tester.tap(find.text('Erneut versuchen'));
      expect(retry, isTrue);
    });
  });
}
