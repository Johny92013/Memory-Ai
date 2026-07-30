import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/family/data/family_member_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Familie per Einladungscode beitreten.
class JoinFamilyScreen extends StatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  State<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends State<JoinFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _repo = FamilyRepository();

  FamilyRole _role = FamilyRole.parent;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _repo.joinFamily(inviteCode: _codeController.text, role: _role);
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      setState(() => _error = ErrorMapper.map(error).message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Familie beitreten',
      body: LoadingOverlay(
        isLoading: _loading,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Einladungscode eingeben',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Den Code erhältst du von einem Familienmitglied.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _codeController,
                    label: 'Einladungscode',
                    hint: 'z. B. A1B2C3D4',
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().length < 6) {
                        return 'Bitte gültigen Code eingeben';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<FamilyRole>(
                    // ignore: deprecated_member_use
                    value: _role,
                    decoration: const InputDecoration(labelText: 'Meine Rolle'),
                    items: FamilyRole.joinChoices
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.labelDe),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _role = value);
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
                    label: 'Beitreten',
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
