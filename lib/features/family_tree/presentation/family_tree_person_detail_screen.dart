import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';
import 'package:memory_ai/features/family_tree/widgets/family_tree_person_card.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Detailansicht einer Stammbaum-Person.
class FamilyTreePersonDetailScreen extends StatefulWidget {
  const FamilyTreePersonDetailScreen({
    super.key,
    required this.personId,
    required this.familyId,
  });

  final String personId;
  final String familyId;

  @override
  State<FamilyTreePersonDetailScreen> createState() =>
      _FamilyTreePersonDetailScreenState();
}

class _FamilyTreePersonDetailScreenState
    extends State<FamilyTreePersonDetailScreen> {
  final _repo = FamilyTreeRepository();
  late Future<FamilyTreePersonModel?> _personFuture;

  @override
  void initState() {
    super.initState();
    _personFuture = _loadPerson();
  }

  Future<FamilyTreePersonModel?> _loadPerson() async {
    final people = await _repo.listPeople(widget.familyId);
    for (final person in people) {
      if (person.id == widget.personId) return person;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Person',
      body: FutureBuilder<FamilyTreePersonModel?>(
        future: _personFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: ErrorMapper.map(snapshot.error!).message,
              onRetry: () => setState(() => _personFuture = _loadPerson()),
            );
          }

          final person = snapshot.data;
          if (person == null) {
            return const Center(child: Text('Person nicht gefunden.'));
          }

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                FamilyTreePersonCard(person: person, width: 200),
                const SizedBox(height: 24),
                if (person.notes != null && person.notes!.isNotEmpty)
                  Text(
                    person.notes!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                const Spacer(),
                AppButton(
                  label: 'Bearbeiten',
                  icon: Icons.edit_outlined,
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      '/family-tree/person/${widget.personId}/edit'
                      '?familyId=${widget.familyId}',
                    );
                    if (updated == true && mounted) {
                      setState(() => _personFuture = _loadPerson());
                    }
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
