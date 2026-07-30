import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';
import 'package:memory_ai/features/family_tree/widgets/relationship_selector.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Beziehung zwischen zwei Personen zuweisen.
class AssignRelationshipScreen extends StatefulWidget {
  const AssignRelationshipScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<AssignRelationshipScreen> createState() =>
      _AssignRelationshipScreenState();
}

class _AssignRelationshipScreenState extends State<AssignRelationshipScreen> {
  final _repo = FamilyTreeRepository();
  late Future<List<FamilyTreePersonModel>> _peopleFuture;
  String? _personAId;
  String? _personBId;
  String? _type;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _peopleFuture = _repo.listPeople(widget.familyId);
  }

  Future<void> _submit() async {
    if (_personAId == null || _personBId == null || _type == null) {
      setState(() => _error = 'Bitte alle Felder ausfüllen.');
      return;
    }
    if (_personAId == _personBId) {
      setState(() => _error = 'Person A und B müssen unterschiedlich sein.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.assignRelationship(
        familyId: widget.familyId,
        personAId: _personAId!,
        personBId: _personBId!,
        type: _type!,
      );
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      setState(() => _error = ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Beziehung zuweisen',
      body: FutureBuilder<List<FamilyTreePersonModel>>(
        future: _peopleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: ErrorMapper.map(snapshot.error!).message,
              onRetry: () => setState(
                () => _peopleFuture = _repo.listPeople(widget.familyId),
              ),
            );
          }

          final people = snapshot.data ?? [];
          if (people.length < 2) {
            return const Center(
              child: Text('Mindestens zwei Personen im Stammbaum nötig.'),
            );
          }

          return LoadingOverlay(
            isLoading: _loading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _personAId,
                      decoration: const InputDecoration(
                        labelText: 'Person A',
                        filled: true,
                        fillColor: AppColors.card,
                      ),
                      items: people
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _personAId = v),
                    ),
                    const SizedBox(height: 16),
                    RelationshipSelector(
                      value: _type,
                      onChanged: (v) => setState(() => _type = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _personBId,
                      decoration: const InputDecoration(
                        labelText: 'Person B',
                        filled: true,
                        fillColor: AppColors.card,
                      ),
                      items: people
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _personBId = v),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: AppColors.accentPink),
                      ),
                    ],
                    const SizedBox(height: 28),
                    AppButton(
                      label: 'Beziehung speichern',
                      onPressed: _submit,
                      isLoading: _loading,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
