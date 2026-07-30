import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';

/// Leerer Zustand für neueste Erinnerungen.
class EmptyMemoriesState extends StatelessWidget {
  const EmptyMemoriesState({super.key, required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: HomeDashboardColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_camera_outlined,
            size: 40,
            color: HomeDashboardColors.blue.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 10),
          const Text(
            'Noch keine Erinnerungen',
            style: TextStyle(
              color: HomeDashboardColors.primaryText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lade dein erstes Foto hoch und beginne deine persönliche Reisechronik.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: HomeDashboardColors.secondaryText,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onAdd,
            style: FilledButton.styleFrom(
              backgroundColor: HomeDashboardColors.coral,
              foregroundColor: HomeDashboardColors.white,
              minimumSize: const Size(44, 44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Erinnerung hinzufügen'),
          ),
        ],
      ),
    );
  }
}
