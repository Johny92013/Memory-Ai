import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_radius.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/people/data/face_consent_service.dart';
import 'package:memory_ai/features/profile/data/biometric_consent_model.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Drei getrennte Informations- und Einwilligungsabschnitte (Art. 9 DSGVO).
class ConsentInfoScreen extends StatefulWidget {
  const ConsentInfoScreen({super.key});

  @override
  State<ConsentInfoScreen> createState() => _ConsentInfoScreenState();
}

class _ConsentInfoScreenState extends State<ConsentInfoScreen> {
  final _consent = FaceConsentService();
  BiometricConsentModel? _model;
  bool _loading = true;
  bool _busy = false;

  bool _detectChecked = false;
  bool _referenceChecked = false;
  bool _familyChecked = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final model = await _consent.getMyConsent();
      if (!mounted) return;
      setState(() {
        _model = model;
        _detectChecked = model.isValidForCurrentVersion;
        _referenceChecked = model.faceReferenceConsentGiven;
        _familyChecked = model.familyMatchingConsentGiven;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _toggleDetection(bool enable) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = enable
          ? await _consent.grantDetection()
          : await _consent.revokeDetection();
      if (!mounted) return;
      setState(() {
        _model = updated;
        _detectChecked = updated.isValidForCurrentVersion;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _toggleReference(bool enable) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = enable
          ? await _consent.grantFaceReference()
          : await _consent.revokeFaceReference();
      if (!mounted) return;
      setState(() {
        _model = updated;
        _referenceChecked = updated.faceReferenceConsentGiven;
        _busy = false;
      });
      if (enable && mounted) {
        context.push('/profile/face-references');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _toggleFamily(bool enable) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final updated = enable
          ? await _consent.grantFamilyMatching()
          : await _consent.revokeFamilyMatching();
      if (!mounted) return;
      setState(() {
        _model = updated;
        _familyChecked = updated.familyMatchingConsentGiven;
        _busy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.textSecondary,
      height: 1.45,
    );

    return AppScaffold(
      title: 'Gesicht & Einwilligungen',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Jede Funktion braucht eine eigene Einwilligung. Du kannst '
                  'sie einzeln erteilen und jederzeit widerrufen – dann '
                  'werden nur die zugehörigen Daten gelöscht.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
                _ConsentSection(
                  title: 'Gesichter erkennen (Position)',
                  bullets: const [
                    'Die App erkennt lokal, wo auf einem Foto ein Gesicht '
                        'liegt – nicht, um wen es sich handelt.',
                    'Keine Weitergabe an externe Dienste.',
                    'Widerruf löscht nur die erkannten Positionen '
                        '(Bounding Boxes).',
                  ],
                  bodyStyle: bodyStyle,
                  checked: _detectChecked,
                  busy: _busy,
                  checkboxLabel:
                      'Ich willige in die lokale Gesichtserkennung '
                      '(nur Position) ein.',
                  onChanged: (v) {
                    setState(() => _detectChecked = v);
                  },
                  actionLabel: _model?.isValidForCurrentVersion == true
                      ? 'Widerrufen'
                      : 'Einwilligen',
                  onAction: () {
                    if (_model?.isValidForCurrentVersion == true) {
                      _toggleDetection(false);
                    } else if (_detectChecked) {
                      _toggleDetection(true);
                    }
                  },
                  actionEnabled:
                      !_busy &&
                      (_model?.isValidForCurrentVersion == true ||
                          _detectChecked),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ConsentSection(
                  title: 'Mich selbst erkennen lassen',
                  bullets: const [
                    'Du kannst 1–5 Referenzfotos hinterlegen. Daraus werden '
                        'nur Merkmalsvektoren gespeichert – keine dauerhaften '
                        'Rohbild-Kopien.',
                    'Bei neuen Fotos schlägt die App vor, wenn du selbst '
                        'darauf zu sehen sein könntest („Möglicherweise du“).',
                    'Du bestätigst oder lehnst jeden Vorschlag ab – nichts '
                        'wird automatisch endgültig zugeordnet.',
                    'Alles läuft lokal. Widerruf löscht nur deine '
                        'Referenzdaten und offenen Selbst-Vorschläge.',
                  ],
                  bodyStyle: bodyStyle,
                  checked: _referenceChecked,
                  busy: _busy,
                  checkboxLabel:
                      'Ich willige ein, dass die App mich anhand meiner '
                      'Referenzfotos vorschlagen darf.',
                  onChanged: (v) {
                    setState(() => _referenceChecked = v);
                  },
                  actionLabel: _model?.faceReferenceConsentGiven == true
                      ? 'Widerrufen'
                      : 'Einwilligen',
                  onAction: () {
                    if (_model?.faceReferenceConsentGiven == true) {
                      _toggleReference(false);
                    } else if (_referenceChecked) {
                      _toggleReference(true);
                    }
                  },
                  actionEnabled:
                      !_busy &&
                      (_model?.faceReferenceConsentGiven == true ||
                          _referenceChecked),
                  extra: _model?.faceReferenceConsentGiven == true
                      ? TextButton(
                          onPressed: () =>
                              context.push('/profile/face-references'),
                          child: const Text('Referenzfotos verwalten'),
                        )
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                _ConsentSection(
                  title: 'Familienabgleich',
                  bullets: const [
                    'Dein erkanntes Gesicht kann mit Referenzdaten '
                        'verbundener Familienmitglieder verglichen werden – '
                        'nur wenn diese ebenfalls zugestimmt haben.',
                    'Nur bestätigte Familienmitglieder; keine offenen '
                        'Einladungen, keine entfernten oder blockierten '
                        'Personen, keine fremden Nutzer.',
                    'Ergebnis ist immer nur ein Vorschlag '
                        '(„Möglicherweise Anna“) zum Bestätigen oder Ablehnen.',
                    'Widerruf löscht nur offene Familien-Vorschläge, nicht '
                        'bestätigte Personen oder Detection-Daten.',
                  ],
                  bodyStyle: bodyStyle,
                  checked: _familyChecked,
                  busy: _busy,
                  checkboxLabel:
                      'Ich willige in den freiwilligen Abgleich mit '
                      'Familienmitgliedern ein, die ebenfalls zugestimmt haben.',
                  onChanged: (v) {
                    setState(() => _familyChecked = v);
                  },
                  actionLabel: _model?.familyMatchingConsentGiven == true
                      ? 'Widerrufen'
                      : 'Einwilligen',
                  onAction: () {
                    if (_model?.familyMatchingConsentGiven == true) {
                      _toggleFamily(false);
                    } else if (_familyChecked) {
                      _toggleFamily(true);
                    }
                  },
                  actionEnabled:
                      !_busy &&
                      (_model?.familyMatchingConsentGiven == true ||
                          _familyChecked),
                ),
                const SizedBox(height: AppSpacing.xxl),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Fertig'),
                ),
              ],
            ),
    );
  }
}

class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.title,
    required this.bullets,
    required this.bodyStyle,
    required this.checked,
    required this.busy,
    required this.checkboxLabel,
    required this.onChanged,
    required this.actionLabel,
    required this.onAction,
    required this.actionEnabled,
    this.extra,
  });

  final String title;
  final List<String> bullets;
  final TextStyle? bodyStyle;
  final bool checked;
  final bool busy;
  final String checkboxLabel;
  final ValueChanged<bool> onChanged;
  final String actionLabel;
  final VoidCallback onAction;
  final bool actionEnabled;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            for (final text in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ', style: bodyStyle),
                    Expanded(child: Text(text, style: bodyStyle)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: checked,
              onChanged: busy ? null : (v) => onChanged(v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: Text(
                checkboxLabel,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ?extra,
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: actionLabel,
              onPressed: actionEnabled ? onAction : null,
              isLoading: busy,
            ),
          ],
        ),
      ),
    );
  }
}
