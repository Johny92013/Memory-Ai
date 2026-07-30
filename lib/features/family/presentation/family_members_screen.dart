import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/family/data/family_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/family/widgets/family_member_tile.dart';
import 'package:memory_ai/features/family/widgets/invitation_code_card.dart';
import 'package:memory_ai/shared/widgets/app_dialog.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Mitgliederliste einer Familie.
class FamilyMembersScreen extends StatefulWidget {
  const FamilyMembersScreen({super.key, required this.familyId, this.family});

  final String familyId;
  final FamilyModel? family;

  @override
  State<FamilyMembersScreen> createState() => _FamilyMembersScreenState();
}

class _FamilyMembersScreenState extends State<FamilyMembersScreen> {
  final _repo = FamilyRepository();
  FamilyModel? _family;
  late Future<List<FamilyMemberModel>> _membersFuture;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _family = widget.family;
    _membersFuture = _repo.listMembers(widget.familyId);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      _family ??= await _repo.getFamily(widget.familyId);
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() => _loadError = ErrorMapper.map(error).message);
      }
    }
  }

  Future<void> _reload() async {
    setState(() {
      _loadError = null;
      _membersFuture = _repo.listMembers(widget.familyId);
    });
    await _bootstrap();
    await _membersFuture;
  }

  Future<void> _leave() async {
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Familie verlassen?',
      message:
          'Möchtest du „${_family?.name ?? 'diese Familie'}“ wirklich verlassen?',
      confirmLabel: 'Verlassen',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await _repo.leaveFamily(widget.familyId);
      if (!mounted) return;
      context.go('/family');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _family?.name ?? 'Mitglieder';

    return AppScaffold(
      title: title,
      actions: [
        IconButton(
          tooltip: 'Einladen',
          onPressed: () {
            final familyId = widget.familyId.trim();
            if (familyId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Die Familiengruppe konnte nicht geöffnet werden.',
                  ),
                ),
              );
              return;
            }
            context.pushNamed(
              'familyInvite',
              pathParameters: {'familyId': familyId},
            );
          },
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
        IconButton(
          tooltip: 'Verlassen',
          onPressed: _leave,
          icon: const Icon(Icons.exit_to_app),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _reload,
        color: AppColors.primary,
        child: FutureBuilder<List<FamilyMemberModel>>(
          future: _membersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _family == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || _loadError != null) {
              return ErrorState(
                message: _loadError ?? ErrorMapper.map(snapshot.error!).message,
                onRetry: _reload,
              );
            }

            final members = snapshot.data ?? [];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                if (_family != null) ...[
                  InvitationCodeCard(inviteCode: _family!.inviteCode),
                  const SizedBox(height: 20),
                ],
                Text(
                  'Mitglieder (${members.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (members.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline,
                    title: 'Noch keine Mitglieder',
                    subtitle: 'Lade deine Familie mit dem Code ein.',
                  )
                else
                  ...members.map(
                    (member) => FamilyMemberTile(
                      member: member,
                      onTap: () {
                        final familyId = widget.familyId.trim();
                        if (familyId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Die Familiengruppe konnte nicht geöffnet werden.',
                              ),
                            ),
                          );
                          return;
                        }
                        context.push(
                          '/family/member/${member.userId}?familyId=$familyId',
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
