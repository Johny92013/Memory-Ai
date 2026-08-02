import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/people/data/tagged_media_models.dart';
import 'package:memory_ai/features/people/data/tagged_media_repository.dart';
import 'package:memory_ai/features/people/widgets/face_confirmation_card.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// Inbox: Aufnahmen, auf denen der Nutzer markiert wurde.
class TaggedMediaInboxScreen extends StatefulWidget {
  const TaggedMediaInboxScreen({super.key});

  @override
  State<TaggedMediaInboxScreen> createState() => _TaggedMediaInboxScreenState();
}

class _TaggedMediaInboxScreenState extends State<TaggedMediaInboxScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TaggedMediaRepository();
  late final TabController _tabs;
  List<TaggedMediaItem> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.listForMe();
      if (!mounted) return;
      setState(() {
        _all = rows;
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

  List<TaggedMediaItem> _filter(List<String> statuses) =>
      _all.where((e) => statuses.contains(e.status)).toList();

  int get _openCount => _filter(MediaPersonStatus.openStatuses).length;

  Future<void> _quickConfirm(TaggedMediaItem item) async {
    try {
      await _repo.confirm(item.tagId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Markierung bestätigt.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _quickReject(TaggedMediaItem item) async {
    try {
      await _repo.reject(item.tagId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Markierung abgelehnt.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Aufnahmen mit mir',
      body: Column(
        children: [
          TabBar(
            controller: _tabs,
            labelColor: AppColors.turquoise,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.turquoise,
            tabs: [
              Tab(
                child: _TabLabel(label: 'Offen', badgeCount: _openCount),
              ),
              const Tab(text: 'Bestätigt'),
              const Tab(text: 'Abgelehnt'),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorState(message: _error!, onRetry: _load)
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _list(
                        _filter(MediaPersonStatus.openStatuses),
                        isOpenTab: true,
                      ),
                      _list(_filter(MediaPersonStatus.confirmedStatuses)),
                      _list(_filter(MediaPersonStatus.rejectedStatuses)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<TaggedMediaItem> items, {bool isOpenTab = false}) {
    if (items.isEmpty) {
      if (isOpenTab) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            EmptyTravelState(
              icon: Icons.person_search_outlined,
              title: 'Keine offenen Markierungen',
              message:
                  'Wenn dich Freunde oder Mitreisende auf Bildern markieren, '
                  'kannst du sie hier bestätigen.',
            ),
          ],
        );
      }
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          EmptyTravelState(
            icon: Icons.person_search_outlined,
            title: 'Keine Einträge',
            message: 'Hier erscheinen Markierungen, die dich betreffen.',
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.turquoise,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          final isOpen = item.isOpen;
          return FaceConfirmationCard(
            item: item,
            showQuickActions: isOpen,
            onTap: () async {
              await context.push('/profile/tagged-media/${item.tagId}');
              await _load();
            },
            onConfirm: isOpen ? () => _quickConfirm(item) : null,
            onReject: isOpen ? () => _quickReject(item) : null,
          );
        },
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.label, required this.badgeCount});

  final String label;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (badgeCount > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$badgeCount',
              style: const TextStyle(
                color: AppColors.turquoise,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
