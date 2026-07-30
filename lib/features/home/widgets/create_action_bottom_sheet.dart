import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';

/// Bottom Sheet mit unterstützten Erstellen-Aktionen.
class CreateActionBottomSheet extends StatelessWidget {
  const CreateActionBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: HomeDashboardColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateActionBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: HomeDashboardColors.secondaryText.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hinzufügen',
              style: TextStyle(
                color: HomeDashboardColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_outlined,
                color: HomeDashboardColors.blue,
              ),
              title: const Text('Foto hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                context.push('/memories/upload');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: HomeDashboardColors.blue,
              ),
              title: const Text('Mehrere Fotos hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                context.push('/memories/upload');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.flight_takeoff,
                color: HomeDashboardColors.violet,
              ),
              title: const Text('Reise erstellen'),
              onTap: () {
                Navigator.pop(context);
                context.push('/trips/create');
              },
            ),
          ],
        ),
      ),
    );
  }
}
