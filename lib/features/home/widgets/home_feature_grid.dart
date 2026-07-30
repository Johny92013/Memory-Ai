import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/home/widgets/home_feature_card.dart';

/// 2×2-Funktionsraster der Startseite.
class HomeFeatureGrid extends StatelessWidget {
  const HomeFeatureGrid({
    super.key,
    required this.memoriesSubtitle,
    required this.familySubtitle,
    required this.mapSubtitle,
    required this.chatSubtitle,
    required this.onMemories,
    required this.onFamily,
    required this.onMap,
    required this.onChat,
  });

  final String memoriesSubtitle;
  final String familySubtitle;
  final String mapSubtitle;
  final String chatSubtitle;
  final VoidCallback onMemories;
  final VoidCallback onFamily;
  final VoidCallback onMap;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxWidth < 340 ? 105.0 : 112.0;
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: (constraints.maxWidth - 8) / 2 / cardHeight,
          children: [
            HomeFeatureCard(
              title: 'Erinnerungen',
              subtitle: memoriesSubtitle,
              icon: Icons.photo_library_outlined,
              background: HomeDashboardColors.blueSoft,
              iconColor: HomeDashboardColors.blue,
              onTap: onMemories,
            ),
            HomeFeatureCard(
              title: 'Familie',
              subtitle: familySubtitle,
              icon: Icons.groups_outlined,
              background: HomeDashboardColors.greenSoft,
              iconColor: HomeDashboardColors.green,
              onTap: onFamily,
            ),
            HomeFeatureCard(
              title: 'Weltkarte',
              subtitle: mapSubtitle,
              icon: Icons.public,
              background: HomeDashboardColors.violetSoft,
              iconColor: HomeDashboardColors.violet,
              onTap: onMap,
            ),
            HomeFeatureCard(
              title: 'Chat',
              subtitle: chatSubtitle,
              icon: Icons.chat_bubble_outline,
              background: HomeDashboardColors.coralSoft,
              iconColor: HomeDashboardColors.coral,
              onTap: onChat,
            ),
          ],
        );
      },
    );
  }
}
