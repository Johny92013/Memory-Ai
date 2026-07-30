import 'package:flutter/material.dart';
import 'package:memory_ai/shared/widgets/app_scaffold.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';

/// Einzelner Chat-Raum (Phase 6).
class ChatRoomScreen extends StatelessWidget {
  const ChatRoomScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Unterhaltung',
      body: EmptyState(
        icon: Icons.forum_outlined,
        title: 'Chat folgt in Phase 6',
        subtitle: 'Raum: $roomId',
      ),
    );
  }
}
