import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_link_model.dart';
import 'package:memory_ai/features/memories/data/related_media_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Vorschläge und bestätigte Verknüpfungen zu verwandten Medien.
class RelatedMediaSuggestions extends StatefulWidget {
  const RelatedMediaSuggestions({
    super.key,
    required this.mediaId,
    this.familyId,
  });

  final String mediaId;
  final String? familyId;

  @override
  State<RelatedMediaSuggestions> createState() =>
      _RelatedMediaSuggestionsState();
}

class _RelatedMediaSuggestionsState extends State<RelatedMediaSuggestions> {
  final _service = RelatedMediaService();
  List<MediaLinkModel> _suggested = [];
  List<MediaItemModel> _confirmed = [];
  bool _loading = true;
  String _scope = 'own';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final candidates = await _service.suggestForMedia(
        widget.mediaId,
        scope: _scope,
        familyId: widget.familyId,
      );
      await _service.persistSuggestions(candidates);
      final suggested = await _service.listSuggestions(widget.mediaId);
      final confirmed = await _service.loadLinkedMediaItems(widget.mediaId);
      if (!mounted) return;
      setState(() {
        _suggested = suggested;
        _confirmed = confirmed;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _confirm(MediaLinkModel link) async {
    try {
      await _service.confirm(link.id);
      MediaChangeNotifier.instance.notifyMediaChanged();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _reject(MediaLinkModel link) async {
    try {
      await _service.reject(link.id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  String _relatedId(MediaLinkModel link) => link.sourceMediaId == widget.mediaId
      ? link.relatedMediaId
      : link.sourceMediaId;

  @override
  Widget build(BuildContext context) {
    final count = _suggested.length + _confirmed.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          count > 0 ? 'Verwandte Medien ($count)' : 'Verwandte Medien',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'own', label: Text('Eigene')),
            ButtonSegment(value: 'family', label: Text('Familie')),
            ButtonSegment(value: 'all', label: Text('Alle')),
          ],
          selected: {_scope},
          onSelectionChanged: (s) {
            setState(() => _scope = s.first);
            _load();
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (_suggested.isNotEmpty) ...[
            Text(
              _suggested.length == 1
                  ? '1 Vorschlag zu diesem Ereignis'
                  : '${_suggested.length} weitere Bilder von diesem Ereignis',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            ..._suggested.map((link) {
              final id = _relatedId(link);
              return Card(
                color: AppColors.surface,
                child: ListTile(
                  title: Text('Medium ${id.substring(0, 8)}…'),
                  subtitle: Text(
                    '${link.relationType} · '
                    '${((link.confidence ?? 0) * 100).round()}%',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _confirm(link),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.error),
                        onPressed: () => _reject(link),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/media/$id'),
                ),
              );
            }),
          ],
          if (_confirmed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Bestätigt', style: Theme.of(context).textTheme.labelLarge),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _confirmed.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final item = _confirmed[i];
                  return InkWell(
                    onTap: () => context.push('/media/${item.id}'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: FutureBuilder<String?>(
                          future: SignedUrlService.mediaThumbnailUrl(
                            item.thumbnailPath,
                          ),
                          builder: (context, snap) {
                            final url = snap.data;
                            if (url == null) {
                              return Container(color: AppColors.surface);
                            }
                            return CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (_suggested.isEmpty && _confirmed.isEmpty)
            Text(
              'Keine verwandten Medien gefunden.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
        ],
      ],
    );
  }
}
