import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../database/app_database.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/profile_form_dialog.dart';
import 'profile_management_screen.dart';

/// Startup and profile switching screen.
/// Displays a family-wide financial overview followed by scannable profile cards.
/// Guarantees no profile-scoped dashboard data is preselected until the user picks a profile.
class ProfileSelectionScreen extends ConsumerWidget {
  const ProfileSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profilesAsync = ref.watch(allProfilesProvider);
    final householdAssetsAsync = ref.watch(householdAssetsProvider);
    final householdAssets = householdAssetsAsync.value ?? <FinancialItem>[];

    // Family-wide aggregated metrics
    final totalFamilyAssetsPaise = householdAssets
        .where((a) => a.status == 'active')
        .fold<int>(0, (sum, a) => sum + a.currentValuationPaise);
    const totalFamilyLiabilitiesPaise = 0; // Upcoming milestone
    final familyNetWorthPaise =
        totalFamilyAssetsPaise - totalFamilyLiabilitiesPaise;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 44,
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        child: profilesAsync.when(
          data: (profiles) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(allProfilesProvider);
                ref.invalidate(householdAssetsProvider);
              },
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: AppSpacing.screenPadding,
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: AppSpacing.md),
                        // Brand Logo Header (No close X button)
                        const Center(
                          child: FinBalanceLogo(
                            size: 56,
                            showText: true,
                            showTagline: true,
                            axis: Axis.vertical,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Family-Wide Financial Overview Card
                        _buildFamilyOverviewCard(
                          isDark: isDark,
                          netWorthPaise: familyNetWorthPaise,
                          assetsPaise: totalFamilyAssetsPaise,
                          liabilitiesPaise: totalFamilyLiabilitiesPaise,
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        // Section Header: All Family Profiles
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'FAMILY PROFILES (${profiles.length})',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_rounded),
                              tooltip: 'Add Profile',
                              onPressed: () =>
                                  _openCreateProfileDialog(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ]),
                    ),
                  ),

                  // Profile List
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final profile = profiles[index];
                          final profileAssets = householdAssets
                              .where((a) =>
                                  a.profileId == profile.id &&
                                  a.status == 'active')
                              .fold<int>(
                                  0, (sum, a) => sum + a.currentValuationPaise);
                          const profileLiabilities = 0; // Upcoming
                          final profileNetWorth =
                              profileAssets - profileLiabilities;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildProfileCard(
                              context: context,
                              ref: ref,
                              profile: profile,
                              isDark: isDark,
                              assetsPaise: profileAssets,
                              liabilitiesPaise: profileLiabilities,
                              netWorthPaise: profileNetWorth,
                            ),
                          );
                        },
                        childCount: profiles.length,
                      ),
                    ),
                  ),

                  // Bottom Action: Manage Profiles
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    sliver: SliverToBoxAdapter(
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

  Widget _buildFamilyOverviewCard({
    required bool isDark,
    required int netWorthPaise,
    required int assetsPaise,
    required int liabilitiesPaise,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : AppColors.brandPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? AppColors.darkBorder
              : AppColors.brandPrimary.withValues(alpha: 0.2),
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_rounded,
                size: 20,
                color: isDark
                    ? AppColors.brandPrimaryLight
                    : AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Family-Wide Financial Overview',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Family Assets',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(assetsPaise),
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.asset,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Family Liabilities',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        Text(
                          '₹0',
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.liability,
                          ),
                        ),
                        Text(
                          '• Upcoming',
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Family Net Worth',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormatter.formatPaise(netWorthPaise),
            style: AppTypography.headlineLarge.copyWith(
              fontWeight: FontWeight.w800,
              color:
                  isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required WidgetRef ref,
    required FinancialProfile profile,
    required bool isDark,
    required int assetsPaise,
    required int liabilitiesPaise,
    required int netWorthPaise,
  }) {
    final relLabel = profile.relationship.trim().isNotEmpty
        ? profile.relationship.trim().toUpperCase()
        : 'MEMBER';

    return FinCard(
      onTap: () => _selectProfile(context, ref, profile.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(profile: profile, radius: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      relLabel,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.brandPrimaryLight,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(netWorthPaise),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assets',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(assetsPaise),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.asset,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liabilities',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹0',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
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
        ],
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
