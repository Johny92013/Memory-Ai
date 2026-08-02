import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/home/widgets/create_action_bottom_sheet.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';

/// Shell mit fester Bottom Navigation (StatefulShellRoute).
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTabSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: navigationShell.currentIndex == 0
          ? HomeDashboardColors.pageBackground
          : HomeDashboardColors.header,
      body: navigationShell,
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTabSelected,
        onPlusPressed: () => CreateActionBottomSheet.show(context),
      ),
    );
  }
}
