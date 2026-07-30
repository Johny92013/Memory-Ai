import 'package:flutter/material.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family/data/family_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/family/widgets/invitation_code_card.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Einladungscode teilen / Familienmitglied einladen.
class InviteFamilyMemberScreen extends StatefulWidget {
  const InviteFamilyMemberScreen({
    super.key,
    required this.familyId,
    this.family,
  });

  final String familyId;
  final FamilyModel? family;

  @override
  State<InviteFamilyMemberScreen> createState() =>
      _InviteFamilyMemberScreenState();
}

class _InviteFamilyMemberScreenState extends State<InviteFamilyMemberScreen> {
  final _repo = FamilyRepository();
  FamilyModel? _family;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _family = widget.family;
    _load();
  }

  Future<void> _load() async {
    if (widget.familyId.trim().isEmpty) {
      setState(() {
        _error = 'Ungültige Familien-ID.';
        _loading = false;
      });
      return;
    }

    if (_family != null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final family = await _repo.getFamily(widget.familyId);
      if (!mounted) return;
      if (family == null) {
        setState(() {
          _error = 'Familie wurde nicht gefunden.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _family = family;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Einladen',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _family == null) {
      return AppScaffold(
        title: 'Einladen',
        body: ErrorState(
          message: _error ?? 'Einladungscode nicht verfügbar.',
          onRetry: _load,
        ),
      );
    }

    return AppScaffold(
      title: 'Mitglied einladen',
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Lade jemanden zu „${_family!.name}“ ein',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Sende den Code per Nachricht oder zeige ihn auf dem Gerät.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          InvitationCodeCard(inviteCode: _family!.inviteCode),
          const SizedBox(height: 20),
          Text(
            'Die Person öffnet Family Memories, tippt auf „Mit Code beitreten“ '
            'und gibt diesen Code ein.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
