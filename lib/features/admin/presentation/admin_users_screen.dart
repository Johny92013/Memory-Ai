import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/admin/data/admin_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Liste aller Benutzerprofile (Admin).
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = AdminRepository();
  List<Map<String, dynamic>> _profiles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profiles = await _repo.listProfiles();
      if (!mounted) return;
      setState(() {
        _profiles = profiles;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(error).message;
      });
    }
  }

  String _displayName(Map<String, dynamic> profile) {
    final first = (profile['first_name'] as String?)?.trim() ?? '';
    final last = (profile['last_name'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    final username = (profile['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    return profile['email'] as String? ?? 'Unbekannt';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Benutzer',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _profiles.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyState(
                  icon: Icons.people_outline,
                  title: 'Keine Benutzer',
                  subtitle: 'Es sind noch keine Profile vorhanden.',
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _profiles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final profile = _profiles[index];
                  final createdAt = profile['created_at'];
                  final parsed = createdAt != null
                      ? DateTime.tryParse(createdAt.toString())
                      : null;
                  final dateText = parsed != null
                      ? DateFormatter.formatDateTime(parsed)
                      : null;

                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: AppColors.card,
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        _displayName(profile).isNotEmpty
                            ? _displayName(profile)[0].toUpperCase()
                            : '?',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ),
                    title: Text(_displayName(profile)),
                    subtitle: Text(
                      [
                        profile['email'] as String?,
                        profile['username'] as String?,
                        dateText,
                      ].whereType<String>().join(' · '),
                      maxLines: 2,
                    ),
                    isThreeLine: true,
                  );
                },
              ),
            ),
    );
  }
}
