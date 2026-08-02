import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/features/home/presentation/home_screen.dart';
import 'package:memory_ai/features/home/presentation/scaffold_with_bottom_nav.dart';
import 'package:memory_ai/features/home/widgets/create_action_bottom_sheet.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';
import 'package:memory_ai/features/map/presentation/world_map_screen.dart';
import 'package:memory_ai/features/memories/presentation/memories_screen.dart';
import 'package:memory_ai/features/profile/presentation/profile_screen.dart';

/// Hauptnavigation: Start · Erinnerungen · Plus · Karte · Profil
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _pageIndex;

  static const _pages = <Widget>[
    HomeScreen(),
    MemoriesScreen(),
    ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(child: WorldMapScreen()),
    ),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialIndex.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant MainNavigationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _pageIndex = widget.initialIndex.clamp(0, 3);
    }
  }

  void _onNavSelected(int tabIndex) {
    if (tabIndex == _pageIndex) return;
    if (tabIndex == 3) {
      context.go(AppTabPaths.profile);
      return;
    }
    context.go(AppTabPaths.tabs[tabIndex]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: _pageIndex,
        onDestinationSelected: _onNavSelected,
        onPlusPressed: () => CreateActionBottomSheet.show(context),
      ),
    );
  }
}
