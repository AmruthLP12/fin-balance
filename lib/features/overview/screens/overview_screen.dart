import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/financial_categories.dart';
import '../../../core/formatting/currency_formatter.dart';
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
import '../../profile/widgets/profile_menu_button.dart';
import '../widgets/holdings_list_card.dart';
import '../widgets/portfolio_summary_card.dart';

/// FinBalance Overview / Net Worth Dashboard dynamically scoped to active financial profile.
class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  /// Show exact rupees instead of lakh / crore shorthand.
  bool _fullAmounts = false;

  String _money(int paise) => _fullAmounts
      ? CurrencyFormatter.formatPaise(paise)
      : CurrencyFormatter.formatPaiseCompact(paise);

  int _selectedChartIndex =
      0; // 0: Assets & Liabilities (Default), 1: Cash Flow, 2: Portfolio Assets
  int _touchedIndex = -1;

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
  void initState() {
    super.initState();
    _loadSelectedChartPreference();
  }

  Future<void> _loadSelectedChartPreference() async {
    try {
      final db = ref.read(databaseProvider);
      final saved =
          await db.appSettingsDao.getSetting('dashboard_selected_chart');
      if (saved != null && mounted) {
        final parsed = int.tryParse(saved);
        if (parsed != null && parsed >= 0 && parsed <= 2) {
          setState(() => _selectedChartIndex = parsed);
        }
      }
    } catch (_) {
      // Default to 0 (Assets & Liabilities)
    }
  }

  Future<void> _onChartSelected(int index) async {
    setState(() => _selectedChartIndex = index);
    try {
      final db = ref.read(databaseProvider);
      await db.appSettingsDao
          .setSetting('dashboard_selected_chart', index.toString());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);
    final liabilitiesAsync = ref.watch(activeProfileLiabilitiesProvider);
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    final profile = activeProfileAsync.value;
    final profileName = profile?.name ?? 'My Profile';

    final activeAssets = (assetsAsync.value ?? <FinancialItem>[])
        .where((a) => a.status == 'active')
        .toList();
    final activeLiabilities = (liabilitiesAsync.value ?? <FinancialItem>[])
        .where((a) => a.status == 'active')
        .toList();
    final transactions = transactionsAsync.value ?? <Transaction>[];
    final categoriesList = categoriesAsync.value ?? <FinancialCategory>[];
    final categoriesMap = {for (final c in categoriesList) c.id: c.name};

    final totalAssetsPaise = activeAssets.fold<int>(
      0,
      (sum, a) => sum + a.currentValuationPaise,
    );
    final totalLiabilitiesPaise = activeLiabilities.fold<int>(
      0,
      (sum, a) => sum + a.currentValuationPaise,
    );
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
          IconButton(
            tooltip: 'Support',
            icon: const Icon(Icons.favorite_border_rounded),
            onPressed: () => ref.read(mainTabProvider.notifier).state = 4,
          ),
          const ProfileMenuButton(radius: 16),
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
                    IconButton(
                      tooltip: _fullAmounts
                          ? 'Show in lakh / crore'
                          : 'Show full amounts',
                      visualDensity: VisualDensity.compact,
                      iconSize: 20,
                      icon: Icon(_fullAmounts
                          ? Icons.unfold_less_rounded
                          : Icons.unfold_more_rounded),
                      onPressed: () =>
                          setState(() => _fullAmounts = !_fullAmounts),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _money(netWorthPaise),
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
                            _money(totalAssetsPaise),
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
                            _money(totalLiabilitiesPaise),
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
                if (activeAssets.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  PortfolioSummaryCard(
                    activeAssets: activeAssets,
                    transactions: transactions,
                    embedded: true,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Distribution & Analytics Section (Three switchable charts)
          _buildDistributionSection(
            context: context,
            isDark: isDark,
            activeAssets: activeAssets,
            activeLiabilities: activeLiabilities,
            transactions: transactions,
            categoriesMap: categoriesMap,
            totalAssetsPaise: totalAssetsPaise,
            totalLiabilitiesPaise: totalLiabilitiesPaise,
          ),
          const SizedBox(height: AppSpacing.lg),
          HoldingsListCard(
            assets: activeAssets,
            liabilities: activeLiabilities,
            onTap: (groupValue, {required isLiability}) {
              if (isLiability) {
                ref.read(mainTabProvider.notifier).state = 2;
              } else {
                ref.read(assetsCategoryRequestProvider.notifier).state =
                    groupValue;
                ref.read(mainTabProvider.notifier).state = 1;
              }
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildDistributionSection({
    required BuildContext context,
    required bool isDark,
    required List<FinancialItem> activeAssets,
    required List<FinancialItem> activeLiabilities,
    required List<Transaction> transactions,
    required Map<int, String> categoriesMap,
    required int totalAssetsPaise,
    required int totalLiabilitiesPaise,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Distribution & Analytics',
        ),
        const SizedBox(height: AppSpacing.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightBackground,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegmentPill(
                  label: 'Assets & Liabilities',
                  isSelected: _selectedChartIndex == 0,
                  isDark: isDark,
                  onTap: () => _onChartSelected(0),
                ),
                _buildSegmentPill(
                  label: 'Cash Flow',
                  isSelected: _selectedChartIndex == 1,
                  isDark: isDark,
                  onTap: () => _onChartSelected(1),
                ),
                _buildSegmentPill(
                  label: 'Portfolio Assets',
                  isSelected: _selectedChartIndex == 2,
                  isDark: isDark,
                  onTap: () => _onChartSelected(2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_selectedChartIndex == 0)
          _buildUnifiedAssetLiabilityChartCard(
            context: context,
            isDark: isDark,
            activeAssets: activeAssets,
            activeLiabilities: activeLiabilities,
            categoriesMap: categoriesMap,
            totalAssetsPaise: totalAssetsPaise,
            totalLiabilitiesPaise: totalLiabilitiesPaise,
          )
        else if (_selectedChartIndex == 1)
          _buildCashFlowChartCard(
            context: context,
            isDark: isDark,
            transactions: transactions,
          )
        else
          _buildAssetAllocationCard(
            context: context,
            isDark: isDark,
            activeAssets: activeAssets,
            categoriesMap: categoriesMap,
            totalValuationPaise: totalAssetsPaise,
          ),
      ],
    );
  }

  Widget _buildSegmentPill({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.brandPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
        ),
      ),
    );
  }

  /// 1. Total assets vs total liabilities.
  Widget _buildUnifiedAssetLiabilityChartCard({
    required BuildContext context,
    required bool isDark,
    required List<FinancialItem> activeAssets,
    required List<FinancialItem> activeLiabilities,
    required Map<int, String> categoriesMap,
    required int totalAssetsPaise,
    required int totalLiabilitiesPaise,
  }) {
    final grand = totalAssetsPaise + totalLiabilitiesPaise;
    if (grand <= 0) {
      return FinCard(
        child: EmptyStateView(
          icon: Icons.pie_chart_outline_rounded,
          title: 'No Data Yet',
          description:
              'Add mutual fund schemes or assets to compare assets and liabilities.',
          actionLabel: 'Search Mutual Funds',
          onAction: () => _openSearch(context),
        ),
      );
    }
    final rows = [
      ('Total Assets', totalAssetsPaise, AppColors.asset),
      ('Total Liabilities', totalLiabilitiesPaise, AppColors.liability),
    ];
    return FinCard(
      child: SizedBox(
        height: 150,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: PieChart(
                PieChartData(
                  sections: [
                    for (final r in rows)
                      if (r.$2 > 0)
                        PieChartSectionData(
                          color: r.$3,
                          value: r.$2.toDouble(),
                          title: '${(r.$2 / grand * 100).toStringAsFixed(0)}%',
                          radius: 36,
                          titleStyle: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                  ],
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: r.$3, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(r.$1,
                                  style: AppTypography.bodySmall
                                      .copyWith(fontWeight: FontWeight.w500))),
                          Text(_money(r.$2),
                              style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w700, color: r.$3)),
                        ],
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

  /// 2. Cash Flow Chart Card
  Widget _buildCashFlowChartCard({
    required BuildContext context,
    required bool isDark,
    required List<Transaction> transactions,
  }) {
    int incomePaise = 0;
    int expensePaise = 0;
    int investmentOutflowPaise = 0;

    for (final txn in transactions) {
      if (txn.transactionType == 'income') {
        incomePaise += txn.amountPaise;
      } else if (txn.transactionType == 'expense' ||
          txn.transactionType == 'debt_repayment') {
        expensePaise += txn.amountPaise;
      } else if (txn.transactionType == 'investment_purchase' ||
          txn.transactionType == 'sip_investment') {
        investmentOutflowPaise += txn.amountPaise;
      }
    }

    final totalOutflowPaise = expensePaise + investmentOutflowPaise;
    final netCashFlowPaise = incomePaise - totalOutflowPaise;
    final savingsRate = incomePaise > 0
        ? (((incomePaise - expensePaise) / incomePaise) * 100)
            .clamp(-100.0, 100.0)
        : 0.0;

    if (transactions.isEmpty || (incomePaise == 0 && totalOutflowPaise == 0)) {
      return FinCard(
        child: EmptyStateView(
          icon: Icons.swap_vert_circle_outlined,
          title: 'No Cash Flow Activity Yet',
          description:
              'Income, expense, or SIP transactions recorded for this profile will appear in the cash flow graph.',
          actionLabel: 'Search Mutual Funds',
          onAction: () => _openSearch(context),
        ),
      );
    }

    final maxVal = [
      incomePaise.toDouble(),
      totalOutflowPaise.toDouble(),
      netCashFlowPaise.abs().toDouble(),
    ].reduce((a, b) => a > b ? a : b);

    final maxY = maxVal > 0 ? (maxVal * 1.25) / 100000 : 10.0;

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cash Flow Overview',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              StatusBadge(
                label: savingsRate >= 0
                    ? '${savingsRate.toStringAsFixed(1)}% Saved'
                    : 'Deficit',
                type: savingsRate >= 20
                    ? BadgeType.asset
                    : (savingsRate >= 0
                        ? BadgeType.neutral
                        : BadgeType.liability),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            (netCashFlowPaise >= 0 ? '+' : '') +
                CurrencyFormatter.formatPaise(netCashFlowPaise),
            style: AppTypography.cardAmount.copyWith(
              color:
                  netCashFlowPaise >= 0 ? AppColors.asset : AppColors.liability,
            ),
          ),
          Text(
            'Net Cash Movement',
            style: AppTypography.labelSmall.copyWith(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 140,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label = groupIndex == 0
                          ? 'Inflow'
                          : (groupIndex == 1 ? 'Outflow' : 'Net Flow');
                      final paise = groupIndex == 0
                          ? incomePaise
                          : (groupIndex == 1
                              ? totalOutflowPaise
                              : netCashFlowPaise);
                      return BarTooltipItem(
                        '$label\n${CurrencyFormatter.formatPaise(paise)}',
                        TextStyle(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String title;
                        switch (value.toInt()) {
                          case 0:
                            title = 'Inflow';
                            break;
                          case 1:
                            title = 'Outflow';
                            break;
                          case 2:
                            title = 'Net';
                            break;
                          default:
                            title = '';
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            title,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: incomePaise > 0 ? (incomePaise / 100000) : 0.1,
                        color: AppColors.asset,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: totalOutflowPaise > 0
                            ? (totalOutflowPaise / 100000)
                            : 0.1,
                        color: AppColors.liability,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: netCashFlowPaise.abs() > 0
                            ? (netCashFlowPaise.abs() / 100000)
                            : 0.1,
                        color: netCashFlowPaise >= 0
                            ? AppColors.asset
                            : AppColors.liability,
                        width: 24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildCashFlowMetric(
                  label: 'Inflows',
                  amountPaise: incomePaise,
                  color: AppColors.asset,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildCashFlowMetric(
                  label: 'Expenses',
                  amountPaise: expensePaise,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildCashFlowMetric(
                  label: 'SIP Investments',
                  amountPaise: investmentOutflowPaise,
                  color: AppColors.brandPrimaryLight,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCashFlowMetric({
    required String label,
    required int amountPaise,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CurrencyFormatter.formatPaise(amountPaise),
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  /// 3. Portfolio Asset Allocation Donut Chart Card
  Widget _buildAssetAllocationCard({
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

    // Group valuation by canonical category
    final Map<String, int> categoryTotals = {};
    for (final item in activeAssets) {
      final rawName = categoriesMap[item.categoryId] ?? item.subType;
      final canonical = FinancialCategoryConstants.normalizeCategoryName(
        rawName,
        subType: item.subType,
      );
      categoryTotals[canonical] =
          (categoryTotals[canonical] ?? 0) + item.currentValuationPaise;
    }

    // Sort categories descending by valuation
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<PieChartSectionData> chartSections = [];
    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final isTouched = i == _touchedIndex;
      final color = _chartPalette[i % _chartPalette.length];
      final percentage = (entry.value / totalValuationPaise) * 100;

      chartSections.add(
        PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: isTouched ? 42 : 36,
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse
                                .touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
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
                    itemCount: sortedCategories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 4),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                CurrencyFormatter.formatPaise(entry.value),
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
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

  void _openSearch(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MutualFundSearchScreen(),
      ),
    );
  }
}
