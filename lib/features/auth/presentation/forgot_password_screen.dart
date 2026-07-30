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

/// Passwort-zurücksetzen-Bildschirm.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.authRepository});

  final AuthRepository? authRepository;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AuthRepository _auth = widget.authRepository ?? AuthRepository();

  bool _loading = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
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
      await _auth.resetPassword(_emailController.text);
      if (!mounted) return;
      setState(() {
        _info =
            'Falls ein Konto mit dieser E-Mail existiert, '
            'haben wir dir einen Link zum Zurücksetzen gesendet.';
      });
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Zurücksetzen fehlgeschlagen. Bitte erneut versuchen.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Passwort vergessen',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/login'),
      ),
      body: LoadingOverlay(
        isLoading: _loading,
        message: 'E-Mail wird gesendet …',
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
                        'Passwort zurücksetzen',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gib deine E-Mail ein. Wir senden dir einen Link '
                        'zum Zurücksetzen des Passworts.',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      AppTextField(
                        controller: _emailController,
                        label: 'E-Mail',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.email],
                        validator: Validators.email,
                        onFieldSubmitted: (_) => _submit(),
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
                        label: 'Link senden',
                        onPressed: _loading ? null : _submit,
                        isLoading: _loading,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _loading ? null : () => context.go('/login'),
                        child: const Text('Zurück zur Anmeldung'),
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
