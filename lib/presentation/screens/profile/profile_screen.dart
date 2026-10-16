import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/partner_car_model.dart';
import '../../state/app_providers.dart';
import '../../state/auth_provider.dart';
import '../../state/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/glass_card.dart';
import 'components/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showEditProfileModal(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.themeSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.themeBorder),
        ),
        title: Text(
          'Edit Profile',
          style: TextStyle(color: context.themeTextPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(
                labelText: 'Full Name',
                labelStyle: TextStyle(color: context.themeTextSecondary),
                filled: true,
                fillColor: context.themeSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: context.themeTextPrimary),
              decoration: InputDecoration(
                labelText: 'Phone Number',
                labelStyle: TextStyle(color: context.themeTextSecondary),
                filled: true,
                fillColor: context.themeSurfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.themeTextSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profileProvider.notifier)
                  .updateProfile(
                    name: nameController.text.trim(),
                    phone: phoneController.text.trim(),
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final hostedCarsAsync = ref.watch(myPartnerCarsProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Profile',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 64,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign In to Manage Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload driving license, submit KYC, track transactions and host your car.',
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Sign In / Register',
                  width: 180,
                  onPressed: () => context.push('/sign-in'),
                ),
                const SizedBox(height: 32),
                GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _buildSwitchTile(
                        icon: isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                        title: 'Dark Mode Theme',
                        subtitle: isDark
                            ? 'OLED Deep Black with Electric Blue'
                            : 'Clean White background with Royal Blue',
                        value: isDark,
                        isDark: isDark,
                        onChanged: (val) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = authState.user!;
    final profileState = ref.watch(profileProvider);
    final kycStatus = profileState.kyc?.overallStatus ?? 'pending';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        child: Column(
          children: [
            ProfileHeader(
              user: user,
              kycStatus: kycStatus,
              onEditProfile: () => _showEditProfileModal(context, ref),
            ),
            if (user.isStaff) ...[
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.primaryLight.withValues(alpha: 0.6),
                onTap: () => context.push('/staff-portal'),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: AppColors.primaryLight,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${user.role.toUpperCase()} CONSOLE',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'STAFF',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage Fleet, verify customer KYC, and review live bookings.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.primaryLight,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (kycStatus.toLowerCase() != 'approved' &&
                kycStatus.toLowerCase() != 'verified')
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.warning.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Complete KYC Verification',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.warning,
                            ),
                          ),
                          Text(
                            'Upload driving license & Aadhaar for instant vehicle release.',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.themeTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/kyc'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            hostedCarsAsync.when(
              data: (cars) => _buildHostedCarsSection(context, cars, isDark),
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _buildSwitchTile(
                    icon: isDark
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    title: 'Dark Mode Theme',
                    subtitle: isDark
                        ? 'OLED Deep Black with Electric Blue'
                        : 'Clean White background with Royal Blue',
                    value: isDark,
                    isDark: isDark,
                    onChanged: (val) {
                      ref
                          .read(themeModeProvider.notifier)
                          .setTheme(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                  Divider(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                    height: 1,
                  ),
                  _buildMenuTile(
                    icon: Icons.badge_outlined,
                    title: 'KYC Document Verification',
                    subtitle: 'Driving License, Aadhaar, PAN',
                    isDark: isDark,
                    onTap: () => context.push('/kyc'),
                  ),
                  Divider(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                    height: 1,
                  ),
                  _buildMenuTile(
                    icon: Icons.directions_car_outlined,
                    title: 'Host Your Car with Kruizly',
                    subtitle:
                        'Earn monthly passive income by partnering your vehicle',
                    isDark: isDark,
                    onTap: () => context.push('/host-car'),
                  ),
                  Divider(
                    color: isDark ? AppColors.border : AppColors.lightBorder,
                    height: 1,
                  ),
                  _buildMenuTile(
                    icon: Icons.phone_in_talk_outlined,
                    title: '24x7 Our Concierge Support',
                    subtitle: '+91 98920 19999 (Call or WhatsApp)',
                    isDark: isDark,
                    onTap: () async {
                      final uri = Uri.parse('tel:+919892019999');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Sign Out',
              isOutlined: true,
              backgroundColor: AppColors.error,
              textColor: AppColors.error,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: isDark
                        ? AppColors.surface
                        : AppColors.lightSurface,
                    title: Text(
                      'Sign Out?',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    content: Text(
                      'Are you sure you want to sign out?',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/home');
                }
              },
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDark = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.textSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: AppColors.textMuted,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isDark = true,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.textSecondary
              : AppColors.lightTextSecondary,
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        activeTrackColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildHostedCarsSection(
    BuildContext context,
    List<PartnerCarModel> hostedCars,
    bool isDark,
  ) {
    if (hostedCars.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'My Hosted Cars',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${hostedCars.length} ${hostedCars.length == 1 ? "Car" : "Cars"}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => context.push('/host-car'),
              icon: const Icon(Icons.add, size: 16, color: AppColors.primaryLight),
              label: const Text(
                'List Car',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...hostedCars.map((car) => _buildHostedCarCard(context, car, isDark)),
      ],
    );
  }

  Widget _buildHostedCarCard(
    BuildContext context,
    PartnerCarModel car,
    bool isDark,
  ) {
    final assetPath = AppAssets.getFleetImage(car.fullName);
    final isFixed = car.isFixedMonthly;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.themeSurfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vehicle Image Preview
          SizedBox(
            height: 140,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) => Image.asset(
                          'assets/fleet/Toyota Glanza.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06D6A0).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF06D6A0).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      car.status.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF06D6A0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOSTED VEHICLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Color(0xFF4FD7FF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  car.fullName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Payout Model Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isFixed
                            ? const Color(0xFF06D6A0)
                            : const Color(0xFF4FD7FF))
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (isFixed
                              ? const Color(0xFF06D6A0)
                              : const Color(0xFF4FD7FF))
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFixed
                              ? const Color(0xFF06D6A0)
                              : const Color(0xFF4FD7FF),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isFixed
                            ? 'Fixed Monthly Retainer • ₹${car.fixedMonthlyAmount > 0 ? car.fixedMonthlyAmount.toInt() : 35000} / mo'
                            : 'Trip Revenue Share • 60% Host Payout / 40% Company',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: isFixed
                              ? const Color(0xFF06D6A0)
                              : const Color(0xFF4FD7FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 2-column info grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: context.themeBorder.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetaCol(
                              'REGISTRATION',
                              car.regNo.isNotEmpty ? car.regNo : 'MH04MU1178',
                              context,
                            ),
                          ),
                          Expanded(
                            child: _buildMetaCol(
                              'LOCATION',
                              car.city.isNotEmpty ? car.city : 'Navi Mumbai',
                              context,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetaCol(
                              'TRANSMISSION',
                              car.transmission,
                              context,
                            ),
                          ),
                          Expanded(
                            child: _buildMetaCol(
                              'YEAR',
                              '${car.year}',
                              context,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Card Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'LISTING ID #${car.carId.isNotEmpty ? car.carId.toUpperCase() : "KZ-HOST"}',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: context.themeTextMuted,
                      ),
                    ),
                    Text(
                      'Managed by Kruizly Admin',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: context.themeTextMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCol(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: context.themeTextMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
