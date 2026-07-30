import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/constants/app_constants.dart';
import 'package:memory_ai/core/errors/app_exception.dart';
import 'package:memory_ai/core/utils/validators.dart';
import 'package:memory_ai/features/auth/data/auth_repository.dart';
import 'package:memory_ai/shared/widgets/app_button.dart';
import 'package:memory_ai/shared/widgets/app_logo.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/app_text_field.dart';
import 'package:memory_ai/shared/widgets/loading_overlay.dart';

/// Anmeldebildschirm.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthRepository _auth = widget.authRepository ?? AuthRepository();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.signInWithIdentifier(
        identifier: _emailController.text,
        password: _passwordController.text,
      );
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Anmeldung fehlgeschlagen. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showAppBar: false,
      body: LoadingOverlay(
        isLoading: _loading,
        message: 'Anmeldung läuft …',
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
                      const SizedBox(height: 16),
                      const Center(child: AppLogo(size: 112)),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Melde dich an, um deine Familienerinnerungen zu sehen.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppTextField(
                        controller: _emailController,
                        label: 'Benutzername oder E-Mail',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.username],
                        validator: Validators.loginIdentifier,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Passwort',
                        prefixIcon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        validator: Validators.loginPassword,
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _loading
                              ? null
                              : () => context.go('/forgot-password'),
                          child: const Text('Passwort vergessen?'),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: AppColors.accentPink),
                        ),
                      ],
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Anmelden',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => context.go('/register'),
                        child: const Text('Noch kein Konto? Registrieren'),
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () => context.go('/welcome'),
                        child: const Text('Zurück zur Startseite'),
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
