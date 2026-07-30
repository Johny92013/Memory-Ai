import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/features/family_tree/data/family_relationship_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_person_model.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';
import 'package:memory_ai/features/family_tree/widgets/family_tree_person_card.dart';

/// Interaktives Canvas für den Familienstammbaum.
class FamilyTreeCanvas extends StatelessWidget {
  const FamilyTreeCanvas({
    super.key,
    required this.people,
    required this.relationships,
    this.onPersonTap,
  });

  final List<FamilyTreePersonModel> people;
  final List<FamilyRelationshipModel> relationships;
  final void Function(FamilyTreePersonModel person)? onPersonTap;

  @override
  Widget build(BuildContext context) {
    if (people.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Personen im Stammbaum.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    final layout = FamilyTreeRepository.generationLayout(people, relationships);
    final byGeneration = <int, List<FamilyTreePersonModel>>{};
    for (final person in people) {
      final gen = layout[person.id] ?? 0;
      byGeneration.putIfAbsent(gen, () => []).add(person);
    }

    final sortedGens = byGeneration.keys.toList()..sort();
    const rowHeight = 140.0;
    const cardWidth = 160.0;
    const hGap = 24.0;
    const vGap = 48.0;

    final maxRowWidth = byGeneration.values
        .map((row) => row.length * cardWidth + (row.length - 1) * hGap)
        .fold(0.0, (a, b) => a > b ? a : b);

    final canvasWidth = maxRowWidth + 80;
    final canvasHeight =
        sortedGens.length * rowHeight + (sortedGens.length - 1) * vGap + 80;

    return SizedBox(
      width: canvasWidth,
      height: canvasHeight,
      child: Stack(
        children: [
          for (var gi = 0; gi < sortedGens.length; gi++)
            for (var pi = 0; pi < byGeneration[sortedGens[gi]]!.length; pi++)
              Positioned(
                left:
                    40 +
                    pi * (cardWidth + hGap) +
                    (maxRowWidth -
                            (byGeneration[sortedGens[gi]]!.length * cardWidth +
                                (byGeneration[sortedGens[gi]]!.length - 1) *
                                    hGap)) /
                        2,
                top: 40 + gi * (rowHeight + vGap),
                child: FamilyTreePersonCard(
                  person: byGeneration[sortedGens[gi]]![pi],
                  width: cardWidth,
                  onTap: onPersonTap != null
                      ? () => onPersonTap!(byGeneration[sortedGens[gi]]![pi])
                      : null,
                ),
              ),
        ],
      ),
    );
  }
}
