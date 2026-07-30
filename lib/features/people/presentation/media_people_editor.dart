import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/media_change_notifier.dart';
import 'package:memory_ai/features/memories/data/people_repository.dart';
import 'package:memory_ai/features/memories/data/person_model.dart';
import 'package:memory_ai/features/people/data/face_suggestion_review.dart';
import 'package:memory_ai/features/people/presentation/person_picker.dart';

/// Abschnitt „Personen auf diesem Medium“ inkl. Vorschläge und Batch.
class MediaPeopleEditor extends StatefulWidget {
  const MediaPeopleEditor({
    super.key,
    required this.mediaId,
    required this.people,
    this.suggestions = const [],
    this.familyId,
    this.otherMediaIds = const [],
    this.onChanged,
  });

  final String mediaId;
  final List<PersonModel> people;
  final List<PersonModel> suggestions;
  final String? familyId;
  final List<String> otherMediaIds;
  final VoidCallback? onChanged;

  @override
  State<MediaPeopleEditor> createState() => _MediaPeopleEditorState();
}

class _MediaPeopleEditorState extends State<MediaPeopleEditor> {
  final _repo = PeopleRepository();
  final _review = FaceSuggestionReview();
  late List<PersonModel> _people;
  late List<PersonModel> _suggestions;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _people = List.of(widget.people);
    _suggestions = List.of(widget.suggestions);
  }

  @override
  void didUpdateWidget(covariant MediaPeopleEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.people != widget.people) {
      _people = List.of(widget.people);
    }
    if (oldWidget.suggestions != widget.suggestions) {
      _suggestions = List.of(widget.suggestions);
    }
  }

  Future<void> _add() async {
    final picked = await PersonPicker.show(
      context,
      multiSelect: true,
      preselectedIds: _people.map((p) => p.id).toSet(),
      familyId: widget.familyId,
    );
    if (picked == null || picked.isEmpty) return;
    setState(() => _busy = true);
    try {
      for (final person in picked) {
        await _repo.assignPersonToMedia(
          mediaId: widget.mediaId,
          personId: person.id,
        );
      }
      if (widget.otherMediaIds.isNotEmpty) {
        if (!mounted) return;
        final apply = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Auch auf andere Medien?'),
            content: Text(
              'Personen auf ${widget.otherMediaIds.length} weitere Medien anwenden?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nur dieses'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Auf alle'),
              ),
            ],
          ),
        );
        if (apply == true) {
          await _repo.assignPeopleToManyMedia(
            mediaIds: widget.otherMediaIds,
            personIds: picked.map((p) => p.id).toList(),
          );
        }
      }
      MediaChangeNotifier.instance.notifyMediaChanged();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PersonModel person) async {
    setState(() => _busy = true);
    try {
      await _repo.unassignPersonFromMedia(
        mediaId: widget.mediaId,
        personId: person.id,
      );
      MediaChangeNotifier.instance.notifyMediaChanged();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmSuggestion(PersonModel person) async {
    setState(() => _busy = true);
    try {
      await _review.confirm(mediaId: widget.mediaId, personId: person.id);
      MediaChangeNotifier.instance.notifyMediaChanged();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectSuggestion(PersonModel person) async {
    setState(() => _busy = true);
    try {
      await _review.reject(mediaId: widget.mediaId, personId: person.id);
      MediaChangeNotifier.instance.notifyMediaChanged();
      widget.onChanged?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Personen auf diesem Medium',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (_busy)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                onPressed: _add,
                icon: const Icon(Icons.person_add_alt),
                tooltip: 'Personen hinzufügen',
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_people.isEmpty)
          Text(
            'Noch keine Personen zugeordnet.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _people
                .map(
                  (p) => InputChip(
                    label: Text(p.name),
                    onDeleted: _busy ? null : () => _remove(p),
                  ),
                )
                .toList(),
          ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Vorgeschlagene Personen',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nur Vorschläge – bitte bestätigen oder ablehnen.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final p in _suggestions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Möglicherweise ${p.name}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ablehnen',
                    onPressed: _busy ? null : () => _rejectSuggestion(p),
                    icon: const Icon(Icons.close),
                  ),
                  IconButton(
                    tooltip: 'Bestätigen',
                    onPressed: _busy ? null : () => _confirmSuggestion(p),
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
