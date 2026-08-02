import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/map/data/memory_album_session.dart';
import 'package:memory_ai/features/memories/data/album_repository.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';

class AlbumCreationSheet extends StatefulWidget {
  const AlbumCreationSheet({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.locationLabel,
    this.tripId,
    this.familyId,
  });

  final List<MediaItemModel> items;
  final Set<String> selectedIds;
  final String locationLabel;
  final String? tripId;
  final String? familyId;

  static Future<MemoryAlbumSession?> show(
    BuildContext context, {
    required List<MediaItemModel> items,
    required Set<String> selectedIds,
    required String locationLabel,
    String? tripId,
    String? familyId,
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
          tripId: tripId,
          familyId: familyId,
        ),
      ),
    );
  }

  @override
  State<AlbumCreationSheet> createState() => _AlbumCreationSheetState();
}

class _AlbumCreationSheetState extends State<AlbumCreationSheet> {
  late final TextEditingController _title;
  final _repo = AlbumRepository();
  String _selection = 'all';
  AlbumLayout _layout = AlbumLayout.mixed;
  String? _coverId;
  bool _saving = false;

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
      case 'own':
        break;
    }
    list.sort((a, b) {
      final ad = a.takenAt ?? a.createdAt ?? DateTime(0);
      final bd = b.takenAt ?? b.createdAt ?? DateTime(0);
      return ad.compareTo(bd);
    });
    return list;
  }

  Future<void> _saveAndOpen() async {
    final items = _resolveItems();
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte mindestens ein Medium wählen.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final title = _title.text.trim().isEmpty
          ? widget.locationLabel
          : _title.text.trim();
      final cover = _coverId ?? items.first.id;
      final coverItem = items.cast<MediaItemModel?>().firstWhere(
        (i) => i?.id == cover,
        orElse: () => items.first,
      );
      final album = await _repo.createAlbum(
        title: title,
        description: widget.locationLabel,
        tripId: widget.tripId,
        familyId: widget.familyId ?? items.first.familyId,
        coverMediaId: cover,
        coverPath: coverItem?.thumbnailPath ?? coverItem?.storagePath,
        layout: AlbumRepository.layoutToDb(_layout),
        mediaItemIds: items.map((i) => i.id).toList(),
      );
      final session = await _repo.toSession(
        album,
        locationLabel: widget.locationLabel,
      );
      if (!mounted) return;
      Navigator.pop(context, session);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
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
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _selection = v ?? 'all'),
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
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _layout = v ?? AlbumLayout.mixed),
            ),
            const Spacer(),
            AppButton(
              label: _saving ? 'Speichern…' : 'Album speichern & öffnen',
              onPressed: _saving ? null : _saveAndOpen,
            ),
          ],
        ),
      ),
    );
  }
}
