import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/core/utils/validators.dart';
import 'package:memory_ai/features/family_tree/data/family_tree_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Person zum Stammbaum hinzufügen.
class AddFamilyTreePersonScreen extends StatefulWidget {
  const AddFamilyTreePersonScreen({super.key, required this.familyId});

  final String familyId;

  @override
  State<AddFamilyTreePersonScreen> createState() =>
      _AddFamilyTreePersonScreenState();
}

class _AddFamilyTreePersonScreenState extends State<AddFamilyTreePersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _repo = FamilyTreeRepository();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _repo.addPerson({
        'family_id': widget.familyId,
        'first_name': _firstName.text.trim(),
        'last_name': _lastName.text.trim().isEmpty
            ? null
            : _lastName.text.trim(),
      });
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
      title: 'Person hinzufügen',
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
                  AppTextField(
                    controller: _firstName,
                    label: 'Vorname',
                    validator: (v) =>
                        Validators.requiredName(v, label: 'Vorname'),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(controller: _lastName, label: 'Nachname'),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(color: AppColors.accentPink),
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Speichern',
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
