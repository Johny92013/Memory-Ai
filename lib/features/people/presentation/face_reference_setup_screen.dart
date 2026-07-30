import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/people/data/face_consent_service.dart';
import 'package:memory_ai/features/people/data/face_embedding_engine.dart';
import 'package:memory_ai/features/people/data/face_reference_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';

/// Einrichtung von 1–5 Referenzfotos für den Selbstabgleich.
/// Speichert nur Embeddings, keine Rohbild-Duplikate.
class FaceReferenceSetupScreen extends StatefulWidget {
  const FaceReferenceSetupScreen({super.key});

  @override
  State<FaceReferenceSetupScreen> createState() =>
      _FaceReferenceSetupScreenState();
}

class _FaceReferenceSetupScreenState extends State<FaceReferenceSetupScreen> {
  final _consent = FaceConsentService();
  final _refs = FaceReferenceRepository();
  final _engine = LocalProjectionEmbeddingEngine();
  final _picker = ImagePicker();

  final List<Uint8List> _previews = [];
  final List<List<double>> _embeddings = [];
  bool _allowed = false;
  bool _loading = true;
  bool _saving = false;
  int _storedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final consent = await _consent.getMyConsent();
      final count = consent.faceReferenceConsentGiven
          ? await _refs.countForCurrentUser()
          : 0;
      if (!mounted) return;
      setState(() {
        _allowed = consent.faceReferenceConsentGiven;
        _storedCount = count;
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

  Future<void> _pick(ImageSource source) async {
    if (!_allowed || _saving || _embeddings.length >= 5) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final bytes = await file.readAsBytes();
      final embedding = await _engine.embedFaceCrop(bytes);
      if (!mounted) return;
      setState(() {
        _previews.add(bytes);
        _embeddings.add(embedding);
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  void _removeAt(int index) {
    setState(() {
      _previews.removeAt(index);
      _embeddings.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (!_allowed || _embeddings.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await _refs.replaceAll(_embeddings);
      if (!mounted) return;
      setState(() {
        _storedCount = _embeddings.length;
        _previews.clear();
        _embeddings.clear();
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Referenzdaten gespeichert. Die Fotos selbst werden nicht dauerhaft '
            'doppelt abgelegt.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  Future<void> _deleteAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Referenzdaten löschen?'),
        content: const Text(
          'Alle Merkmalsvektoren für den Selbstabgleich werden entfernt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _saving = true);
    try {
      await _refs.replaceAll(const []);
      if (!mounted) return;
      setState(() {
        _storedCount = 0;
        _previews.clear();
        _embeddings.clear();
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(ErrorMapper.map(e).message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Referenzfotos',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_allowed
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Text(
                  'Zuerst die Einwilligung „Mich selbst erkennen lassen“ '
                  'erteilen.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Wähle 1–5 Fotos von dir. Daraus werden lokal Merkmalsvektoren '
                  'erzeugt. Die Rohbilder werden nicht dauerhaft als zweite '
                  'Kopie gespeichert.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Gespeicherte Referenzen: $_storedCount',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (var i = 0; i < _previews.length; i++)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _previews[i],
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: _saving ? null : () => _removeAt(i),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _embeddings.length >= 5 || _saving
                            ? null
                            : () => _pick(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Galerie'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _embeddings.length >= 5 || _saving
                            ? null
                            : () => _pick(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Kamera'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Referenzdaten speichern',
                  onPressed: _embeddings.isEmpty || _saving ? null : _save,
                  isLoading: _saving,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (_storedCount > 0)
                  OutlinedButton(
                    onPressed: _saving ? null : _deleteAll,
                    child: const Text('Alle Referenzdaten löschen'),
                  ),
              ],
            ),
    );
  }
}
