import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/features/people/data/tagged_media_repository.dart';

/// Start-Karte: offene Personen-Markierungen.
class TaggedMediaNotificationCard extends StatefulWidget {
  const TaggedMediaNotificationCard({super.key});

  @override
  State<TaggedMediaNotificationCard> createState() =>
      _TaggedMediaNotificationCardState();
}

class _TaggedMediaNotificationCardState
    extends State<TaggedMediaNotificationCard> {
  final _tags = TaggedMediaRepository();
  final _notes = InAppNotificationRepository();
  int _openCount = 0;
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final open = await _tags.listForMe(
        statuses: ['suggested', 'pending_confirmation'],
      );
      final unread = await _notes.countUnread();
      if (!mounted) return;
      setState(() {
        _openCount = open.length;
        _unread = unread;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || (_openCount == 0 && _unread == 0)) {
      return const SizedBox.shrink();
    }
    final label = _openCount == 1
        ? 'Du wurdest auf 1 Erinnerung markiert.'
        : _openCount > 1
        ? 'Du wurdest auf $_openCount Erinnerungen markiert.'
        : 'Neue Markierungs-Hinweise.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ListTile(
          leading: Badge(
            isLabelVisible: _unread > 0 || _openCount > 0,
            label: Text('${_openCount > 0 ? _openCount : _unread}'),
            child: const Icon(Icons.person_pin_outlined),
          ),
          title: const Text('Aufnahmen mit mir'),
          subtitle: Text(label),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/profile/tagged-media'),
        ),
      ),
    );
  }
}
