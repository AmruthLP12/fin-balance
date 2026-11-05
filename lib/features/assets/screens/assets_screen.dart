import 'package:flutter/material.dart';
import '../../../core/constants/asset_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculations/financial_calculator.dart';
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
import '../../profile/widgets/profile_menu_button.dart';
import '../widgets/add_sip_dialog.dart';
import '../widgets/holding_card.dart';
import '../widgets/sip_card.dart';
import 'mutual_fund_search_screen.dart';
import 'sip_details_screen.dart';

/// Assets screen for managing Mutual Funds, Stocks, FDs, Gold, and wealth holdings scoped to the active profile.
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  // Category navigation filter: defaults to 'mutual_fund' as in reference
  String _selectedCategoryFilter = 'mutual_fund';

  @override
  Widget build(BuildContext context) {
    ref.listen<String?>(assetsCategoryRequestProvider, (_, category) {
      if (category == null) return;
      _select(category);
      ref.read(assetsCategoryRequestProvider.notifier).state = null;
    });
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);
    final sipsAsync = ref.watch(activeProfileSipPlansProvider);
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);

    final profileName = activeProfileAsync.value?.name ?? 'Profile';
    final sips = sipsAsync.value ?? [];
    final allTransactions = transactionsAsync.value ?? [];

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
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child:
                  FinBalanceLogo(size: 28, showText: true, showTagline: false),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search & Add Mutual Funds',
            onPressed: () => _openSearchScreen(context),
          ),
          const ProfileMenuButton(radius: 16),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: assetsAsync.when(
        data: (items) {
          final totalCount = items.length;
          int countOf(String v) => items
              .where((i) => groupOf(i.subType, assetGroups).value == v)
              .length;

          final filteredItems = _filterItems(items, _selectedCategoryFilter);

          // Calculate summary metrics for current category view
          final totalCurrentPaise = filteredItems.fold<int>(
              0, (sum, i) => sum + i.currentValuationPaise);
          final totalInvestedPaise =
              filteredItems.fold<int>(0, (sum, i) => sum + i.initialValuePaise);
          final totalPnlPaise = FinancialCalculator.calculateProfitLossPaise(
            investedPaise: totalInvestedPaise,
            currentValuationPaise: totalCurrentPaise,
          );
          final isProfit = totalPnlPaise >= 0;
          final totalPnlPercent = FinancialCalculator.calculateAbsoluteReturn(
            investedPaise: totalInvestedPaise,
            currentValuationPaise: totalCurrentPaise,
          );

          // Calculate Overall XIRR for filtered holdings
          final filteredItemIds = filteredItems.map((i) => i.id).toSet();
          final matchingTransactions = allTransactions
              .where((tx) =>
                  tx.financialItemId != null &&
                  filteredItemIds.contains(tx.financialItemId))
              .toList();

          final overallXirr = FinancialCalculator.calculatePortfolioXirr(
            transactions: matchingTransactions,
            totalValuationPaise: totalCurrentPaise,
          );

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragEnd: _onSwipe,
            child: ListView(
              padding: AppSpacing.screenPadding,
              children: [
                // 1. Category Navigation Row (scrollable pills; the selected one is kept in view)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (value, label) in [
                        ('all', 'All Assets'),
                        for (final g in assetGroups) (g.value, g.label),
                      ]) ...[
                        _buildCategoryPill(
                          label: label,
                          categoryValue: value,
                          count: value == 'all' ? totalCount : countOf(value),
                          isDark: isDark,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // 2. Compact Portfolio Summary Card
                FinCard(
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_categoryDisplayName(_selectedCategoryFilter).toUpperCase()} SUMMARY',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          StatusBadge(
                            label:
                                '${filteredItems.length} ${filteredItems.length == 1 ? 'Holding' : 'Holdings'}',
                            type: BadgeType.neutral,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CURRENT VALUE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                CurrencyFormatter.formatPaise(
                                    totalCurrentPaise),
                                style: AppTypography.heroAmount.copyWith(
                                  fontSize: 20,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'OVERALL P&L',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(totalPnlPaise)} (${totalPnlPercent >= 0 ? '+' : ''}${totalPnlPercent.toStringAsFixed(1)}%)',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isProfit
                                      ? AppColors.asset
                                      : AppColors.liability,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.md,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Invested: ',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatPaise(
                                    totalInvestedPaise),
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Overall IRR: ',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              Text(
                                overallXirr != null
                                    ? '${overallXirr.toStringAsFixed(1)}%'
                                    : '—',
                                style: AppTypography.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: (overallXirr != null &&
                                          overallXirr >= 0)
                                      ? AppColors.asset
                                      : ((overallXirr != null &&
                                              overallXirr < 0)
                                          ? AppColors.liability
                                          : (isDark
                                              ? AppColors.darkTextSecondary
                                              : AppColors.lightTextSecondary)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // 3. Compact Investment Holdings List
                SectionHeader(
                  title:
                      '${_categoryDisplayName(_selectedCategoryFilter)} (${filteredItems.length})',
                  actionLabel: _selectedCategoryFilter == 'mutual_fund' ||
                          _selectedCategoryFilter == 'all'
                      ? 'Search Schemes'
                      : null,
                  onActionTap: () => _openSearchScreen(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (filteredItems.isEmpty)
                  _buildCategoryEmptyState(
                    category: _selectedCategoryFilter,
                    profileName: profileName,
                  )
                else
                  ...filteredItems.map(
                    (item) => HoldingCard(
                      item: item,
                      onTap: () => _openHoldingDetails(context, item),
                      onDelete: () => _confirmDeleteHolding(context, item),
                    ),
                  ),

                // 4. SIP Schedules Section (visible when viewing Mutual Funds or All)
                if (_selectedCategoryFilter == 'mutual_fund' ||
                    _selectedCategoryFilter == 'all') ...[
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(
                    title: 'SIP Schedules (${sips.length})',
                    actionLabel: '+ Add SIP',
                    onActionTap: () => _openAddSipDialog(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (sips.isEmpty)
                    FinCard(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              color: AppColors.scheduled),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('No Active SIPs',
                                    style: AppTypography.titleMedium),
                                Text(
                                  'Set up ongoing or bulk historical SIP investments for $profileName.',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : AppColors.lightTextSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => _openAddSipDialog(context),
                            child: const Text('Add SIP'),
                          ),
                        ],
                      ),
                    )
                  else
                    ...sips.map((sip) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SipCard(sip: sip),
                        )),
                ],

                const SizedBox(height: 80), // FAB clearance
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Error loading assets: $err'),
          ),
        ),
      ),
    );
  }

  static final _tabOrder = ['all', for (final g in assetGroups) g.value];
  final _pillKeys = {for (final v in _tabOrder) v: GlobalKey()};

  void _select(String category) {
    setState(() => _selectedCategoryFilter = category);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _pillKeys[category]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 200), alignment: 0.5);
      }
    });
  }

  /// Swipe left/right to move between category tabs.
  void _onSwipe(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 300) return;
    final i = _tabOrder.indexOf(_selectedCategoryFilter);
    final next = i + (v < 0 ? 1 : -1);
    if (next >= 0 && next < _tabOrder.length) {
      _select(_tabOrder[next]);
    }
  }

  List<FinancialItem> _filterItems(List<FinancialItem> items, String filter) {
    if (filter == 'all') return items;
    return items
        .where((i) => groupOf(i.subType, assetGroups).value == filter)
        .toList();
  }

  Widget _buildCategoryPill({
    required String label,
    required String categoryValue,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _selectedCategoryFilter == categoryValue;
    return InkWell(
      key: _pillKeys[categoryValue],
      onTap: () => _select(categoryValue),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandPrimary
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (count > 0 || isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : (isDark
                          ? AppColors.darkSurfaceHighlight
                          : AppColors.lightSurfaceHighlight),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryEmptyState({
    required String category,
    required String profileName,
  }) {
    switch (category) {
      case 'stock':
        return EmptyStateView(
          icon: Icons.trending_up_rounded,
          title: 'No Stocks or ETFs Added',
          description:
              'Equity holdings for $profileName will be tracked here. Stock portfolio management is planned for upcoming milestones.',
        );
      case 'fixed_income':
        return EmptyStateView(
          icon: Icons.account_balance_rounded,
          title: 'No Fixed Income Added',
          description:
              'PPF, NSC, KVP, SSS, POSS, FD, FRD and RD for $profileName will appear here.',
        );
      case 'gold':
        return const EmptyStateView(
          icon: Icons.circle_rounded,
          title: 'No Gold Holdings Added',
          description:
              'Digital gold, Sovereign Gold Bonds (SGB), and gold ETFs will be tracked here.',
        );
      case 'mutual_fund':
        return EmptyStateView(
          icon: Icons.pie_chart_outline_rounded,
          title: 'No Mutual Funds in $profileName’s Portfolio',
          description:
              'Search 40,000+ AMFI mutual fund schemes or set up a flexible SIP to track wealth safely on-device.',
          actionLabel: 'Search Mutual Funds',
          onAction: () => _openSearchScreen(context),
        );
      default:
        final label = categoryLabel(category);
        return EmptyStateView(
          icon: Icons.inventory_2_outlined,
          title: 'No $label Added',
          description:
              '$label for $profileName will be tracked here. Support for this category is planned for upcoming milestones.',
        );
    }
  }

  String _categoryDisplayName(String category) =>
      category == 'all' ? 'All Investments' : categoryLabel(category);

  void _openSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MutualFundSearchScreen(),
      ),
    );
  }

  void _openHoldingDetails(BuildContext context, FinancialItem item) {
    // Navigate to dedicated full-screen SIP Details page
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SipDetailsScreen(holding: item),
      ),
    );
  }

  void _openAddSipDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AddSipDialog(),
    );
  }

  void _confirmDeleteHolding(BuildContext context, FinancialItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Holding?'),
        content: Text(
          'Are you sure you want to remove "${item.name}" from this profile’s portfolio? This will remove all associated transactions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final itemsDao = ref.read(financialItemsDaoProvider);
              await itemsDao.deleteHoldingCascade(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Removed "${item.name}" and associated records.'),
                  ),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
