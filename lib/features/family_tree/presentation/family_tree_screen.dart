import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family_tree/data/family_relationship_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';
import 'package:memory_ai/features/family_tree/widgets/family_tree_canvas.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Interaktiver Familienstammbaum.
class FamilyTreeScreen extends StatefulWidget {
  const FamilyTreeScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<FamilyTreeScreen> createState() => _FamilyTreeScreenState();
}

class _FamilyTreeScreenState extends State<FamilyTreeScreen> {
  final _repository = FamilyTreeRepository();
  late Future<
    ({
      List<FamilyTreePersonModel> people,
      List<FamilyRelationshipModel> relationships,
    })
  >
  _dataFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _dataFuture = _loadData();
  }

  Future<
    ({
      List<FamilyTreePersonModel> people,
      List<FamilyRelationshipModel> relationships,
    })
  >
  _loadData() async {
    final results = await Future.wait([
      _repository.listPeople(widget.familyId),
      _repository.listRelationships(widget.familyId),
    ]);
    return (
      people: results[0] as List<FamilyTreePersonModel>,
      relationships: results[1] as List<FamilyRelationshipModel>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Familienstammbaum'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            tooltip: 'Beziehung',
            icon: const Icon(Icons.link),
            onPressed: () async {
              final result = await context.push<bool>(
                '/family-tree/relationship/add?familyId=${widget.familyId}',
              );
              if (result == true && mounted) setState(_reload);
            },
          ),
          IconButton(
            tooltip: 'Person hinzufügen',
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () async {
              final result = await context.push<bool>(
                '/family-tree/person/add?familyId=${widget.familyId}',
              );
              if (result == true && mounted) setState(_reload);
            },
          ),
        ],
      ),
      body:
          FutureBuilder<
            ({
              List<FamilyTreePersonModel> people,
              List<FamilyRelationshipModel> relationships,
            })
          >(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorState(
                  message: ErrorMapper.map(snapshot.error!).message,
                  onRetry: () => setState(_reload),
                );
              }

              final data = snapshot.data!;
              return InteractiveViewer(
                constrained: false,
                minScale: 0.4,
                maxScale: 2.5,
                boundaryMargin: const EdgeInsets.all(120),
                child: FamilyTreeCanvas(
                  people: data.people,
                  relationships: data.relationships,
                  onPersonTap: (person) {
                    context.push(
                      '/family-tree/person/${person.id}?familyId=${widget.familyId}',
                    );
                  },
                ),
              );
            },
          ),
    );
  }
}
