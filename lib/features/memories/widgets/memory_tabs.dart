import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Medien-Tabs für die Erinnerungen-Galerie.
enum MemoryGalleryTab { all, photos, videos, trips }

extension MemoryGalleryTabLabel on MemoryGalleryTab {
  String get label => switch (this) {
    MemoryGalleryTab.all => 'Alle',
    MemoryGalleryTab.photos => 'Fotos',
    MemoryGalleryTab.videos => 'Videos',
    MemoryGalleryTab.trips => 'Reisen',
  };
}

class MemoryTabs extends StatelessWidget {
  const MemoryTabs({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final MemoryGalleryTab selected;
  final ValueChanged<MemoryGalleryTab> onSelected;

  static const _tabs = MemoryGalleryTab.values;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 20),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final isActive = tab == selected;
          return InkWell(
            onTap: () => onSelected(tab),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? AppColors.turquoise
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 2,
                  width: isActive ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.turquoise,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
