import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:memory_ai/app/app_colors.dart';
import 'package:memory_ai/core/services/signed_url_service.dart';
import 'package:memory_ai/core/utils/initials_helper.dart';

/// Avatar mit Signed URL und Initialen-Fallback.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.avatarPath,
    this.firstName,
    this.lastName,
    this.displayName,
    this.radius = 36,
    this.onTap,
  });

  final String? avatarPath;
  final String? firstName;
  final String? lastName;
  final String? displayName;
  final double radius;
  final VoidCallback? onTap;

  String get _initials {
    if ((firstName != null && firstName!.trim().isNotEmpty) ||
        (lastName != null && lastName!.trim().isNotEmpty)) {
      return InitialsHelper.fromNames(firstName, lastName);
    }
    return InitialsHelper.fromFullName(displayName);
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    Widget avatar = FutureBuilder<String?>(
      future: SignedUrlService.avatarUrl(avatarPath),
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (url != null && url.isNotEmpty) {
          return ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              placeholder: (_, _) =>
                  _InitialsCircle(initials: _initials, size: size),
              errorWidget: (_, _, _) =>
                  _InitialsCircle(initials: _initials, size: size),
            ),
          );
        }
        return _InitialsCircle(initials: _initials, size: size);
      },
    );

    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: avatar,
      );
    }

    return SizedBox(width: size, height: size, child: avatar);
  }
}

class _InitialsCircle extends StatelessWidget {
  const _InitialsCircle({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
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
