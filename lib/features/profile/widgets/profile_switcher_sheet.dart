import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/status_badge.dart';
import '../screens/profile_management_screen.dart';
import 'profile_avatar.dart';
import 'profile_form_dialog.dart';

/// Bottom sheet allowing quick switching between family members and profiles.
class ProfileSwitcherSheet extends ConsumerWidget {
  const ProfileSwitcherSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeId = ref.watch(activeProfileIdProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Profiles',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a profile to view isolated portfolio & net worth',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Manage Profiles',
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileManagementScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg),

            // Profile List
            profilesAsync.when(
              data: (profiles) {
                if (profiles.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: Text('No active profiles found')),
                  );
                }

                return Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: profiles.length,
                    separatorBuilder: (_, __) =>
                        const Divider(indent: 72, height: 1),
                    itemBuilder: (context, index) {
                      final p = profiles[index];
                      final isSelected = p.id == activeId;

                      return ListTile(
                        leading: ProfileAvatar(profile: p, radius: 22),
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.name,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (p.isDefault) ...[
                              const SizedBox(width: AppSpacing.xs),
                              const StatusBadge(
                                label: 'Default',
                                type: BadgeType.neutral,
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text(
                          _formatRelationship(p.relationship),
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        trailing: isSelected
                            ? Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.brandPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              )
                            : null,
                        selected: isSelected,
                        onTap: () async {
                          await ref
                              .read(activeProfileIdProvider.notifier)
                              .switchProfile(p.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text('Error loading profiles: $err'),
              ),
            ),

            const Divider(height: AppSpacing.lg),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Add Profile'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog<void>(
                          context: context,
                          builder: (_) => const ProfileFormDialog(),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.manage_accounts_outlined),
                      label: const Text('Manage All'),
                      onPressed: () {
                        Navigator.of(context).pop();
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
            ),
          ],
        ),
      ),
    );
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
        return 'Primary User';
      default:
        return 'Family Member';
    }
  }
}
