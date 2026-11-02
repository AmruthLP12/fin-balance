import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/status_badge.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_form_dialog.dart';
import 'profile_management_screen.dart';

/// Startup profile selection screen.
/// Guarantees that no dashboard, portfolio, or transaction data is preloaded
/// until a specific profile is selected.
class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeId = ref.watch(activeProfileIdProvider);

    return Scaffold(
      body: SafeArea(
        child: profilesAsync.when(
          data: (profiles) {
            // Find last used profile or first available
            final lastUsedProfile =
                profiles.where((p) => p.id == activeId).firstOrNull ??
                    profiles.firstOrNull;

            return Padding(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (activeId > 0)
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Return to Dashboard',
                        onPressed: () {
                          ref
                              .read(hasSelectedInitialProfileProvider.notifier)
                              .state = true;
                        },
                      ),
                    )
                  else
                    const SizedBox(height: AppSpacing.lg),

                  // Brand & Header
                  const Center(
                    child: FinBalanceLogo(
                      size: 64,
                      showText: true,
                      showTagline: true,
                      axis: Axis.vertical,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Select a profile to continue',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Prominent "Quick Continue" Button
                  if (lastUsedProfile != null) ...[
                    FinCard(
                      backgroundColor: isDark
                          ? AppColors.brandPrimary.withValues(alpha: 0.12)
                          : AppColors.brandPrimary.withValues(alpha: 0.08),
                      borderColor:
                          AppColors.brandPrimary.withValues(alpha: 0.3),
                      onTap: () =>
                          _selectProfile(context, ref, lastUsedProfile.id),
                      child: Row(
                        children: [
                          ProfileAvatar(profile: lastUsedProfile, radius: 24),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Quick Continue as',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    const StatusBadge(
                                      label: 'Last Used',
                                      type: BadgeType.scheduled,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lastUsedProfile.name,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.brandPrimaryLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Profile Grid / List Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ALL PROFILES (${profiles.length})',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.person_add_outlined, size: 18),
                        label: const Text('+ Add Profile'),
                        onPressed: () => _openCreateProfileDialog(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Profiles List
                  Expanded(
                    child: ListView.separated(
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final isLastUsed = profile.id == activeId;

                        return FinCard(
                          onTap: () => _selectProfile(context, ref, profile.id),
                          child: Row(
                            children: [
                              ProfileAvatar(profile: profile, radius: 20),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: AppSpacing.xs,
                                      runSpacing: 2,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          profile.name,
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isLastUsed)
                                          const StatusBadge(
                                            label: 'Last Active',
                                            type: BadgeType.scheduled,
                                          ),
                                        if (profile.isDefault)
                                          const StatusBadge(
                                            label: 'Default',
                                            type: BadgeType.brand,
                                          ),
                                      ],
                                    ),
                                    if (profile.relationship.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        profile.relationship.toUpperCase(),
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action: Manage Profiles
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Manage Family Profiles'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ProfileManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Error loading profiles: $err'),
          ),
        ),
      ),
    );
  }

  void _selectProfile(BuildContext context, WidgetRef ref, int profileId) {
    ref.read(activeProfileIdProvider.notifier).switchProfile(profileId);
    ref.read(hasSelectedInitialProfileProvider.notifier).state = true;
  }

  void _openCreateProfileDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const ProfileFormDialog(),
    );
  }
}
