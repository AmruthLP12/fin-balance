import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../assets/screens/mutual_fund_search_screen.dart';
import '../../profile/widgets/profile_avatar.dart';

/// FinBalance Overview / Net Worth Dashboard dynamically scoped to active financial profile.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  static const List<Color> _chartPalette = [
    AppColors.brandPrimary,
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
    Color(0xFF6366F1),
    Color(0xFF14B8A6),
    Color(0xFFE11D48),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    final profile = activeProfileAsync.value;
    final profileName = profile?.name ?? 'My Profile';

    final assets = assetsAsync.value ?? <FinancialItem>[];
    final activeAssets = assets.where((a) => a.status == 'active').toList();
    final transactions = transactionsAsync.value ?? <Transaction>[];
    final categoriesList = categoriesAsync.value ?? <FinancialCategory>[];
    final categoriesMap = {for (final c in categoriesList) c.id: c.name};

    final totalAssetsPaise = activeAssets.fold<int>(
      0,
      (sum, a) => sum + a.currentValuationPaise,
    );
    // Milestone Scope Control: Liabilities are 0 in net worth until liabilities milestone
    const totalLiabilitiesPaise = 0;
    final netWorthPaise = totalAssetsPaise - totalLiabilitiesPaise;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Tooltip(
          message: 'Switch Family Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(hasSelectedInitialProfileProvider.notifier).state =
                  false;
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FinBalanceLogo(
                    size: 28,
                    showText: true,
                    showTagline: false,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.unfold_more_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          Tooltip(
            message: 'Switch Family Profile',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ref.read(hasSelectedInitialProfileProvider.notifier).state =
                    false;
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProfileAvatar(profile: profile, radius: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
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
                          Row(
                            children: [
                              Text(
                                '₹0',
                                style: AppTypography.amountMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Asset Allocation Donut Chart Section
          _buildAssetAllocationSection(
            context: context,
            isDark: isDark,
            activeAssets: activeAssets,
            categoriesMap: categoriesMap,
            totalValuationPaise: totalAssetsPaise,
          ),
          const SizedBox(height: AppSpacing.lg),

          // Recent Activity Section
          SectionHeader(
            title: 'Recent Activity',
            actionLabel: 'Search Schemes',
            onActionTap: () => _openSearch(context),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (transactions.isEmpty)
            EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No Investment Activity Yet',
              description:
                  'Transactions recorded from SIP installments or asset investments for $profileName will appear here.',
              actionLabel: 'Search Mutual Funds',
              onAction: () => _openSearch(context),
            )
          else
            ...transactions.take(5).map((tx) {
              final isInvestment = tx.transactionType == 'investment_purchase';
              final isExpense = tx.transactionType == 'expense';
              final isIncome = tx.transactionType == 'income';

              final Color amountColor = isIncome
                  ? AppColors.asset
                  : (isInvestment
                      ? AppColors.brandPrimaryLight
                      : (isExpense
                          ? AppColors.liability
                          : (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)));

              final prefix = isIncome ? '+' : '-';
              final titleText = tx.notes?.isNotEmpty == true
                  ? tx.notes!
                  : (categoriesMap[tx.categoryId] ??
                      tx.transactionType.replaceAll('_', ' ').toUpperCase());

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: FinCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: amountColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInvestment
                              ? Icons.trending_up_rounded
                              : (isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded),
                          size: 18,
                          color: amountColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatter.formatDate(tx.transactionDate),
                              style: AppTypography.bodySmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '$prefix${CurrencyFormatter.formatPaise(tx.amountPaise)}',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: amountColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAssetAllocationSection({
    required BuildContext context,
    required bool isDark,
    required List<FinancialItem> activeAssets,
    required Map<int, String> categoriesMap,
    required int totalValuationPaise,
  }) {
    if (activeAssets.isEmpty || totalValuationPaise <= 0) {
      return FinCard(
        child: EmptyStateView(
          icon: Icons.pie_chart_outline_rounded,
          title: 'No Asset Allocation Data',
          description:
              'Add mutual fund schemes or assets to view the category breakdown.',
          actionLabel: 'Search Mutual Funds',
          onAction: () => _openSearch(context),
        ),
      );
    }

    // Group valuation by category
    final Map<String, int> categoryTotals = {};
    for (final item in activeAssets) {
      final catName =
          categoriesMap[item.categoryId] ?? _formatSubtype(item.subType);
      categoryTotals[catName] =
          (categoryTotals[catName] ?? 0) + item.currentValuationPaise;
    }

    // Sort categories descending by valuation
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> chartSections = [];
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final color = _chartPalette[i % _chartPalette.length];
      final percentage = (entry.value / totalValuationPaise) * 100;

      chartSections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: percentage >= 5 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 36,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Asset Category Allocation',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      sections: chartSections,
                      centerSpaceRadius: 36,
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  flex: 6,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final entry = sortedCategories[i];
                      final color = _chartPalette[i % _chartPalette.length];
                      final pct = (entry.value / totalValuationPaise) * 100;

                      return Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${pct.toStringAsFixed(1)}%',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatSubtype(String subType) {
    switch (subType) {
      case 'mutual_fund':
        return 'Mutual Funds';
      case 'stock':
        return 'Stocks';
      case 'fixed_deposit':
        return 'Fixed Deposits';
      case 'gold':
        return 'Gold';
      case 'ppf':
        return 'PPF';
      case 'epf':
        return 'EPF';
      case 'gpf':
        return 'GPF';
      case 'nps':
        return 'NPS';
      case 'bond':
        return 'Bonds';
      case 'cash':
        return 'Cash & Bank';
      default:
        return 'Other Assets';
    }
  }

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MutualFundSearchScreen(),
      ),
    );
  }
}
