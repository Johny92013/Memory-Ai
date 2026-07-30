import 'package:flutter/material.dart';
import 'package:memory_ai/features/memories/presentation/media_gallery_screen.dart';

/// Einstieg Galerie – ohne Familien-Pflicht.
class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key, this.familyId});

  final String? familyId;

  @override
  Widget build(BuildContext context) {
    return const MediaGalleryScreen();
  }
}
