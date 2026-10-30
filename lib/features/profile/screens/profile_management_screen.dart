import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_form_dialog.dart';

/// Full screen for managing all family financial profiles.
class ProfileManagementScreen extends ConsumerWidget {
  const ProfileManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesWithArchivedProvider);
    final activeId = ref.watch(activeProfileIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Family Profiles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Add Profile',
            onPressed: () => _openCreateDialog(context),
          ),
        ],
      ),
      body: profilesAsync.when(
        data: (profiles) {
          if (profiles.isEmpty) {
            return EmptyStateView(
              icon: Icons.people_outline_rounded,
              title: 'No Profiles Configured',
              description:
                  'Create individual profiles for family members to isolate assets, liabilities, and investments.',
              actionLabel: 'Create Profile',
              onAction: () => _openCreateDialog(context),
            );
          }

          final activeProfiles = profiles.where((p) => !p.isArchived).toList();
          final archivedProfiles = profiles.where((p) => p.isArchived).toList();

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Info Banner
              FinCard(
                backgroundColor: isDark
                    ? AppColors.brandPrimary.withValues(alpha: 0.1)
                    : AppColors.brandPrimary.withValues(alpha: 0.05),
                borderColor: AppColors.brandPrimary.withValues(alpha: 0.3),
                child: Row(
                  children: [
                    const Icon(
                      Icons.diversity_3_rounded,
                      color: AppColors.brandPrimaryLight,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Multi-Person Family Finance',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Each family member has independent portfolios, liabilities, and transactions. Switching profiles instantly recalibrates the dashboard.',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Active Profiles Section
              SectionHeader(
                title: 'Active Profiles (${activeProfiles.length})',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...activeProfiles.map((p) => _buildProfileCard(
                    context,
                    ref,
                    profile: p,
                    isActive: p.id == activeId,
                    isDark: isDark,
                  )),

              if (archivedProfiles.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                SectionHeader(
                  title: 'Archived Profiles (${archivedProfiles.length})',
                ),
                const SizedBox(height: AppSpacing.sm),
                ...archivedProfiles.map((p) => _buildProfileCard(
                      context,
                      ref,
                      profile: p,
                      isActive: false,
                      isDark: isDark,
                      isArchived: true,
                    )),
              ],

              const SizedBox(height: 80), // Fab clearance
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading profiles: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Profile'),
        onPressed: () => _openCreateDialog(context),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref, {
    required FinancialProfile profile,
    required bool isActive,
    required bool isDark,
    bool isArchived = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        backgroundColor: isActive
            ? (isDark
                ? AppColors.brandPrimary.withValues(alpha: 0.15)
                : AppColors.brandPrimary.withValues(alpha: 0.08))
            : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface),
        borderColor: isActive
            ? AppColors.brandPrimary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        child: Column(
          children: [
            Row(
              children: [
                ProfileAvatar(profile: profile, radius: 24),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.name,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          if (isActive)
                            const StatusBadge(
                              label: 'Active Now',
                              type: BadgeType.asset,
                            ),
                          if (profile.isDefault) ...[
                            const SizedBox(width: 4),
                            const StatusBadge(
                              label: 'Default',
                              type: BadgeType.neutral,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_formatRelationship(profile.relationship)} • Created ${DateFormatter.formatDate(profile.createdAt)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                      if (profile.description != null &&
                          profile.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          profile.description!,
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  tooltip: 'Options',
                  onSelected: (action) =>
                      _handleAction(context, ref, action, profile),
                  itemBuilder: (context) => [
                    if (!isActive && !isArchived)
                      const PopupMenuItem(
                        value: 'switch',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Switch to Profile'),
                          ],
                        ),
                      ),
                    if (!profile.isDefault && !isArchived)
                      const PopupMenuItem(
                        value: 'make_default',
                        child: Row(
                          children: [
                            Icon(Icons.star_outline_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit Profile'),
                        ],
                      ),
                    ),
                    if (!isArchived)
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Archive Profile'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'unarchive',
                        child: Row(
                          children: [
                            Icon(Icons.unarchive_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Restore Profile'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 20, color: AppColors.liability),
                          SizedBox(width: 8),
                          Text('Delete Profile',
                              style: TextStyle(color: AppColors.liability)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (!isActive && !isArchived) ...[
              const SizedBox(height: AppSpacing.sm),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                  label: const Text('Switch to this profile'),
                  onPressed: () {
                    ref
                        .read(activeProfileIdProvider.notifier)
                        .switchProfile(profile.id);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openCreateDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const ProfileFormDialog(),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    FinancialProfile profile,
  ) async {
    final dao = ref.read(profilesDaoProvider);

    switch (action) {
      case 'switch':
        await ref
            .read(activeProfileIdProvider.notifier)
            .switchProfile(profile.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Switched to "${profile.name}"'),
              backgroundColor: AppColors.brandPrimary,
            ),
          );
        }
        break;

      case 'make_default':
        await dao.setDefaultProfile(profile.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${profile.name}" is now the default profile'),
              backgroundColor: AppColors.asset,
            ),
          );
        }
        break;

      case 'edit':
        await showDialog<void>(
          context: context,
          builder: (_) => ProfileFormDialog(profileToEdit: profile),
        );
        break;

      case 'archive':
        final activeCount = await dao.countActiveProfiles();
        if (activeCount <= 1) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Cannot archive the only active profile. Create another first.'),
                backgroundColor: AppColors.liability,
              ),
            );
          }
          return;
        }

        await dao.archiveProfile(profile.id);
        // If current profile was archived, switch to default
        final currentActiveId = ref.read(activeProfileIdProvider);
        if (currentActiveId == profile.id) {
          final def = await dao.getDefaultProfile();
          if (def != null) {
            await ref
                .read(activeProfileIdProvider.notifier)
                .switchProfile(def.id);
          }
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Archived "${profile.name}". Historical records remain intact.'),
            ),
          );
        }
        break;

      case 'unarchive':
        await dao.unarchiveProfile(profile.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Restored "${profile.name}" to active profiles.'),
              backgroundColor: AppColors.asset,
            ),
          );
        }
        break;

      case 'delete':
        final hasHistory = await dao.hasFinancialHistory(profile.id);
        if (!context.mounted) return;

        if (hasHistory) {
          // Prevent accidental deletion of profiles containing financial records
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.shield_outlined,
                  color: AppColors.warning, size: 36),
              title: const Text('Profile Has Financial History'),
              content: Text(
                'Profile "${profile.name}" contains recorded assets, accounts, or ledger transactions.\n\nTo preserve audit trails and avoid data loss, this profile cannot be permanently deleted.\n\nYou can Archive this profile instead to hide it from daily dashboards while keeping records secure.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _handleAction(context, ref, 'archive', profile);
                  },
                  child: const Text('Archive Instead'),
                ),
              ],
            ),
          );
        } else {
          // Safe to delete if no history exists
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              icon: const Icon(Icons.delete_forever_rounded,
                  color: AppColors.liability, size: 36),
              title: Text('Delete "${profile.name}"?'),
              content: const Text(
                'This profile has no recorded assets or transactions. Are you sure you want to permanently delete it?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.liability),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await dao.deleteProfile(profile.id);
                    final currentActive = ref.read(activeProfileIdProvider);
                    if (currentActive == profile.id) {
                      final def = await dao.getDefaultProfile();
                      if (def != null) {
                        await ref
                            .read(activeProfileIdProvider.notifier)
                            .switchProfile(def.id);
                      }
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Deleted "${profile.name}"'),
                        ),
                      );
                    }
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        }
        break;
    }
  }

  String _formatRelationship(String rel) {
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
        return 'Family Member';
    }
  }
}
