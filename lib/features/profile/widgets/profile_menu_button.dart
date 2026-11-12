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
/// - Up to 3 profiles to switch to directly, plus "Show more" (profile selection screen)
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
    final allProfiles = ref.watch(allProfilesProvider).value ?? const [];
    final activeId = ref.watch(activeProfileIdProvider);
    // Active profile first, then the others, at most 3 in the menu.
    final shown = ([
      ...allProfiles.where((p) => p.id == activeId),
      ...allProfiles.where((p) => p.id != activeId),
    ]).take(3).toList();
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
          if (action.startsWith('profile:')) {
            ref
                .read(activeProfileIdProvider.notifier)
                .switchProfile(int.parse(action.substring(8)));
            return;
          }
          switch (action) {
            case 'more':
              ref.read(hasSelectedInitialProfileProvider.notifier).state =
                  false;
              // Close any screen opened on top (e.g. Settings from the start page).
              Navigator.of(context).popUntil((r) => r.isFirst);
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

          // 2. Profiles to switch to (up to 3), then "Show more"
          for (final p in shown)
            PopupMenuItem<String>(
              value: 'profile:${p.id}',
              child: Row(
                children: [
                  ProfileAvatar(profile: p, radius: 12),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (p.id == activeId)
                    const Icon(Icons.check_rounded, size: 18),
                ],
              ),
            ),
          if (allProfiles.length > shown.length)
            PopupMenuItem<String>(
              value: 'more',
              child: Row(
                children: [
                  Icon(
                    Icons.groups_rounded,
                    size: 20,
                    color: isDark
                        ? AppColors.brandPrimaryLight
                        : AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Show more (${allProfiles.length - shown.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const PopupMenuDivider(height: 1),

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
