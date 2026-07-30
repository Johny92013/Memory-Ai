import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family/data/family_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/family/widgets/family_card.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Übersicht aller Familien des Nutzers.
class FamilyOverviewScreen extends StatefulWidget {
  const FamilyOverviewScreen({super.key});

  @override
  State<FamilyOverviewScreen> createState() => _FamilyOverviewScreenState();
}

class _FamilyOverviewScreenState extends State<FamilyOverviewScreen> {
  final _repo = FamilyRepository();
  late Future<List<FamilyModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.listMyFamilies();
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.listMyFamilies());
    await _future;
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>('/family/create');
    if (created == true) await _reload();
  }

  Future<void> _openJoin() async {
    final joined = await context.push<bool>('/family/join');
    if (joined == true) await _reload();
  }

  Future<void> _openFamilyActions(FamilyModel family) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(family.name),
              subtitle: const Text('Familie auswählen'),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Mitglieder'),
              onTap: () {
                Navigator.pop(context);
                context.push('/family/members?familyId=${family.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_tree_outlined),
              title: const Text('Stammbaum'),
              onTap: () {
                Navigator.pop(context);
                context.push('/family-tree?familyId=${family.id}');
              },
            ),
          ],
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Meine Familien',
      body: RefreshIndicator(
        onRefresh: _reload,
        color: AppColors.primary,
        child: FutureBuilder<List<FamilyModel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ErrorState(
                message: ErrorMapper.map(snapshot.error!).message,
                onRetry: _reload,
              );
            }

            final families = snapshot.data ?? [];

            if (families.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                    icon: Icons.family_restroom,
                    title: 'Noch keine Familie',
                    subtitle:
                        'Erstelle eine Familie oder tritt mit einem Einladungscode bei.',
                    buttonLabel: 'Familie erstellen',
                    onButtonPressed: _openCreate,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: OutlinedButton(
                      onPressed: _openJoin,
                      child: const Text('Mit Code beitreten'),
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              itemCount: families.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == families.length) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Neue Familie erstellen',
                        icon: Icons.add,
                        onPressed: _openCreate,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _openJoin,
                        icon: const Icon(Icons.vpn_key_outlined),
                        label: const Text('Mit Code beitreten'),
                      ),
                    ],
                  );
                }

                final family = families[index];
                return FamilyCard(
                  family: family,
                  onTap: () => _openFamilyActions(family),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
