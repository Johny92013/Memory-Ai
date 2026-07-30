import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/admin/data/admin_repository.dart';
import 'package:memory_ai/features/admin/widgets/admin_stat_card.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Admin-Dashboard mit Kennzahlen und Verwaltungslinks.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _repo = AdminRepository();

  int? _profileCount;
  int? _familyCount;
  int? _memoryCount;
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
      final profiles = await _repo.countProfiles();
      final families = await _repo.countFamilies();
      final memories = await _repo.countMemories();

      if (!mounted) return;
      setState(() {
        _profileCount = profiles;
        _familyCount = families;
        _memoryCount = memories;
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
      title: 'Admin-Verwaltung',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ErrorState(message: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Übersicht',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AdminStatCard(
                    label: 'Benutzer',
                    value: '${_profileCount ?? 0}',
                    icon: Icons.people_outline,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  AdminStatCard(
                    label: 'Familien',
                    value: '${_familyCount ?? 0}',
                    icon: Icons.family_restroom,
                    color: AppColors.turquoise,
                  ),
                  const SizedBox(height: 12),
                  AdminStatCard(
                    label: 'Erinnerungen',
                    value: '${_memoryCount ?? 0}',
                    icon: Icons.photo_library_outlined,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Verwaltung',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: AppColors.card,
                    leading: const Icon(Icons.people_outline),
                    title: const Text('Alle Benutzer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/users'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: AppColors.card,
                    leading: const Icon(Icons.family_restroom),
                    title: const Text('Alle Familien'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin/families'),
                  ),
                ],
              ),
            ),
    );
  }
}
