import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/utils/initials_helper.dart';
import 'package:memory_ai/features/trips/data/trip_member_model.dart';

/// Überlappende runde Avatare für Mitreisende mit „+N“-Overflow.
class TravelerAvatarStack extends StatelessWidget {
  const TravelerAvatarStack({
    super.key,
    required this.members,
    this.maxVisible = 4,
    this.avatarSize = 36,
    this.overlap = 10,
  });

  final List<TripMemberModel> members;
  final int maxVisible;
  final double avatarSize;
  final double overlap;

  List<TripMemberModel> get _visibleMembers {
    return members
        .where((m) => m.invitationStatus == 'accepted')
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final accepted = _visibleMembers;
    if (accepted.isEmpty) return const SizedBox.shrink();

    final show = accepted.take(maxVisible).toList();
    final overflow = accepted.length - show.length;
    final step = avatarSize - overlap;
    final width =
        avatarSize + step * (show.length - 1) + (overflow > 0 ? step : 0);

    return SizedBox(
      height: avatarSize,
      width: width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < show.length; i++)
            Positioned(
              left: i * step,
              child: _TravelerAvatar(
                label: show[i].displayName ?? show[i].email ?? '?',
                size: avatarSize,
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: show.length * step,
              child: _OverflowBadge(count: overflow, size: avatarSize),
            ),
        ],
      ),
    );
  }
}

class _TravelerAvatar extends StatelessWidget {
  const _TravelerAvatar({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = InitialsHelper.fromFullName(label);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.brandGradient,
        border: Border.all(color: AppColors.backgroundDark, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.count, required this.size});

  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardElevated,
        border: Border.all(color: AppColors.backgroundDark, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '+$count',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.28,
        ),
      ),
    );
  }
}
