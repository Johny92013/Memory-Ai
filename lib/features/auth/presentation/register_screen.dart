import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/utils/validators.dart';
import 'package:memory_ai/features/auth/data/auth_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_logo.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Registrierungsbildschirm mit Vorname, Nachname, E-Mail und Passwort.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final AuthRepository _auth = widget.authRepository ?? AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      final response = await _auth.signUp(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (response.session == null) {
        setState(() {
          _info =
              'Konto erstellt. Bitte bestätige deine E-Mail, falls nötig, '
              'und melde dich danach an.';
        });
      } else {
        context.go('/welcome');
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () =>
              _error = 'Registrierung fehlgeschlagen. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrieren',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/welcome'),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        message: 'Konto wird erstellt …',
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: AppLogo(size: 88)),
                      const SizedBox(height: 20),
                      Text(
                        'Neues Familienkonto',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lege dein Konto an und starte eure Erinnerungen.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _firstNameController,
                        label: 'Vorname',
                        prefixIcon: Icons.person_outline,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.givenName],
                        validator: (value) =>
                            Validators.requiredName(value, label: 'Vorname'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _lastNameController,
                        label: 'Nachname',
                        prefixIcon: Icons.badge_outlined,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.familyName],
                        validator: (value) =>
                            Validators.requiredName(value, label: 'Nachname'),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailController,
                        label: 'E-Mail',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Passwort',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.newPassword],
                        validator: Validators.password,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmController,
                        label: 'Passwort bestätigen',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscureConfirm,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (value) => Validators.confirmPassword(
                          value,
                          _passwordController.text,
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
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
                      if (_info != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _info!,
                          style: const TextStyle(color: AppColors.turquoise),
                        ),
                      ],
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'Registrieren',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => context.go('/login'),
                        child: const Text('Bereits ein Konto? Anmelden'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
