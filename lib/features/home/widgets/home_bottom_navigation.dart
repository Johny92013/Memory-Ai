import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Travel Bottom Navigation: Start · Erinnerungen · Plus · Karte · Profil
class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.onPlusPressed,
  });

  /// 0 Start, 1 Erinnerungen, 2 Karte, 3 Profil
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final VoidCallback onPlusPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      elevation: 12,
      shadowColor: Colors.black54,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
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
                    const SizedBox(width: 64),
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
                        icon: Icons.person_outline,
                        selectedIcon: Icons.person_rounded,
                        label: 'Profil',
                        selected: selectedIndex == 3,
                        onTap: () => onDestinationSelected(3),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -16,
                  child: GestureDetector(
                    onTap: onPlusPressed,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.turquoise.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
    final color = selected ? AppColors.turquoise : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(4),
              decoration: selected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.turquoise.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    )
                  : null,
              child: Icon(
                selected ? selectedIcon : icon,
                color: color,
                size: 22,
              ),
            ),
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
