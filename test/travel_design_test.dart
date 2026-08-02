import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_theme.dart';
import 'package:memory_ai/features/home/presentation/scaffold_with_bottom_nav.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';
import 'package:memory_ai/features/map/data/map_aggregation_helper.dart';
import 'package:memory_ai/features/map/data/map_filter_state.dart';
import 'package:memory_ai/features/map/presentation/location_preview_sheet.dart';
import 'package:memory_ai/features/map/presentation/year_color_legend.dart';
import 'package:memory_ai/features/map/widgets/photo_location_marker.dart';
import 'package:memory_ai/features/map/widgets/travel_map_search_bar.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/widgets/memory_grid_tile.dart';
import 'package:memory_ai/features/memories/widgets/memory_section_header.dart';
import 'package:memory_ai/features/memories/widgets/memory_tabs.dart';
import 'package:memory_ai/features/people/widgets/face_confirmation_card.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/widgets/add_traveler_button.dart';
import 'package:memory_ai/features/trips/widgets/traveler_avatar_stack.dart';
import 'package:memory_ai/shared/widgets/app_travel_logo.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

void main() {
  group('Travel branding', () {
    testWidgets('AppTravelLogo renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: AppTravelLogo(size: 64, showWordmark: true),
          ),
        ),
      );
      expect(find.text('Memory-AI'), findsOneWidget);
    });

    test('Brand colors defined', () {
      expect(AppColors.turquoise, const Color(0xFF14B8A6));
      expect(AppColors.primaryBlue, const Color(0xFF2563EB));
      expect(AppColors.backgroundDark, const Color(0xFF071624));
      expect(AppColors.cyan, const Color(0xFF11C5C9));
    });

    test('Year colors match travel palette', () {
      expect(YearColorPalette.forYear(2022), const Color(0xFF2563EB));
      expect(YearColorPalette.forYear(2023), const Color(0xFF14B8A6));
      expect(YearColorPalette.forYear(2024), const Color(0xFFF59E0B));
      expect(YearColorPalette.forYear(2025), const Color(0xFF8B5CF6));
      expect(YearColorPalette.forYear(2026), const Color(0xFFEF5D68));
    });

    test('Dark theme uses travel surfaces', () {
      final theme = AppTheme.dark;
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.backgroundDark);
    });
  });

  group('Bottom navigation', () {
    testWidgets('shows Profil not Chat', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
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

    testWidgets('ScaffoldWithBottomNav shows bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const ScaffoldWithBottomNav(
                  selectedIndex: 0,
                  child: Center(child: Text('ShellContent')),
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('ShellContent'), findsOneWidget);
      expect(find.text('Start'), findsOneWidget);
      expect(find.byType(HomeBottomNavigation), findsOneWidget);
    });

    testWidgets('fullscreen path hides bottom nav', (tester) async {
      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.dark,
          routerConfig: GoRouter(
            initialLocation: '/map/album-viewer',
            routes: [
              GoRoute(
                path: '/map/album-viewer',
                builder: (_, _) => const ScaffoldWithBottomNav(
                  child: Center(child: Text('AlbumFullscreen')),
                ),
              ),
            ],
          ),
        ),
      );
      expect(find.text('AlbumFullscreen'), findsOneWidget);
      expect(find.byType(HomeBottomNavigation), findsNothing);
    });
  });

  group('Map chrome', () {
    testWidgets('TravelMapSearchBar visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: TravelMapSearchBar(
              controller: TextEditingController(),
              onFilterPressed: () {},
              hasActiveFilters: true,
            ),
          ),
        ),
      );
      expect(find.text('Suche nach Orten, Tagen oder Reisen'), findsOneWidget);
      expect(find.byType(TravelMapFilterButton), findsOneWidget);
    });

    testWidgets('PhotoLocationMarker without items shows place icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(body: PhotoLocationMarker(items: [])),
        ),
      );
      expect(find.byIcon(Icons.place), findsOneWidget);
    });

    testWidgets('TravelMapClusterMarker shows count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: TravelMapClusterMarker(count: 12, color: AppColors.turquoise),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('YearColorLegend visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 120,
              child: YearColorLegend(years: [2024, 2025]),
            ),
          ),
        ),
      );
      expect(find.byType(YearColorLegend), findsOneWidget);
    });

    testWidgets('LocationPreviewSheet compact card', (tester) async {
      final group = MapLocationGroup(
        key: '1.0,2.0',
        latitude: 1,
        longitude: 2,
        items: const [
          MediaItemModel(
            id: 'm1',
            ownerId: 'u1',
            mediaType: 'image',
            city: 'Bali',
            countryName: 'Indonesien',
          ),
        ],
        city: 'Bali',
        countryName: 'Indonesien',
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: LocationPreviewSheet(group: group)),
        ),
      );
      expect(find.text('Alle Erinnerungen anzeigen'), findsOneWidget);
      expect(find.textContaining('Bali'), findsWidgets);
    });
  });

  group('Memories widgets', () {
    testWidgets('MemoryTabs show four labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: MemoryTabs(
              selected: MemoryGalleryTab.all,
              onSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Alle'), findsOneWidget);
      expect(find.text('Fotos'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Reisen'), findsOneWidget);
    });

    testWidgets('MemorySectionHeader renders month', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: MemorySectionHeader(
              title: 'Juni 2024',
              subtitle: 'Bali, Indonesien',
            ),
          ),
        ),
      );
      expect(find.text('Juni 2024'), findsOneWidget);
      expect(find.text('Bali, Indonesien'), findsOneWidget);
    });

    testWidgets('VideoThumbnailOverlay shows play', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: SizedBox(
              width: 100,
              height: 100,
              child: VideoThumbnailOverlay(durationSeconds: 42),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.text('0:42'), findsOneWidget);
    });
  });

  group('People & trips widgets', () {
    testWidgets('TaggedByHeader and confirmation buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16),
              child: TaggedByHeader(name: 'Anna'),
            ),
          ),
        ),
      );
      expect(find.textContaining('Anna'), findsOneWidget);
      expect(find.text('Markiert von Anna'), findsOneWidget);
    });

    testWidgets('TravelerAvatarStack and AddTravelerButton', (tester) async {
      const members = [
        TripMemberModel(
          id: '1',
          tripId: 't1',
          userId: 'u1',
          role: 'owner',
          invitationStatus: 'accepted',
          displayName: 'Alex',
        ),
        TripMemberModel(
          id: '2',
          tripId: 't1',
          userId: 'u2',
          role: 'member',
          invitationStatus: 'accepted',
          displayName: 'Sam',
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: Column(
              children: [
                const TravelerAvatarStack(members: members),
                AddTravelerButton(onTap: () {}),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(TravelerAvatarStack), findsOneWidget);
      expect(find.text('Mitreisende hinzufügen'), findsOneWidget);
    });
  });

  group('Empty states & responsive', () {
    testWidgets('EmptyTravelState visible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: EmptyTravelState(
              title: 'Noch keine Erinnerungen',
              message: 'Deine Fotos, Videos und Reisen erscheinen hier.',
              buttonLabel: 'Erinnerung hinzufügen',
              onPressed: () {},
            ),
          ),
        ),
      );
      expect(find.text('Noch keine Erinnerungen'), findsOneWidget);
      expect(find.text('Erinnerung hinzufügen'), findsOneWidget);
    });

    testWidgets('no overflow at 320px width for nav', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            bottomNavigationBar: HomeBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              onPlusPressed: () {},
            ),
            body: const Center(child: Text('ok')),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Profil'), findsOneWidget);
    });
  });
}
