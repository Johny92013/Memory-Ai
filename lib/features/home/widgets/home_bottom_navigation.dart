import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';

/// Feste untere Navigation mit zentralem Plus-Button.
class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onPlusPressed,
  });

  /// Index der sichtbaren Tabs: 0 Start, 1 Erinnerungen, 2 Karte, 3 Chat.
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onPlusPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: HomeDashboardColors.white,
      elevation: 8,
      shadowColor: HomeDashboardColors.cardShadow,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _NavItem(
                      icon: Icons.home_outlined,
                      selectedIcon: Icons.home_rounded,
                      label: 'Start',
                      selected: selectedIndex == 0,
                      onTap: () => onDestinationSelected(0),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.photo_library_outlined,
                      selectedIcon: Icons.photo_library,
                      label: 'Erinnerungen',
                      selected: selectedIndex == 1,
                      onTap: () => onDestinationSelected(1),
                    ),
                  ),
                  const SizedBox(width: 56),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.map_outlined,
                      selectedIcon: Icons.map_rounded,
                      label: 'Karte',
                      selected: selectedIndex == 2,
                      onTap: () => onDestinationSelected(2),
                    ),
                  ),
                  Expanded(
                    child: _NavItem(
                      icon: Icons.chat_bubble_outline,
                      selectedIcon: Icons.chat_bubble,
                      label: 'Chat',
                      selected: selectedIndex == 3,
                      onTap: () => onDestinationSelected(3),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -12,
                child: GestureDetector(
                  onTap: onPlusPressed,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: HomeDashboardColors.plusButton,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: HomeDashboardColors.plusButton.withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: HomeDashboardColors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? HomeDashboardColors.navActive
        : HomeDashboardColors.navInactive;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? selectedIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
