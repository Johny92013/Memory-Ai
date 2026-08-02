import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';
import 'package:memory_ai/features/people/data/tagged_media_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// Detailansicht einer Markierung mit Freigabe-Aktionen.
class TaggedMediaDetailScreen extends StatefulWidget {
  const TaggedMediaDetailScreen({super.key, required this.tagId});

  final String tagId;

  @override
  State<TaggedMediaDetailScreen> createState() =>
      _TaggedMediaDetailScreenState();
}

class _TaggedMediaDetailScreenState extends State<TaggedMediaDetailScreen> {
  final _repo = TaggedMediaRepository();
  TaggedMediaItem? _item;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.listForMe();
      final match = rows.where((e) => e.tagId == widget.tagId).firstOrNull;
      if (!mounted) return;
      if (match == null) {
        setState(() {
          _loading = false;
          _error = 'Die Markierung konnte nicht geladen werden.';
        });
        return;
      }
      setState(() {
        _item = match;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gespeichert.')));
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Markierung',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _item == null) {
      return AppScaffold(
        title: 'Markierung',
        body: ErrorState(message: _error ?? 'Unbekannt', onRetry: _load),
      );
    }

    final item = _item!;
    final dateFmt = DateFormat.yMMMMd('de').add_Hm();

    return AppScaffold(
      title: 'Markierung',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          FutureBuilder<String?>(
            future: item.thumbnailPath != null && item.thumbnailPath!.isNotEmpty
                ? SignedUrlService.mediaThumbnailUrl(item.thumbnailPath)
                : SignedUrlService.mediaPhotoUrl(item.storagePath),
            builder: (context, snap) {
              if (snap.data == null) {
                return const SizedBox(
                  height: 240,
                  child: Center(child: Icon(Icons.image_outlined, size: 64)),
                );
              }
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: snap.data!,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Markiert von ${item.taggedByName ?? 'Unbekannt'}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Aufnahme von ${item.ownerName ?? 'Unbekannt'}'),
          if (item.takenAt != null) Text(dateFmt.format(item.takenAt!)),
          Text(item.placeLabel),
          if (item.tripTitle != null) Text('Reise: ${item.tripTitle}'),
          if (item.familyName != null) Text('Familie: ${item.familyName}'),
          Text('Status: ${item.status}'),
          const SizedBox(height: AppSpacing.xl),
          if (item.isOpen ||
              item.status == MediaPersonStatus.confirmed ||
              item.status == MediaPersonStatus.linkedOnly) ...[
            GradientPrimaryButton(
              label: 'Ja, das bin ich',
              onPressed: _busy
                  ? null
                  : () => _run(() => _repo.confirm(item.tagId)),
            ),
            const SizedBox(height: AppSpacing.sm),
            DarkSecondaryButton(
              label: 'In meine Galerie',
              onPressed: _busy
                  ? null
                  : () => _run(() => _repo.acceptToGallery(item.tagId)),
            ),
            const SizedBox(height: AppSpacing.sm),
            DarkSecondaryButton(
              label: 'Nein, nicht ich',
              onPressed: _busy
                  ? null
                  : () => _run(() => _repo.reject(item.tagId)),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => _repo.linkOnly(item.tagId)),
              child: const Text('Nur verknüpft lassen'),
            ),
          ] else if (item.status == MediaPersonStatus.acceptedToGallery) ...[
            const Text(
              'In deiner Galerie verknüpft (keine Dateikopie). '
              'Eigentümer bleibt der Uploader.',
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: () => context.push('/media/${item.mediaId}'),
              child: const Text('Medium öffnen'),
            ),
          ] else ...[
            Text('Diese Markierung ist ${item.status}.'),
          ],
        ],
      ),
    );
  }
}
