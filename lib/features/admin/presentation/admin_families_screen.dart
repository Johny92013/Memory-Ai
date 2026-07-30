import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/features/admin/data/admin_repository.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Liste aller Familien (Admin).
class AdminFamiliesScreen extends StatefulWidget {
  const AdminFamiliesScreen({super.key});

  @override
  State<AdminFamiliesScreen> createState() => _AdminFamiliesScreenState();
}

class _AdminFamiliesScreenState extends State<AdminFamiliesScreen> {
  final _repo = AdminRepository();
  List<Map<String, dynamic>> _families = [];
  Map<String, int> _memberCounts = {};
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
      final families = await _repo.listFamilies();
      final counts = <String, int>{};
      for (final family in families) {
        final id = family['id'] as String;
        counts[id] = await _repo.countMembersForFamily(id);
      }

      if (!mounted) return;
      setState(() {
        _families = families;
        _memberCounts = counts;
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Familien',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : _families.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                EmptyState(
                  icon: Icons.family_restroom,
                  title: 'Keine Familien',
                  subtitle: 'Es sind noch keine Familien vorhanden.',
                ),
              ],
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _families.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final family = _families[index];
                  final id = family['id'] as String;
                  final name = family['name'] as String? ?? 'Familie';
                  final memberCount = _memberCounts[id] ?? 0;
                  final createdAt = family['created_at'];
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
                    leading: const Icon(
                      Icons.family_restroom,
                      color: AppColors.turquoise,
                    ),
                    title: Text(name),
                    subtitle: Text(
                      [
                        '$memberCount Mitglieder',
                        dateText,
                      ].whereType<String>().join(' · '),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
