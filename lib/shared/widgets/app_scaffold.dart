import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';

/// Dunkles Scaffold mit einheitlichem Hintergrund.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.actions,
    this.leading,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.showAppBar = true,
  });

  final String? title;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final List<Widget>? actions;
  final Widget? leading;
  final bool resizeToAvoidBottomInset;
  final bool extendBodyBehindAppBar;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: showAppBar && title != null
          ? AppBar(title: Text(title!), leading: leading, actions: actions)
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
