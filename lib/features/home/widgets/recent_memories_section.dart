import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/home/widgets/empty_memories_state.dart';
import 'package:memory_ai/features/home/widgets/recent_memory_card.dart';
import 'package:memory_ai/features/memories/data/media_item_model.dart';

/// Abschnitt „Neueste Erinnerungen“.
class RecentMemoriesSection extends StatelessWidget {
  const RecentMemoriesSection({
    super.key,
    required this.items,
    required this.onShowAll,
    required this.onItemTap,
    required this.onAddMemory,
    this.failed = false,
    this.onRetry,
  });

  final List<MediaItemModel> items;
  final VoidCallback onShowAll;
  final void Function(MediaItemModel item) onItemTap;
  final VoidCallback onAddMemory;
  final bool failed;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Neueste Erinnerungen',
                style: TextStyle(
                  color: HomeDashboardColors.primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                foregroundColor: HomeDashboardColors.link,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(44, 44),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Alle anzeigen',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (failed)
          _ErrorBlock(onRetry: onRetry)
        else if (items.isEmpty)
          EmptyMemoriesState(onAdd: onAddMemory)
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return RecentMemoryCard(
                  item: item,
                  onTap: () => onItemTap(item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HomeDashboardColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Erinnerungen konnten nicht geladen werden.',
            textAlign: TextAlign.center,
            style: TextStyle(color: HomeDashboardColors.secondaryText),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Erneut versuchen'),
            ),
          ],
        ],
      ),
    );
  }
}
