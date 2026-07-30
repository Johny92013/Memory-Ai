import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_card.dart';
import 'package:memory_ai/shared/widgets/app_dialog.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Detailansicht eines Familienmitglieds.
class FamilyMemberDetailScreen extends StatefulWidget {
  const FamilyMemberDetailScreen({
    super.key,
    required this.familyId,
    required this.userId,
    this.member,
    this.canManage = false,
  });

  final String familyId;
  final String userId;
  final FamilyMemberModel? member;
  final bool canManage;

  @override
  State<FamilyMemberDetailScreen> createState() =>
      _FamilyMemberDetailScreenState();
}

class _FamilyMemberDetailScreenState extends State<FamilyMemberDetailScreen> {
  final _repo = FamilyRepository();
  FamilyMemberModel? _member;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _load();
  }

  Future<void> _load() async {
    if (_member != null && _member!.userId == widget.userId) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final members = await _repo.listMembers(widget.familyId);
      final found = members.where((m) => m.userId == widget.userId).toList();
      if (!mounted) return;
      if (found.isEmpty) {
        setState(() {
          _error = 'Mitglied wurde nicht gefunden.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _member = found.first;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = ErrorMapper.map(error).message;
        _loading = false;
      });
    }
  }

  Future<void> _remove() async {
    final member = _member;
    if (member == null) return;

    final confirmed = await AppDialog.confirm(
      context,
      title: 'Mitglied entfernen?',
      message:
          'Möchtest du „${member.displayName}“ wirklich aus der Familie entfernen?',
      confirmLabel: 'Entfernen',
      isDestructive: true,
    );
    if (!confirmed) return;

    try {
      await _repo.removeMember(
        familyId: widget.familyId,
        userId: member.userId,
      );
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(error).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Mitglied',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _member == null) {
      return AppScaffold(
        title: 'Mitglied',
        body: ErrorState(
          message: _error ?? 'Mitglied konnte nicht geladen werden.',
          onRetry: _load,
        ),
      );
    }

    final member = _member!;

    return AppScaffold(
      title: member.displayName,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: ProfileAvatar(
              avatarPath: member.avatarPath,
              firstName: member.firstName,
              lastName: member.lastName,
              displayName: member.displayName,
              radius: 52,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            member.displayName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            member.role.labelDe,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.turquoise),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: 'E-Mail',
                  value: member.email ?? '–',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Rolle',
                  value: member.role.labelDe,
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Beigetreten',
                  value: DateFormatter.day(member.joinedAt),
                ),
              ],
            ),
          ),
          if (widget.canManage && !member.isAdminOrOwner) ...[
            const SizedBox(height: 28),
            AppButton(
              label: 'Aus Familie entfernen',
              icon: Icons.person_remove_outlined,
              onPressed: _remove,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
