import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/auth/app_role.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_model.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_repository.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';
import 'package:memory_ai/features/profile/widgets/profile_info_card.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';

/// Profilübersicht des angemeldeten Nutzers.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = ProfileRepository();
  final _consentRepo = BiometricConsentRepository();
  late Future<ProfileModel?> _future;
  BiometricConsentModel? _consent;
  bool _consentLoading = true;
  bool _consentBusy = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.getMyProfile();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    setState(() => _consentLoading = true);
    try {
      final consent = await _consentRepo.getMyConsent();
      if (!mounted) return;
      setState(() {
        _consent = consent;
        _consentLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _consent = null;
        _consentLoading = false;
      });
    }
  }

  Future<void> _reload() async {
    setState(() => _future = _repo.getMyProfile());
    await Future.wait([_future, _loadConsent()]);
  }

  Future<void> _signOut() async {
    await SupabaseService.client.auth.signOut();
    if (!mounted) return;
    context.go('/welcome');
  }

  Future<void> _onFaceToggle(bool enable) async {
    if (_consentBusy) return;
    if (enable) {
      final granted = await context.push<bool>('/profile/consent/face');
      if (granted == true) await _loadConsent();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gesichtserkennung deaktivieren?'),
        content: const Text(
          'Bereits erkannte Gesichtspositionen werden gelöscht. '
          'Referenz- und Familien-Einwilligungen bleiben getrennt bestehen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _consentBusy = true);
    try {
      final updated = await _consentRepo.revokeConsent();
      if (!mounted) return;
      setState(() {
        _consent = updated;
        _consentBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consentBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _onReferenceToggle(bool enable) async {
    if (_consentBusy) return;
    if (enable) {
      await context.push('/profile/consent/face');
      await _loadConsent();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selbstabgleich deaktivieren?'),
        content: const Text(
          'Nur deine Referenzdaten und offenen Selbst-Vorschläge werden gelöscht.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _consentBusy = true);
    try {
      final updated = await _consentRepo.revokeFaceReferenceConsent();
      if (!mounted) return;
      setState(() {
        _consent = updated;
        _consentBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consentBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _onFamilyToggle(bool enable) async {
    if (_consentBusy) return;
    if (enable) {
      await context.push('/profile/consent/face');
      await _loadConsent();
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Familienabgleich deaktivieren?'),
        content: const Text(
          'Nur offene Familien-Vorschläge werden gelöscht. '
          'Bestätigte Personen bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deaktivieren'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _consentBusy = true);
    try {
      final updated = await _consentRepo.revokeFamilyMatchingConsent();
      if (!mounted) return;
      setState(() {
        _consent = updated;
        _consentBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _consentBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final faceEnabled = _consent?.isValidForCurrentVersion ?? false;
    final referenceEnabled = _consent?.faceReferenceConsentGiven ?? false;
    final familyEnabled = _consent?.familyMatchingConsentGiven ?? false;

    return AppScaffold(
      title: 'Profil',
      actions: [
        IconButton(
          tooltip: 'Abmelden',
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: _reload,
        color: AppColors.accentWarm,
        child: FutureBuilder<ProfileModel?>(
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

            final profile = snapshot.data;
            if (profile == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyState(
                    icon: Icons.person_outline,
                    title: 'Noch kein Profil',
                    subtitle: 'Vervollständige dein Profil, um loszulegen.',
                    buttonLabel: 'Profil erstellen',
                    onButtonPressed: () => context.go('/complete-profile'),
                  ),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                ProfileInfoCard(
                  profile: profile,
                  onEdit: () async {
                    await context.push('/profile/edit');
                    await _reload();
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Privatsphäre und Einwilligungen',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Gesichter erkennen (Position)'),
                          subtitle: const Text(
                            'Erkennt Gesichtspositionen lokal – nur mit Einwilligung.',
                          ),
                          value: faceEnabled,
                          onChanged: (_consentLoading || _consentBusy)
                              ? null
                              : _onFaceToggle,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Mich selbst erkennen lassen'),
                          subtitle: const Text(
                            'Vorschläge anhand eigener Referenzfotos.',
                          ),
                          value: referenceEnabled,
                          onChanged: (_consentLoading || _consentBusy)
                              ? null
                              : _onReferenceToggle,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Familienabgleich'),
                          subtitle: const Text(
                            'Nur mit Gegenkonsens verbundener Mitglieder.',
                          ),
                          value: familyEnabled,
                          onChanged: (_consentLoading || _consentBusy)
                              ? null
                              : _onFamilyToggle,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () async {
                              await context.push('/profile/consent/face');
                              await _loadConsent();
                            },
                            child: const Text('Details und Einwilligungen'),
                          ),
                        ),
                        if (referenceEnabled)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: () =>
                                  context.push('/profile/face-references'),
                              child: const Text('Referenzfotos verwalten'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (AppRole.isAppAdmin(SupabaseService.client.auth.currentUser))
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    tileColor: AppColors.surface,
                    leading: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.accentWarm,
                    ),
                    title: const Text('Admin-Verwaltung'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/admin'),
                  ),
                if (AppRole.isAppAdmin(SupabaseService.client.auth.currentUser))
                  const SizedBox(height: AppSpacing.sm),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  tileColor: AppColors.surface,
                  leading: const Icon(Icons.person_pin_outlined),
                  title: const Text('Aufnahmen mit mir'),
                  subtitle: const Text(
                    'Markierungen bestätigen und gemeinsame Erinnerungen',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/tagged-media'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  tileColor: AppColors.surface,
                  leading: const Icon(Icons.flight_takeoff_outlined),
                  title: const Text('Meine Reisen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/trips'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  tileColor: AppColors.surface,
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Verbindungen und Familie'),
                  subtitle: const Text('Freunde, Mitreisende, Stammbaum'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile/groups'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  tileColor: AppColors.surface,
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text('Einstellungen'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
