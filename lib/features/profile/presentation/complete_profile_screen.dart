import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/services/image_service.dart';
import 'package:memory_ai/core/services/supabase_service.dart';
import 'package:memory_ai/core/utils/date_formatter.dart';
import 'package:memory_ai/core/utils/validators.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Onboarding: Profil vervollständigen.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repo = ProfileRepository();
  final _familyRepo = FamilyRepository();

  XFile? _pickedImage;
  Uint8List? _previewBytes;
  DateTime? _birthDate;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    try {
      final profile = await _repo.ensureExists();
      if (!mounted) return;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _usernameController.text = profile.username ?? '';
      setState(() => _birthDate = profile.birthDate);
    } catch (_) {
      // Prefill ist optional.
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImageService.pickImage();
    if (file == null) return;
    final bytes = await ImageService.readBytes(file);
    if (!mounted) return;
    setState(() {
      _pickedImage = file;
      _previewBytes = bytes;
    });
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Geburtsdatum wählen',
      cancelText: 'Abbrechen',
      confirmText: 'Übernehmen',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Nicht angemeldet');
      }

      String? avatarPath;
      if (_pickedImage != null) {
        avatarPath = await ImageService.uploadAvatar(
          userId: userId,
          file: _pickedImage!,
        );
      }

      await _repo.completeProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        avatarPath: avatarPath,
        birthDate: _birthDate,
      );

      final families = await _familyRepo.listMyFamilies();
      if (!mounted) return;
      context.go(families.isEmpty ? '/family' : '/home');
    } catch (error) {
      setState(() => _error = ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Profil vervollständigen',
      body: LoadingOverlay(
        isLoading: _loading,
        message: 'Wird gespeichert…',
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Erzähl uns etwas über dich',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dein Profil hilft der Familie, dich zu erkennen.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          if (_previewBytes != null)
                            CircleAvatar(
                              radius: 52,
                              backgroundImage: MemoryImage(_previewBytes!),
                            )
                          else
                            const ProfileAvatar(radius: 52, displayName: 'Ich'),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Profilbild tippen zum Ändern',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _firstNameController,
                    label: 'Vorname',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        Validators.requiredName(v, label: 'Vorname'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _lastNameController,
                    label: 'Nachname',
                    textCapitalization: TextCapitalization.words,
                    validator: (v) =>
                        Validators.requiredName(v, label: 'Nachname'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _usernameController,
                    label: 'Benutzername',
                    hint: 'z. B. anna_mueller',
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 3) {
                        return 'Mindestens 3 Zeichen';
                      }
                      if (!RegExp(r'^[a-zA-Z0-9._]+$').hasMatch(text)) {
                        return 'Nur Buchstaben, Zahlen, . und _';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickBirthDate,
                    borderRadius: BorderRadius.circular(18),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum (optional)',
                        prefixIcon: Icon(Icons.cake_outlined),
                      ),
                      child: Text(
                        _birthDate == null
                            ? 'Nicht angegeben'
                            : DateFormatter.day(_birthDate),
                        style: TextStyle(
                          color: _birthDate == null
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.accentPink),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Speichern und weiter',
                    onPressed: _save,
                    isLoading: _loading,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
