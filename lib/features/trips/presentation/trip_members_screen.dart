import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';
import 'package:memory_ai/features/trips/data/trip_repository.dart';
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
  List<TripMemberModel> _members = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final members = await _repo.listTripMembers(widget.tripId);
      if (!mounted) return;
      setState(() {
        _members = members;
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

  Future<void> _invite() async {
    try {
      await _repo.inviteMember(
        tripId: widget.tripId,
        email: _emailController.text.trim(),
        role: 'viewer',
      );
      _emailController.clear();
      _load();
    } catch (e) {
      setState(() => _error = ErrorMapper.map(e).message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Mitglieder',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _members.isEmpty
          ? ErrorState(message: _error!, onRetry: _load)
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: _emailController,
                          label: 'E-Mail einladen',
                        ),
                      ),
                      const SizedBox(width: 8),
                      AppButton(label: 'Einladen', onPressed: _invite),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final m = _members[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (m.displayName ?? m.email ?? '?')[0].toUpperCase(),
                          ),
                        ),
                        title: Text(m.displayName ?? m.email ?? m.userId),
                        subtitle: Text(
                          '${m.role} · ${m.invitationStatus}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
