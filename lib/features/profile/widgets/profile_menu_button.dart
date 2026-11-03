import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../screens/profile_management_screen.dart';
import 'profile_avatar.dart';
import 'profile_form_dialog.dart';

/// Interactive AppBar profile avatar button that opens a compact profile menu/popover.
///
/// Provides quick access to:
/// - Profile details (initials avatar, name, relationship)
/// - Switch Profile action (returns to profile selection screen)
/// - Manage Profiles action (navigates to ProfileManagementScreen)
/// - Add Family Member action (opens ProfileFormDialog)
///
/// Tapping outside dismisses the menu without navigation.
class ProfileMenuButton extends ConsumerWidget {
  final double radius;

  const ProfileMenuButton({super.key, this.radius = 16});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final profile = activeProfileAsync.value;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profileName = profile?.name ?? 'My Profile';
    final relationship = (profile?.relationship != null &&
            profile!.relationship.trim().isNotEmpty)
        ? profile.relationship.trim()
        : 'Self';

    return Theme(
      data: theme.copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color:
              isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            side: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          elevation: 6,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Profile Menu ($profileName)',
        offset: const Offset(0, 46),
        padding: EdgeInsets.zero,
        onSelected: (action) {
          switch (action) {
            case 'switch':
              ref.read(hasSelectedInitialProfileProvider.notifier).state =
                  false;
              break;
            case 'manage':
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ProfileManagementScreen(),
                ),
              );
              break;
            case 'add':
              showDialog<void>(
                context: context,
                builder: (_) => const ProfileFormDialog(),
              );
              break;
          }
        },
        itemBuilder: (context) => [
          // 1. Header: Profile Info Card (non-actionable visual header)
          PopupMenuItem<String>(
            enabled: false,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: 230,
              child: Row(
                children: [
                  ProfileAvatar(profile: profile, radius: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          profileName,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.brandPrimary.withValues(alpha: 0.15)
                                : AppColors.brandPrimary
                                    .withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            relationship.toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.brandPrimaryLight
                                  : AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),

          // 2. Action: Switch Profile
          PopupMenuItem<String>(
            value: 'switch',
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.brandPrimaryLight
                      : AppColors.brandPrimary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Switch Profile',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 3. Action: Manage Profiles
          PopupMenuItem<String>(
            value: 'manage',
            child: Row(
              children: [
                Icon(
                  Icons.manage_accounts_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Manage Profiles',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // 4. Action: Add New Profile
          PopupMenuItem<String>(
            value: 'add',
            child: Row(
              children: [
                Icon(
                  Icons.person_add_outlined,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                const Expanded(
                  child: Text(
                    'Add Family Member',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ProfileAvatar(profile: profile, radius: radius),
        ),
      ),
    );
  }
}
