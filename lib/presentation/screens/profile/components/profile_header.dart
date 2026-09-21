import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/user_model.dart';
import '../../../widgets/glass_card.dart';
import '../../../widgets/status_badge.dart';

class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final String kycStatus;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.kycStatus,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.primary,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: TextStyle(fontSize: 13, color: context.themeTextSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.phone != null && user.phone!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.phone!,
                        style: TextStyle(fontSize: 12, color: context.themeTextMuted),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primaryLight, size: 20),
                onPressed: onEditProfile,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: context.themeSurfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.themeBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shield_outlined, color: AppColors.primaryLight, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'KYC Identity Verification',
                      style: TextStyle(fontSize: 13, color: context.themeTextPrimary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                StatusBadge(status: kycStatus),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
