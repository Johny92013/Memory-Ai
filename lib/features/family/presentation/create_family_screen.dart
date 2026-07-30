import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/utils/validators.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/features/family/widgets/invitation_code_card.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Neue Familie anlegen.
class CreateFamilyScreen extends StatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  State<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends State<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repo = FamilyRepository();

  bool _loading = false;
  String? _error;
  String? _createdInviteCode;
  String? _createdFamilyId;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final family = await _repo.createFamily(_nameController.text);
      if (!mounted) return;
      setState(() {
        _createdInviteCode = family.inviteCode;
        _createdFamilyId = family.id;
      });
    } catch (error) {
      setState(() => _error = ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Familie erstellen',
      body: LoadingOverlay(
        isLoading: _loading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _createdInviteCode != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Familie angelegt',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lade deine Familie mit dem Code ein.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      InvitationCodeCard(inviteCode: _createdInviteCode!),
                      const SizedBox(height: 28),
                      AppButton(
                        label: 'Weiter zu Mitgliedern',
                        onPressed: () => context.go(
                          '/family/members?familyId=$_createdFamilyId',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.go(
                          '/family-tree?familyId=$_createdFamilyId',
                        ),
                        child: const Text('Zum Stammbaum'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => context.pop(true),
                        child: const Text('Zurück zur Übersicht'),
                      ),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Wie heißt eure Familie?',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Du wirst Inhaber und kannst andere einladen.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        AppTextField(
                          controller: _nameController,
                          label: 'Familienname',
                          hint: 'z. B. Familie Müller',
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            final base = Validators.requiredName(
                              value,
                              label: 'Familienname',
                            );
                            if (base != null) return base;
                            if (value!.trim().length < 2) {
                              return 'Mindestens 2 Zeichen';
                            }
                            return null;
                          },
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
                          label: 'Familie erstellen',
                          onPressed: _submit,
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
