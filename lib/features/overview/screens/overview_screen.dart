import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/return_to_profiles_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../assets/screens/mutual_fund_search_screen.dart';
import '../../profile/widgets/profile_selector_button.dart';

/// FinBalance Overview / Net Worth Dashboard dynamically scoped to active financial profile.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);

    final profile = activeProfileAsync.value;
    final profileName = profile?.name ?? 'My Profile';

    final assets = assetsAsync.value ?? [];

    final totalAssetsPaise =
        assets.fold<int>(0, (sum, a) => sum + a.currentValuationPaise);
    // Scope control: liabilities are excluded from net worth until liabilities milestone
    const totalLiabilitiesPaise = 0;
    final netWorthPaise = totalAssetsPaise;

    return Scaffold(
      appBar: AppBar(
        leading: const ReturnToProfilesButton(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.15),
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 20,
                color: AppColors.brandPrimaryLight,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Flexible(
              child: Text(
                AppConstants.appName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: const [
          ProfileSelectorButton(compact: true),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Net Worth Hero Card
          FinCard(
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '$profileName’s NET WORTH'.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const StatusBadge(
                      label: '100% Offline',
                      type: BadgeType.neutral,
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.formatPaise(netWorthPaise),
                  style: AppTypography.heroAmount.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Divider(),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.asset,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Total Assets',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(totalAssetsPaise),
                            style: AppTypography.amountMedium.copyWith(
                              color: AppColors.asset,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.liability,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Total Liabilities',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyFormatter.formatPaise(
                                totalLiabilitiesPaise),
                            style: AppTypography.amountMedium.copyWith(
                              color: AppColors.liability,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Quick Stats Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  label: 'Active Assets',
                  value: CurrencyFormatter.formatPaise(totalAssetsPaise),
                  subtitle: '${assets.length} items tracked',
                  accentColor: AppColors.asset,
                  icon: Icons.trending_up_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: 'Liabilities',
                  value: '₹0',
                  subtitle: 'Future Milestone',
                  accentColor: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  icon: Icons.credit_card_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Portfolio Breakdown / Recent Holdings Section
          SectionHeader(
            title: '$profileName’s Holdings',
            actionLabel: 'Search Schemes',
            onActionTap: () => _openSearch(context),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (assets.isEmpty)
            EmptyStateView(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Assets in $profileName’s Balance Sheet',
              description:
                  'Search Indian mutual funds or add holdings to calculate $profileName’s verified net worth.',
              actionLabel: 'Search Mutual Funds',
              onAction: () => _openSearch(context),
            )
          else
            ...assets.take(5).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: FinCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: AppTypography.titleMedium
                                    .copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Invested: ${CurrencyFormatter.formatPaise(item.initialValuePaise)}',
                                style: AppTypography.bodySmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          CurrencyFormatter.formatPaise(
                              item.currentValuationPaise),
                          style: AppTypography.cardAmount.copyWith(
                            color: AppColors.asset,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MutualFundSearchScreen(),
      ),
    );
  }
}
