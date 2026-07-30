import 'package:flutter/material.dart';
import 'package:memory_ai/features/auth/presentation/welcome_screen.dart';

/// Dünner Einstiegspunkt; Redirects übernimmt später der Router.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.child});

  /// Optionaler Inhalt; Standard ist der Willkommensbildschirm.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? const WelcomeScreen();
  }
}
