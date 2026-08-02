import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/features/home/widgets/create_action_bottom_sheet.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';

/// Pfade der Haupt-Tabs (Bottom Nav).
abstract final class AppTabPaths {
  static const home = '/home';
  static const memories = '/home?tab=1';
  static const map = '/home?tab=2';
  static const profile = '/profile';

  static const tabs = <String>[
    '/home',
    '/home?tab=1',
    '/home?tab=2',
    '/profile',
  ];

  /// Vollbild-Routen ohne Bottom Navigation.
  static bool isFullscreenPath(String path) {
    return path.contains('/album-viewer') ||
        path.contains('/slideshow') ||
        path.contains('/player') ||
        path.startsWith('/album/') ||
        path.endsWith('/fullscreen');
  }

  static int indexForLocation(String location, {String? tabParam}) {
    final tab = int.tryParse(tabParam ?? '');
    if (tab != null) return tab.clamp(0, 3);
    if (location.startsWith('/profile') ||
        location.startsWith('/settings') ||
        location.startsWith('/family')) {
      return 3;
    }
    if (location.startsWith('/memories') ||
        location.startsWith('/media') ||
        location.startsWith('/timeline') ||
        location.startsWith('/upload') ||
        location.startsWith('/trips')) {
      return 1;
    }
    if (location.startsWith('/map') || location.startsWith('/location')) {
      return 2;
    }
    return 0;
  }
}

/// Hält die Bottom Navigation auf normalen Seiten sichtbar (iOS ohne Hardware-Zurück).
class ScaffoldWithBottomNav extends StatelessWidget {
  const ScaffoldWithBottomNav({
    super.key,
    required this.child,
    this.selectedIndex,
    this.backgroundColor,
  });

  final Widget child;
  final int? selectedIndex;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (AppTabPaths.isFullscreenPath(location)) {
      return child;
    }
    final tabParam = GoRouterState.of(context).uri.queryParameters['tab'];
    final index =
        selectedIndex ??
        AppTabPaths.indexForLocation(location, tabParam: tabParam);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: index.clamp(0, 3),
        onDestinationSelected: (i) => context.go(AppTabPaths.tabs[i]),
        onPlusPressed: () => CreateActionBottomSheet.show(context),
      ),
    );
  }
}
