import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/chat/presentation/chat_overview_screen.dart';
import 'package:memory_ai/features/home/presentation/home_screen.dart';
import 'package:memory_ai/features/home/widgets/create_action_bottom_sheet.dart';
import 'package:memory_ai/features/home/widgets/home_bottom_navigation.dart';
import 'package:memory_ai/features/map/presentation/world_map_screen.dart';
import 'package:memory_ai/features/memories/presentation/memories_screen.dart';

/// Hauptnavigation: Start · Erinnerungen · Plus · Karte · Chat
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _pageIndex = 0;

  static const _pages = <Widget>[
    HomeScreen(),
    MemoriesScreen(),
    ColoredBox(
      color: HomeDashboardColors.pageBackground,
      child: SafeArea(child: WorldMapScreen()),
    ),
    ChatOverviewScreen(),
  ];

  void _onNavSelected(int tabIndex) {
    setState(() => _pageIndex = tabIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageIndex == 0
          ? HomeDashboardColors.pageBackground
          : HomeDashboardColors.header,
      body: IndexedStack(index: _pageIndex, children: _pages),
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: _pageIndex,
        onDestinationSelected: _onNavSelected,
        onPlusPressed: () => CreateActionBottomSheet.show(context),
      ),
    );
  }
}
