import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Album-Detail (Phase 4).
class AlbumDetailScreen extends StatelessWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Album',
      body: Center(
        child: Text(
          'Album $albumId – Phase 4',
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
