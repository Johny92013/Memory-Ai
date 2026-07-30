import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

class AlbumCreationSheet extends StatefulWidget {
  const AlbumCreationSheet({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.locationLabel,
  });

  final List<MediaItemModel> items;
  final Set<String> selectedIds;
  final String locationLabel;

  static Future<MemoryAlbumSession?> show(
    BuildContext context, {
    required List<MediaItemModel> items,
    required Set<String> selectedIds,
    required String locationLabel,
  }) {
    return showModalBottomSheet<MemoryAlbumSession>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.7,
        child: AlbumCreationSheet(
          items: items,
          selectedIds: selectedIds,
          locationLabel: locationLabel,
        ),
      ),
    );
  }

  @override
  State<AlbumCreationSheet> createState() => _AlbumCreationSheetState();
}

class _AlbumCreationSheetState extends State<AlbumCreationSheet> {
  late final TextEditingController _title;
  String _selection = 'all';
  AlbumLayout _layout = AlbumLayout.mixed;
  String? _coverId;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.locationLabel);
    _coverId = widget.items.isEmpty ? null : widget.items.first.id;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<MediaItemModel> _resolveItems() {
    var list = List<MediaItemModel>.from(widget.items);
    switch (_selection) {
      case 'selected':
        if (widget.selectedIds.isNotEmpty) {
          list = list.where((i) => widget.selectedIds.contains(i.id)).toList();
        }
        break;
      case 'photos':
        list = list.where((i) => i.mediaType == 'image').toList();
        break;
      case 'photosAndVideoThumbs':
        // Videos behalten (als Vorschaubilder im Album)
        break;
      case 'own':
        // Owner-Filter erfolgt bereits durch Quelle; hier noop
        break;
    }
    list.sort((a, b) {
      final ad = a.takenAt ?? a.createdAt ?? DateTime(0);
      final bd = b.takenAt ?? b.createdAt ?? DateTime(0);
      return ad.compareTo(bd);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Album erstellen',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Albumtitel'),
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<String>(
              initialValue: _selection,
              decoration: const InputDecoration(labelText: 'Medienauswahl'),
              items: const [
                DropdownMenuItem(
                  value: 'all',
                  child: Text('Alle Medien des Orts'),
                ),
                DropdownMenuItem(
                  value: 'selected',
                  child: Text('Manuelle Auswahl'),
                ),
                DropdownMenuItem(value: 'photos', child: Text('Nur Fotos')),
                DropdownMenuItem(
                  value: 'photosAndVideoThumbs',
                  child: Text('Fotos + Video-Vorschaubilder'),
                ),
              ],
              onChanged: (v) => setState(() => _selection = v ?? 'all'),
            ),
            DropdownButtonFormField<AlbumLayout>(
              initialValue: _layout,
              decoration: const InputDecoration(labelText: 'Layout'),
              items: const [
                DropdownMenuItem(
                  value: AlbumLayout.single,
                  child: Text('Ein Bild / Seite'),
                ),
                DropdownMenuItem(
                  value: AlbumLayout.doublePage,
                  child: Text('Zwei Bilder / Seite'),
                ),
                DropdownMenuItem(
                  value: AlbumLayout.collage,
                  child: Text('Collage'),
                ),
                DropdownMenuItem(
                  value: AlbumLayout.mixed,
                  child: Text('Automatische Mischung'),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _layout = v ?? AlbumLayout.mixed),
            ),
            const Spacer(),
            AppButton(
              label: 'Album öffnen',
              onPressed: () {
                final items = _resolveItems();
                Navigator.pop(
                  context,
                  MemoryAlbumSession(
                    title: _title.text.trim().isEmpty
                        ? widget.locationLabel
                        : _title.text.trim(),
                    items: items,
                    coverMediaId: _coverId,
                    locationLabel: widget.locationLabel,
                    layout: _layout,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
