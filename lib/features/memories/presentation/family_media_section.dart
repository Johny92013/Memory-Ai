import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';
import 'package:memory_ai/features/memories/data/media_repository.dart';

/// Familienmedien mit Zugriff (RLS); nicht berechtigte bleiben unsichtbar.
class FamilyMediaSection extends StatefulWidget {
  const FamilyMediaSection({
    super.key,
    required this.familyId,
    this.excludeMediaId,
  });

  final String familyId;
  final String? excludeMediaId;

  @override
  State<FamilyMediaSection> createState() => _FamilyMediaSectionState();
}

class _FamilyMediaSectionState extends State<FamilyMediaSection> {
  final _repo = MediaRepository();
  List<MediaItemModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repo.listAccessibleMedia(
        scope: 'family',
        familyId: widget.familyId,
        limit: 40,
      );
      final filtered = items
          .where((m) => m.id != widget.excludeMediaId)
          .toList();
      if (!mounted) return;
      setState(() {
        _items = filtered;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Familienmedien', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_items.isEmpty)
          Text(
            'Keine zugänglichen Familienmedien.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final item = _items[i];
                return InkWell(
                  onTap: () => context.push('/media/${item.id}'),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: FutureBuilder<String?>(
                        future: SignedUrlService.mediaThumbnailUrl(
                          item.thumbnailPath,
                        ),
                        builder: (context, snap) {
                          final url = snap.data;
                          if (url == null) {
                            return Container(
                              color: AppColors.surface,
                              child: const Icon(Icons.image_outlined),
                            );
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
    );
  }
}
