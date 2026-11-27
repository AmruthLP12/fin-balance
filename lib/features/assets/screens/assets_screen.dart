import '../../../core/providers/daily_pnl.dart';
import '../../personal_debt/personal_debt_card.dart';
import '../../personal_debt/personal_debt_form.dart';
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
import '../widgets/holding_card.dart';
import 'mutual_fund_search_screen.dart';
import 'sip_details_screen.dart';
import 'deposit_details_screen.dart';
import '../../savings/savings_details_screen.dart';
import '../deposit_add_actions.dart';

/// Assets screen for managing Mutual Funds, Stocks, FDs, Gold, and wealth holdings scoped to the active profile.
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  // Category navigation filter: defaults to 'mutual_fund' as in reference
  String _selectedCategoryFilter = 'mutual_fund';
  String _subFilter = 'all'; // sub-category chip inside Deposits
  String _query = ''; // mutual fund name filter
  final _queryCtl = TextEditingController();
  String _sortBy = 'name';
  bool _ascending = true;
  bool _showRedeemed = false;

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

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
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);
    final sips =
        ref.watch(activeProfileSipPlansProvider).value ?? const <SipPlan>[];

    final profileName = activeProfileAsync.value?.name ?? 'Profile';
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
          int countOf(String v) => items
              .where((i) => groupOf(i.subType, assetGroups).value == v)
              .length;

          final filteredItems =
              _filterItems(items, _selectedCategoryFilter, sips);

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
          final isMoneyLentCategory = _selectedCategoryFilter == 'money_lent';
          final interestRecordedPaise = matchingTransactions
              .where((tx) =>
                  tx.transactionType == 'interest_received' ||
                  tx.transactionType == 'interest_paid')
              .fold<int>(0, (sum, tx) => sum + tx.amountPaise);

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
                      // The "All Assets" tab is hidden for now (still handled by _filterItems).
                      for (final g in assetGroups) ...[
                        _buildCategoryPill(
                          label: g.label,
                          categoryValue: g.value,
                          count: countOf(g.value),
                          isDark: isDark,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
                if (_subCategories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (value, label) in [
                          ('all', 'All'),
                          ..._subCategories,
                        ]) ...[
                          ChoiceChip(
                            label: Text(label),
                            selected: _subFilter == value,
                            onSelected: (_) => _setSub(value),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                      ],
                    ),
                  ),
                ],
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
                            label: isMoneyLentCategory
                                ? '${filteredItems.length} ${filteredItems.length == 1 ? 'Person' : 'People'}'
                                : '${filteredItems.length} ${filteredItems.length == 1 ? 'Holding' : 'Holdings'}',
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
                                isMoneyLentCategory
                                    ? 'INTEREST RECORDED'
                                    : 'OVERALL P&L',
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
                                isMoneyLentCategory
                                    ? CurrencyFormatter.formatPaise(
                                        interestRecordedPaise)
                                    : '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(totalPnlPaise)} (${totalPnlPercent >= 0 ? '+' : ''}${totalPnlPercent.toStringAsFixed(1)}%)',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isMoneyLentCategory
                                      ? AppColors.asset
                                      : (isProfit
                                          ? AppColors.asset
                                          : AppColors.liability),
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
                                isMoneyLentCategory
                                    ? 'Lent in total: '
                                    : 'Invested: ',
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
                                isMoneyLentCategory
                                    ? 'Outstanding: '
                                    : 'Overall IRR: ',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              Text(
                                isMoneyLentCategory
                                    ? CurrencyFormatter.formatPaise(
                                        totalCurrentPaise)
                                    : (overallXirr != null
                                        ? '${overallXirr.toStringAsFixed(1)}%'
                                        : '—'),
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
                  actionLabel: _selectedCategoryFilter == 'money_lent' ||
                          _selectedCategoryFilter == 'other_asset'
                      ? (_selectedCategoryFilter == 'money_lent'
                          ? '+ Lend Money'
                          : '+ Add Asset')
                      : _selectedCategoryFilter == 'other_deposit'
                          ? (_depositAdd == null
                              ? null
                              : '+ ${_depositAdd!.label}')
                          : _selectedCategoryFilter == 'mutual_fund' ||
                                  _selectedCategoryFilter == 'all'
                              ? 'Search Schemes'
                              : null,
                  onActionTap: () => _selectedCategoryFilter == 'money_lent' ||
                          _selectedCategoryFilter == 'other_asset'
                      ? PersonalDebtForm.show(context, lent: true)
                      : _selectedCategoryFilter == 'other_deposit'
                          ? _depositAdd?.open(context)
                          : _openSearchScreen(context),
                ),
                const SizedBox(height: AppSpacing.sm),

                if (filteredItems.isEmpty)
                  _buildCategoryEmptyState(
                    category: _selectedCategoryFilter,
                    profileName: profileName,
                  )
                else if (_selectedCategoryFilter == 'mutual_fund')
                  ..._mutualFundSections(filteredItems, sips, isDark)
                else
                  ...filteredItems.map(_holdingTile),
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

  List<(String, String)> get _subCategories {
    for (final g in assetGroups) {
      if (g.value == _selectedCategoryFilter) return g.children;
    }
    return const [];
  }

  Widget _holdingTile(FinancialItem item) {
    if (item.subType == 'money_lent') return PersonalDebtCard(item: item);
    return HoldingCard(
      item: item,
      onTap: () {
        if (item.subType == 'other_asset') {
          PersonalDebtForm.show(context, lent: true, item: item);
        } else if (item.subType == 'ppf' || item.subType == 'sss') {
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => SavingsDetailsScreen(itemId: item.id)));
        } else if (item.subType == 'fixed_deposit' ||
            item.subType == 'recurring_deposit') {
          Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => DepositDetailsScreen(holding: item)));
        } else {
          _openHoldingDetails(context, item);
        }
      },
      onDelete: () => _confirmDeleteHolding(context, item),
    );
  }

  static const _sortLabels = {
    'name': 'Name',
    'cost': 'Cost',
    'value': 'Value',
    'day': '1 Day P&L %',
    'return': 'Return %',
  };

  Future<void> _pickSort() async {
    var by = _sortBy, asc = _ascending;
    await showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setD) => SimpleDialog(
          title: const Text('Sort mutual funds'),
          children: [
            RadioGroup<String>(
              groupValue: by,
              onChanged: (v) => setD(() => by = v ?? by),
              child: Column(children: [
                for (final e in _sortLabels.entries)
                  RadioListTile<String>(title: Text(e.value), value: e.key),
              ]),
            ),
            const Divider(),
            RadioGroup<bool>(
              groupValue: asc,
              onChanged: (v) => setD(() => asc = v ?? asc),
              child: const Column(children: [
                RadioListTile<bool>(title: Text('Ascending'), value: true),
                RadioListTile<bool>(title: Text('Descending'), value: false),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FilledButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Apply')),
            ),
          ],
        ),
      ),
    );
    setState(() {
      _sortBy = by;
      _ascending = asc;
    });
  }

  /// Mutual funds: name filter + sort, active holdings first, redeemed
  /// (zero-unit) funds in their own section behind a button.
  List<Widget> _mutualFundSections(
      List<FinancialItem> all, List<SipPlan> sips, bool isDark) {
    final daily = ref.watch(dailyChangeByItemProvider).value ?? const {};
    final q = _query.trim().toLowerCase();
    final shown =
        all.where((i) => q.isEmpty || i.name.toLowerCase().contains(q));
    final now = DateTime.now();
    bool planned(FinancialItem i) =>
        i.currentValuationPaise == 0 &&
        sips.any((s) => s.financialItemId == i.id && s.startDate.isAfter(now));

    num key(FinancialItem i) {
      switch (_sortBy) {
        case 'cost':
          return i.initialValuePaise;
        case 'value':
          return i.currentValuationPaise;
        case 'day':
          return daily[i.id]?.pct ?? double.negativeInfinity;
        case 'return':
          return FinancialCalculator.calculateAbsoluteReturn(
              investedPaise: i.initialValuePaise,
              currentValuationPaise: i.currentValuationPaise);
      }
      return 0;
    }

    int cmp(FinancialItem a, FinancialItem b) {
      final c = _sortBy == 'name'
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : key(a).compareTo(key(b));
      return _ascending ? c : -c;
    }

    final live = shown.where((i) => i.currentValuationPaise > 0).toList()
      ..sort(cmp);
    final plannedItems = shown.where(planned).toList()..sort(cmp);
    final redeemed = shown
        .where((i) => i.currentValuationPaise == 0 && !planned(i))
        .toList()
      ..sort(cmp);
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    Widget header(String title, List<FinancialItem> l) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text('$title (${l.length})',
                    style: AppTypography.titleMedium),
              ),
              Text(
                'Cost ${CurrencyFormatter.formatPaiseCompact(l.fold<int>(0, (s, i) => s + i.initialValuePaise))}'
                ' · Value ${CurrencyFormatter.formatPaiseCompact(l.fold<int>(0, (s, i) => s + i.currentValuationPaise))}',
                style: AppTypography.labelSmall.copyWith(color: muted),
              ),
            ],
          ),
        );

    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filter funds by name',
                prefixIcon: const Icon(Icons.filter_list_rounded, size: 20),
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () {
                          _queryCtl.clear();
                          setState(() => _query = '');
                        }),
              ),
              controller: _queryCtl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
            ),
          ),
          IconButton(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded),
            onPressed: _pickSort,
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.only(top: 2, bottom: AppSpacing.sm),
        child: Text(
            'Sorted by ${_sortLabels[_sortBy]} (${_ascending ? 'ascending' : 'descending'})',
            style: AppTypography.labelSmall.copyWith(color: muted)),
      ),
      if (live.isEmpty && plannedItems.isEmpty && redeemed.isEmpty)
        const Padding(
          padding: EdgeInsets.all(AppSpacing.md),
          child: Center(child: Text('No funds match the filter.')),
        ),
      if (live.isNotEmpty || plannedItems.isNotEmpty) ...[
        header('Active', [...live, ...plannedItems]),
        ...live.map(_holdingTile),
        ...plannedItems.map(_holdingTile),
      ],
      if (redeemed.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: Icon(_showRedeemed
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded),
          label: Text(
              '${_showRedeemed ? 'Hide' : 'Show'} redeemed (${redeemed.length}) · Cost ${CurrencyFormatter.formatPaiseCompact(redeemed.fold<int>(0, (s, i) => s + i.initialValuePaise))}'),
          onPressed: () => setState(() => _showRedeemed = !_showRedeemed),
        ),
        if (_showRedeemed) ...[
          const SizedBox(height: AppSpacing.sm),
          header('Redeemed', redeemed),
          ...redeemed.map(_holdingTile),
        ],
      ],
    ];
  }

  void _setSub(String v) {
    ref.read(assetsSubCategoryProvider.notifier).state = v;
    setState(() => _subFilter = v);
  }

  /// Deposits offer "add" only inside a chip that has a form (FD, RD, PPF, SSS).
  ({String label, void Function(BuildContext) open})? get _depositAdd =>
      _selectedCategoryFilter == 'other_deposit'
          ? depositAddFor(_subFilter)
          : null;

  static final _tabOrder = [for (final g in assetGroups) g.value];
  final _pillKeys = {for (final v in _tabOrder) v: GlobalKey()};

  void _select(String category) {
    ref.read(assetsActiveCategoryProvider.notifier).state = category;
    ref.read(assetsSubCategoryProvider.notifier).state = 'all';
    setState(() {
      _selectedCategoryFilter = category;
      _subFilter = 'all';
    });
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

  List<FinancialItem> _filterItems(
      List<FinancialItem> items, String filter, List<SipPlan> sips) {
    final filtered = filter == 'all'
        ? items
        : items
            .where((i) => groupOf(i.subType, assetGroups).value == filter)
            .where((i) => _subFilter == 'all' || i.subType == _subFilter)
            .toList();
    if (filter == 'other_deposit') {
      // Nearest maturity first, then deposits without a date, then matured ones
      // (most recently matured first).
      final today = DateTime.now();
      final start = DateTime(today.year, today.month, today.day);
      int bucket(FinancialItem i) => i.maturityDate == null
          ? 1
          : (i.maturityDate!.isBefore(start) ? 2 : 0);
      filtered.sort((a, b) {
        final c = bucket(a).compareTo(bucket(b));
        if (c != 0) return c;
        if (bucket(a) == 0) return a.maturityDate!.compareTo(b.maturityDate!);
        if (bucket(a) == 2) return b.maturityDate!.compareTo(a.maturityDate!);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return filtered;
    }
    filtered.sort((a, b) {
      final futureA = sips.any((s) =>
          s.financialItemId == a.id &&
          s.startDate.isAfter(DateTime.now()) &&
          a.currentValuationPaise == 0);
      final futureB = sips.any((s) =>
          s.financialItemId == b.id &&
          s.startDate.isAfter(DateTime.now()) &&
          b.currentValuationPaise == 0);
      if (futureA != futureB) return futureA ? 1 : -1;
      final activeA = a.status == 'active' && a.currentValuationPaise > 0;
      final activeB = b.status == 'active' && b.currentValuationPaise > 0;
      if (activeA != activeB) return activeA ? -1 : 1;
      if (a.currentValuationPaise != b.currentValuationPaise) {
        return b.currentValuationPaise.compareTo(a.currentValuationPaise);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return filtered;
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
      case 'other_deposit':
        if (!depositChipsBuilt.contains(_subFilter)) {
          return EmptyStateView(
            icon: Icons.hourglass_top_rounded,
            title: 'Coming soon',
            description:
                '${categoryLabel(_subFilter)} tracking is not available yet.',
          );
        }
        final add = _depositAdd;
        return EmptyStateView(
          icon: Icons.account_balance_rounded,
          title: add == null
              ? 'No Deposits Added'
              : 'No ${categoryLabel(_subFilter)} Added',
          description: add == null
              ? 'FD, RD, PPF and SSS for $profileName will appear here.'
              : 'Tap + ${add.label} to add one for $profileName.',
        );
      case 'money_lent':
        return const EmptyStateView(
          icon: Icons.handshake_outlined,
          title: 'No Money Lent',
          description:
              'Money you lent to a friend or relative, with or without interest, is tracked here.',
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
