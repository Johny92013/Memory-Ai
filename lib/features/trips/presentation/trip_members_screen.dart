import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
import 'package:memory_ai/features/trips/data/trip_role_permissions.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

class TripMembersScreen extends StatefulWidget {
  const TripMembersScreen({super.key, required this.tripId});

  final String tripId;

  @override
  State<TripMembersScreen> createState() => _TripMembersScreenState();
}

class _TripMembersScreenState extends State<TripMembersScreen> {
  final _repo = TripRepository();
  final _emailController = TextEditingController();
  final _companionController = TextEditingController();
  final _codeController = TextEditingController();
  List<TripMemberModel> _members = [];
  List<Map<String, dynamic>> _companions = [];
  String _inviteRole = 'contributor';
  bool _loading = true;
  String? _error;
  String? _myRole;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _companionController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await _repo.listTripMembers(widget.tripId);
      final companions = await _repo.listCompanions(widget.tripId);
      final me = SupabaseService.client.auth.currentUser?.id;
      final mine = members.where((m) => m.userId == me).toList();
      if (!mounted) return;
      setState(() {
        _members = members;
        _companions = companions;
        _myRole = mine.isEmpty ? null : mine.first.role;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  bool get _canManage => TripRolePermissions.canManageMembers(_myRole);

  Future<void> _invite() async {
    try {
      await _repo.inviteMember(
        tripId: widget.tripId,
        email: _emailController.text.trim(),
        role: _inviteRole,
      );
      _emailController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Einladung gesendet (ausstehend).')),
      );
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  Future<void> _addCompanion() async {
    try {
      await _repo.addCompanion(
        tripId: widget.tripId,
        displayName: _companionController.text,
      );
      _companionController.clear();
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  Future<void> _createCode() async {
    try {
      final code = await _repo.createInviteCode(
        tripId: widget.tripId,
        role: _inviteRole,
      );
      if (!mounted) return;
      await Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Einladungscode kopiert: $code')));
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  Future<void> _redeemCode() async {
    try {
      await _repo.redeemInviteCode(_codeController.text);
      _codeController.clear();
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Einladung angenommen.')));
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  Future<void> _acceptMine() async {
    try {
      await _repo.acceptTripInvite(widget.tripId);
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  Future<void> _declineMine() async {
    try {
      await _repo.declineTripInvite(widget.tripId);
      await _load();
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  String _roleHelp(String role) {
    switch (role) {
      case 'owner':
        return 'Volle Verwaltung';
      case 'editor':
        return 'Reise und Medien bearbeiten';
      case 'contributor':
        return 'Eigene Medien hochladen';
      case 'viewer':
        return 'Nur ansehen';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = SupabaseService.client.auth.currentUser?.id;
    final myPending = _members.any(
      (m) => m.userId == me && m.invitationStatus == 'pending',
    );

    return AppScaffold(
      title: 'Mitreisende',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _members.isEmpty
          ? ErrorState(message: _error!, onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                if (myPending) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Du hast eine offene Reiseeinladung.'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Annehmen',
                                  onPressed: _acceptMine,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _declineMine,
                                  child: const Text('Ablehnen'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (_canManage) ...[
                  Text('Rollen', style: Theme.of(context).textTheme.titleSmall),
                  Text(
                    'Owner: verwalten · Editor: bearbeiten · '
                    'Contributor: eigene Medien · Viewer: nur lesen',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _inviteRole,
                    decoration: const InputDecoration(labelText: 'Rolle'),
                    items: const [
                      DropdownMenuItem(
                        value: 'contributor',
                        child: Text('Contributor'),
                      ),
                      DropdownMenuItem(value: 'editor', child: Text('Editor')),
                      DropdownMenuItem(value: 'viewer', child: Text('Viewer')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _inviteRole = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _emailController,
                          label: 'App-Nutzer per E-Mail',
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(label: 'Einladen', onPressed: _invite),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Einladungslink-/Code erzeugen',
                    onPressed: _createCode,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _companionController,
                          label: 'Mitreisender ohne Account',
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(label: 'Hinzufügen', onPressed: _addCompanion),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                AppTextField(
                  controller: _codeController,
                  label: 'Einladungscode einlösen',
                ),
                const SizedBox(height: 8),
                AppButton(label: 'Code einlösen', onPressed: _redeemCode),
                const SizedBox(height: 16),
                Text(
                  'Mitglieder',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ..._members.map((m) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Text(
                        (m.displayName ?? m.email ?? '?')[0].toUpperCase(),
                      ),
                    ),
                    title: Text(m.displayName ?? m.email ?? m.userId),
                    subtitle: Text(
                      '${m.role} · ${m.invitationStatus}\n${_roleHelp(m.role)}',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    isThreeLine: true,
                    trailing: _canManage && m.role != 'owner'
                        ? IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () async {
                              await _repo.removeMember(
                                tripId: widget.tripId,
                                userId: m.userId,
                              );
                              await _load();
                            },
                          )
                        : null,
                  );
                }),
                if (_companions.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ohne Account',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  ..._companions.map((c) {
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c['display_name']?.toString() ?? ''),
                      subtitle: const Text(
                        'Kein Upload-Zugriff',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }),
                ],
              ],
            ),
    );
  }
}
