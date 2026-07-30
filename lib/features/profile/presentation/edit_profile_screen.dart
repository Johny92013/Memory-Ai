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
import 'package:memory_ai/features/profile/data/profile_model.dart';
import 'package:memory_ai/features/profile/data/profile_repository.dart';
import 'package:memory_ai/features/profile/widgets/profile_avatar.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Profil bearbeiten.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _repo = ProfileRepository();

  ProfileModel? _profile;
  XFile? _pickedImage;
  Uint8List? _previewBytes;
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await _repo.ensureExists();
      if (!mounted) return;
      _profile = profile;
      _firstNameController.text = profile.firstName ?? '';
      _lastNameController.text = profile.lastName ?? '';
      _usernameController.text = profile.username ?? '';
      _birthDate = profile.birthDate;
    } catch (error) {
      _loadError = ErrorMapper.map(error).message;
    } finally {
      if (mounted) setState(() => _loading = false);
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
      _saving = true;
      _error = null;
    });

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Nicht angemeldet');

      String? avatarPath;
      if (_pickedImage != null) {
        avatarPath = await ImageService.uploadAvatar(
          userId: userId,
          file: _pickedImage!,
        );
      }

      await _repo.updateProfile(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        username: _usernameController.text,
        avatarPath: avatarPath,
        birthDate: _birthDate,
      );

      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      setState(() => _error = ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Profil bearbeiten',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null || _profile == null) {
      return AppScaffold(
        title: 'Profil bearbeiten',
        body: ErrorState(
          message: _loadError ?? 'Profil konnte nicht geladen werden.',
          onRetry: _load,
        ),
      );
    }

    return AppScaffold(
      title: 'Profil bearbeiten',
      body: LoadingOverlay(
        isLoading: _saving,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          if (_previewBytes != null)
                            CircleAvatar(
                              radius: 48,
                              backgroundImage: MemoryImage(_previewBytes!),
                            )
                          else
                            ProfileAvatar(
                              avatarPath: _profile!.avatarPath,
                              firstName: _profile!.firstName,
                              lastName: _profile!.lastName,
                              displayName: _profile!.displayName,
                              radius: 48,
                            ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 16,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 3) return 'Mindestens 3 Zeichen';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickBirthDate,
                    borderRadius: BorderRadius.circular(18),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Geburtsdatum',
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
                    label: 'Änderungen speichern',
                    onPressed: _save,
                    isLoading: _saving,
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
