import 'package:flutter/material.dart';
import 'package:memory_ai/app/home_dashboard_colors.dart';
import 'package:memory_ai/features/home/widgets/user_greeting.dart';
import 'package:memory_ai/features/profile/data/profile_model.dart';

/// Dunkler Header der Startseite mit Titel, Glocke und Begrüßung.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.greeting,
    this.profile,
    this.onProfileTap,
    this.onNotificationsTap,
    this.showNotificationDot = false,
    this.height = 190,
  });

  final String greeting;
  final ProfileModel? profile;
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationsTap;
  final bool showNotificationDot;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: HomeDashboardColors.header,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Start',
                      style: TextStyle(
                        color: HomeDashboardColors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: onNotificationsTap,
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: HomeDashboardColors.white,
                          ),
                          tooltip: 'Benachrichtigungen',
                        ),
                        if (showNotificationDot)
                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: HomeDashboardColors.coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                UserGreeting(
                  greeting: greeting,
                  subtitle: 'Schön, dass du da bist.',
                  profile: profile,
                  onProfileTap: onProfileTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
