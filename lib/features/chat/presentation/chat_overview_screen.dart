import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/app/app_spacing.dart';
import 'package:memory_ai/core/errors/error_mapper.dart';
import 'package:memory_ai/features/chat/data/chat_repository.dart';
import 'package:memory_ai/features/chat/data/chat_room_model.dart';
import 'package:memory_ai/features/family/data/family_repository.dart';
import 'package:memory_ai/shared/widgets/app_travel_logo.dart';
import 'package:memory_ai/shared/widgets/empty_state.dart';
import 'package:memory_ai/shared/widgets/error_state.dart';
import 'package:memory_ai/shared/widgets/travel_ui.dart';

/// Übersicht der Familien-Chat-Räume.
class ChatOverviewScreen extends StatefulWidget {
  const ChatOverviewScreen({super.key});

  @override
  State<ChatOverviewScreen> createState() => _ChatOverviewScreenState();
}

class _ChatOverviewScreenState extends State<ChatOverviewScreen> {
  final _chatRepo = ChatRepository();
  final _familyRepo = FamilyRepository();

  List<ChatRoomModel> _rooms = [];
  String? _familyId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final families = await _familyRepo.listMyFamilies();
      if (families.isEmpty) {
        if (!mounted) return;
        setState(() {
          _familyId = null;
          _rooms = [];
          _loading = false;
        });
        return;
      }
      final family = families.first;
      final room = await _chatRepo.ensureFamilyRoom(familyId: family.id);
      final rooms = await _chatRepo.listRooms(family.id);
      if (!mounted) return;
      setState(() {
        _familyId = family.id;
        _rooms = rooms.isEmpty ? [room] : rooms;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = ErrorMapper.map(e).message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chat',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Familienchat – reiner Text, Echtzeit.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ErrorState(message: _error!, onRetry: _load)
                  : _familyId == null
                  ? const EmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Keine Familie',
                      subtitle:
                          'Tritt einer Familie bei, um den Familienchat zu nutzen.',
                    )
                  : _rooms.isEmpty
                  ? EmptyTravelState(
                      icon: Icons.chat_bubble_outline,
                      title: 'Noch keine Unterhaltungen',
                      message: 'Starte den Familienchat.',
                      buttonLabel: 'Chat öffnen',
                      onPressed: _load,
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemCount: _rooms.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          return TravelCard(
                            onTap: () => context.push('/chat/${room.id}'),
                            child: Row(
                              children: [
                                const GradientIconContainer(
                                  icon: Icons.forum_outlined,
                                  size: 44,
                                  iconSize: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        room.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        'Tippen zum Schreiben',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
