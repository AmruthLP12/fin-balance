import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import 'profile_avatar.dart';
import 'profile_switcher_sheet.dart';

/// Interactive AppBar button displaying the active profile with a selector sheet trigger.
class ProfileSelectorButton extends ConsumerWidget {
  final bool compact;

  const ProfileSelectorButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return activeProfileAsync.when(
      data: (profile) {
        final displayName = profile?.name ?? 'Profile';
        final relationship = profile?.relationship ?? 'self';

        if (compact) {
          return IconButton(
            tooltip: 'Switch Profile ($displayName)',
            icon: ProfileAvatar(profile: profile, radius: 14),
            onPressed: () => _openSwitcher(context),
          );
        }

        return InkWell(
          onTap: () => _openSwitcher(context),
          borderRadius: AppSpacing.borderRadiusPill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurface,
              borderRadius: AppSpacing.borderRadiusPill,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfileAvatar(profile: profile, radius: 13),
                const SizedBox(width: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 130),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _relationshipLabel(relationship),
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 20,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 32,
        height: 32,
        child: Icon(Icons.account_circle_outlined, size: 24),
      ),
      error: (_, __) => const Icon(Icons.person_outline),
    );
  }

  void _openSwitcher(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const ProfileSwitcherSheet(),
    );
  }

  String _relationshipLabel(String rel) {
    switch (rel.toLowerCase()) {
      case 'father':
        return 'Father';
      case 'mother':
        return 'Mother';
      case 'spouse':
        return 'Spouse';
      case 'child':
        return 'Child';
      case 'self':
        return 'Self';
      default:
        return 'Family';
    }
  }
}
