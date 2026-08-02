import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Legacy-Screen: leitet auf den aktuellen Upload-Flow (`media_items`) um.
class UploadMemoryScreen extends StatelessWidget {
  const UploadMemoryScreen({super.key, this.familyId});

  final String? familyId;

  @override
  Widget build(BuildContext context) {
    final query = <String, String>{
      if (familyId != null && familyId!.isNotEmpty) 'familyId': familyId!,
    };
    final target = Uri(
      path: '/memories/upload',
      queryParameters: query.isEmpty ? null : query,
    ).toString();

    return AppScaffold(
      title: 'Upload',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dieser Upload-Weg ist veraltet.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Neue Erinnerungen werden in media_items gespeichert. '
              'Bitte nutze den aktuellen Upload.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Zum aktuellen Upload',
              onPressed: () => context.go(target),
            ),
          ],
        ),
      ),
    );
  }
}
