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
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../profile/widgets/profile_avatar.dart';

/// Unified Activity Ledger and Cash Flow Analysis Screen.
///
/// Features:
/// - Tab 1: Activity Ledger with real Drift transactions, multi-dimension filters
///   (type, category, date range), summary metrics, and detail/delete capabilities.
/// - Tab 2: Cash Flow analysis with flexible period selection, income/expense breakdown,
///   savings rate calculation, top expense highlighting, and quick entry shortcuts.
/// - Scoped to the active financial profile.
/// - Excludes internal transfers from income and expense calculations.
class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Ledger Filter State
  String _selectedType = 'all'; // all, income, expense, investment, transfer
  String _selectedLedgerPeriod =
      'all'; // all, today, this_month, last_month, custom
  DateTimeRange? _ledgerCustomRange;
  int? _selectedCategoryId;

  // Cash Flow Filter State
  String _cashFlowPeriod =
      'this_month'; // this_month, last_month, 3_months, 6_months, this_year, custom
  DateTimeRange? _cashFlowCustomRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
                child: ProfileAvatar.active(radius: 16),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor:
              isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
          unselectedLabelColor:
              isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          indicatorColor:
              isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
          tabs: const [
            Tab(text: 'Ledger'),
            Tab(text: 'Cash Flow'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLedgerTab(context, isDark),
          _buildCashFlowTab(context, isDark),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: ACTIVITY LEDGER
  // ==========================================

  Widget _buildLedgerTab(BuildContext context, bool isDark) {
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return transactionsAsync.when(
      data: (allTxns) {
        final categoriesMap = <int, FinancialCategory>{
          for (final c in categoriesAsync.value ?? <FinancialCategory>[])
            c.id: c,
        };

        // Apply filters
        final filteredTxns = allTxns.where((txn) {
          // Type filter
          if (_selectedType != 'all') {
            if (_selectedType == 'income' && txn.transactionType != 'income') {
              return false;
            }
            if (_selectedType == 'expense' &&
                txn.transactionType != 'expense') {
              return false;
            }
            if (_selectedType == 'investment' &&
                !txn.transactionType.contains('investment')) {
              return false;
            }
            if (_selectedType == 'transfer' &&
                txn.transactionType != 'transfer') {
              return false;
            }
          }

          // Category filter
          if (_selectedCategoryId != null &&
              txn.categoryId != _selectedCategoryId) {
            return false;
          }

          // Date filter
          final date = txn.transactionDate;
          final now = DateTime.now();
          if (_selectedLedgerPeriod == 'today') {
            if (date.year != now.year ||
                date.month != now.month ||
                date.day != now.day) {
              return false;
            }
          } else if (_selectedLedgerPeriod == 'this_month') {
            if (date.year != now.year || date.month != now.month) {
              return false;
            }
          } else if (_selectedLedgerPeriod == 'last_month') {
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            if (date.year != lastMonth.year || date.month != lastMonth.month) {
              return false;
            }
          } else if (_selectedLedgerPeriod == 'custom' &&
              _ledgerCustomRange != null) {
            if (date.isBefore(_ledgerCustomRange!.start) ||
                date.isAfter(
                    _ledgerCustomRange!.end.add(const Duration(days: 1)))) {
              return false;
            }
          }

          return true;
        }).toList();

        // Calculate summary metrics on filtered list (or all profile transactions)
        int totalIncomePaise = 0;
        int totalExpensePaise = 0;
        int totalInvestmentPaise = 0;

        for (final txn in filteredTxns) {
          if (txn.transactionType == 'income') {
            totalIncomePaise += txn.amountPaise;
          } else if (txn.transactionType == 'expense') {
            totalExpensePaise += txn.amountPaise;
          } else if (txn.transactionType.contains('investment')) {
            totalInvestmentPaise += txn.amountPaise;
          }
        }
        final netMovementPaise =
            totalIncomePaise - totalExpensePaise - totalInvestmentPaise;

        final hasActiveFilters = _selectedType != 'all' ||
            _selectedLedgerPeriod != 'all' ||
            _selectedCategoryId != null;

        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Ledger Summary Card
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
                        'SUMMARY METRICS',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${filteredTxns.length} records',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Income',
                          CurrencyFormatter.formatPaise(totalIncomePaise),
                          AppColors.asset,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildMetricTile(
                          'Expenses',
                          CurrencyFormatter.formatPaise(totalExpensePaise),
                          AppColors.liability,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          'Investments',
                          CurrencyFormatter.formatPaise(totalInvestmentPaise),
                          AppColors.brandPrimaryLight,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _buildMetricTile(
                          'Net Movement',
                          (netMovementPaise >= 0 ? '+' : '') +
                              CurrencyFormatter.formatPaise(netMovementPaise),
                          netMovementPaise >= 0
                              ? AppColors.asset
                              : AppColors.liability,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTypeChip('All', 'all', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildTypeChip('Income', 'income', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildTypeChip('Expenses', 'expense', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildTypeChip('Investments', 'investment', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildTypeChip('Transfers', 'transfer', isDark),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Date & Category Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildDateFilterChip(isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildCategoryFilterChip(categoriesAsync.value ?? [], isDark),
                  if (hasActiveFilters) ...[
                    const SizedBox(width: AppSpacing.xs),
                    ActionChip(
                      avatar: const Icon(Icons.close_rounded, size: 16),
                      label: const Text('Reset'),
                      onPressed: () {
                        setState(() {
                          _selectedType = 'all';
                          _selectedLedgerPeriod = 'all';
                          _ledgerCustomRange = null;
                          _selectedCategoryId = null;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Transactions List
            if (filteredTxns.isEmpty)
              EmptyStateView(
                icon: Icons.receipt_long_rounded,
                title: 'No Transactions',
                description: hasActiveFilters
                    ? 'No transactions match the selected filters. Try resetting the filters.'
                    : 'No activity recorded yet for this profile. Use the + button to add income, expenses, or transfers.',
              )
            else
              ...filteredTxns.map((txn) {
                final category = categoriesMap[txn.categoryId];
                return _buildTransactionCard(context, txn, category, isDark);
              }),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error loading activity: $err'),
        ),
      ),
    );
  }

  Widget _buildMetricTile(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.titleMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value, bool isDark) {
    final isSelected = _selectedType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedType = value);
      },
    );
  }

  Widget _buildDateFilterChip(bool isDark) {
    String label = 'All Dates';
    if (_selectedLedgerPeriod == 'today') label = 'Today';
    if (_selectedLedgerPeriod == 'this_month') label = 'This Month';
    if (_selectedLedgerPeriod == 'last_month') label = 'Last Month';
    if (_selectedLedgerPeriod == 'custom' && _ledgerCustomRange != null) {
      label =
          '${DateFormatter.formatDate(_ledgerCustomRange!.start)} - ${DateFormatter.formatDate(_ledgerCustomRange!.end)}';
    }

    return PopupMenuButton<String>(
      initialValue: _selectedLedgerPeriod,
      onSelected: (val) async {
        if (val == 'custom') {
          final now = DateTime.now();
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime(now.year + 2),
            initialDateRange: _ledgerCustomRange ??
                DateTimeRange(
                  start: DateTime(now.year, now.month, 1),
                  end: now,
                ),
          );
          if (picked != null) {
            setState(() {
              _selectedLedgerPeriod = 'custom';
              _ledgerCustomRange = picked;
            });
          }
        } else {
          setState(() {
            _selectedLedgerPeriod = val;
            _ledgerCustomRange = null;
          });
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'all', child: Text('All Dates')),
        PopupMenuItem(value: 'today', child: Text('Today')),
        PopupMenuItem(value: 'this_month', child: Text('This Month')),
        PopupMenuItem(value: 'last_month', child: Text('Last Month')),
        PopupMenuItem(value: 'custom', child: Text('Custom Range...')),
      ],
      child: Chip(
        avatar: const Icon(Icons.calendar_today_rounded, size: 14),
        label: Text(label),
      ),
    );
  }

  Widget _buildCategoryFilterChip(
      List<FinancialCategory> categories, bool isDark) {
    String label = 'All Categories';
    if (_selectedCategoryId != null) {
      final match = categories.where((c) => c.id == _selectedCategoryId);
      if (match.isNotEmpty) label = match.first.name;
    }

    return PopupMenuButton<int?>(
      initialValue: _selectedCategoryId,
      onSelected: (val) {
        setState(() => _selectedCategoryId = val);
      },
      itemBuilder: (context) => [
        const PopupMenuItem<int?>(
          value: null,
          child: Text('All Categories'),
        ),
        const PopupMenuDivider(),
        ...categories.map(
          (c) => PopupMenuItem<int?>(
            value: c.id,
            child: Text(c.name),
          ),
        ),
      ],
      child: Chip(
        avatar: const Icon(Icons.category_rounded, size: 14),
        label: Text(label),
      ),
    );
  }

  Widget _buildTransactionCard(
    BuildContext context,
    Transaction txn,
    FinancialCategory? category,
    bool isDark,
  ) {
    final isIncome = txn.transactionType == 'income';
    final isExpense = txn.transactionType == 'expense';
    final isInvestment = txn.transactionType.contains('investment');

    Color color;
    IconData icon;
    String prefix;

    if (isIncome) {
      color = AppColors.asset;
      icon = Icons.arrow_downward_rounded;
      prefix = '+';
    } else if (isExpense) {
      color = AppColors.liability;
      icon = Icons.arrow_upward_rounded;
      prefix = '-';
    } else if (isInvestment) {
      color = AppColors.brandPrimaryLight;
      icon = Icons.trending_up_rounded;
      prefix = '';
    } else {
      color = Colors.blueGrey;
      icon = Icons.swap_horiz_rounded;
      prefix = '';
    }

    final categoryName = category?.name ??
        txn.transactionType.replaceAll('_', ' ').toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: () =>
            _showTransactionDetails(context, txn, categoryName, isDark),
        child: FinCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          DateFormatter.formatDate(txn.transactionDate),
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                        if (txn.notes != null && txn.notes!.isNotEmpty) ...[
                          Text(
                            ' • ',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              txn.notes!,
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$prefix${CurrencyFormatter.formatPaise(txn.amountPaise)}',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    Transaction txn,
    String categoryName,
    bool isDark,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transaction Details',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    StatusBadge(
                      label: txn.transactionType
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      type: txn.transactionType == 'income'
                          ? BadgeType.asset
                          : (txn.transactionType == 'expense'
                              ? BadgeType.liability
                              : BadgeType.neutral),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _buildDetailRow('Amount',
                    CurrencyFormatter.formatPaise(txn.amountPaise), isDark),
                _buildDetailRow('Category', categoryName, isDark),
                _buildDetailRow('Date',
                    DateFormatter.formatDate(txn.transactionDate), isDark),
                _buildDetailRow('Source', txn.source.toUpperCase(), isDark),
                if (txn.notes != null && txn.notes!.isNotEmpty)
                  _buildDetailRow('Notes', txn.notes!, isDark),
                const SizedBox(height: AppSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.liability),
                    label: const Text(
                      'Delete Transaction',
                      style: TextStyle(color: AppColors.liability),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.liability),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.of(bottomSheetContext).pop();
                      _confirmDeleteTransaction(context, txn);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteTransaction(BuildContext context, Transaction txn) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Transaction?'),
          content: Text(
            'Are you sure you want to delete this recorded transaction of ${CurrencyFormatter.formatPaise(txn.amountPaise)}? This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.liability,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref
                      .read(transactionsDaoProvider)
                      .deleteTransaction(txn.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Transaction deleted.'),
                        backgroundColor: AppColors.liability,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to delete: $e')),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ==========================================
  // TAB 2: CASH FLOW ANALYSIS
  // ==========================================

  Widget _buildCashFlowTab(BuildContext context, bool isDark) {
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);

    return transactionsAsync.when(
      data: (allTxns) {
        final categoriesMap = <int, FinancialCategory>{
          for (final c in categoriesAsync.value ?? <FinancialCategory>[])
            c.id: c,
        };

        // Filter transactions for Cash Flow according to selected period
        // TRANSFERS ARE EXPLICITLY EXCLUDED FROM INCOME AND EXPENSE CASH FLOW
        final cashFlowTxns = allTxns.where((txn) {
          // Strictly exclude transfers
          if (txn.transactionType == 'transfer') return false;

          final date = txn.transactionDate;
          final now = DateTime.now();

          if (_cashFlowPeriod == 'this_month') {
            return date.year == now.year && date.month == now.month;
          } else if (_cashFlowPeriod == 'last_month') {
            final lastMonth = DateTime(now.year, now.month - 1, 1);
            return date.year == lastMonth.year && date.month == lastMonth.month;
          } else if (_cashFlowPeriod == '3_months') {
            final start = DateTime(now.year, now.month - 3, now.day);
            return date.isAfter(start) &&
                date.isBefore(now.add(const Duration(days: 1)));
          } else if (_cashFlowPeriod == '6_months') {
            final start = DateTime(now.year, now.month - 6, now.day);
            return date.isAfter(start) &&
                date.isBefore(now.add(const Duration(days: 1)));
          } else if (_cashFlowPeriod == 'this_year') {
            return date.year == now.year;
          } else if (_cashFlowPeriod == 'custom' &&
              _cashFlowCustomRange != null) {
            return (date.isAfter(_cashFlowCustomRange!.start) ||
                    date.isAtSameMomentAs(_cashFlowCustomRange!.start)) &&
                date.isBefore(
                    _cashFlowCustomRange!.end.add(const Duration(days: 1)));
          }
          return true;
        }).toList();

        // Calculate Cash Flow metrics
        int incomePaise = 0;
        int expensePaise = 0;
        int investmentOutflowPaise = 0;
        final incomeByCategory = <int, int>{};
        final expenseByCategory = <int, int>{};
        final investmentByCategory = <int, int>{};

        for (final txn in cashFlowTxns) {
          if (txn.transactionType == 'income') {
            incomePaise += txn.amountPaise;
            incomeByCategory[txn.categoryId] =
                (incomeByCategory[txn.categoryId] ?? 0) + txn.amountPaise;
          } else if (txn.transactionType == 'expense') {
            expensePaise += txn.amountPaise;
            expenseByCategory[txn.categoryId] =
                (expenseByCategory[txn.categoryId] ?? 0) + txn.amountPaise;
          } else if (txn.transactionType == 'investment_purchase') {
            investmentOutflowPaise += txn.amountPaise;
            investmentByCategory[txn.categoryId] =
                (investmentByCategory[txn.categoryId] ?? 0) + txn.amountPaise;
          }
        }

        final totalOutflowPaise = expensePaise + investmentOutflowPaise;
        final netCashFlowPaise = incomePaise - totalOutflowPaise;
        final savingsRate = incomePaise > 0
            ? (((incomePaise - expensePaise) / incomePaise) * 100)
                .clamp(-100.0, 100.0)
            : 0.0;

        return ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Period Selector
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('This Month', 'this_month', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPeriodChip('Last Month', 'last_month', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPeriodChip('3 Months', '3_months', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPeriodChip('6 Months', '6_months', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  _buildPeriodChip('This Year', 'this_year', isDark),
                  const SizedBox(width: AppSpacing.xs),
                  ActionChip(
                    avatar: const Icon(Icons.date_range_rounded, size: 14),
                    label: Text(_cashFlowPeriod == 'custom' &&
                            _cashFlowCustomRange != null
                        ? '${DateFormatter.formatDate(_cashFlowCustomRange!.start)} - ${DateFormatter.formatDate(_cashFlowCustomRange!.end)}'
                        : 'Custom'),
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(now.year + 2),
                        initialDateRange: _cashFlowCustomRange ??
                            DateTimeRange(
                              start: DateTime(now.year, now.month, 1),
                              end: now,
                            ),
                      );
                      if (picked != null) {
                        setState(() {
                          _cashFlowPeriod = 'custom';
                          _cashFlowCustomRange = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Cash Flow Summary Card
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
                        'NET CASH MOVEMENT',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
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
                    style: AppTypography.heroAmount.copyWith(
                      color: netCashFlowPaise >= 0
                          ? AppColors.asset
                          : AppColors.liability,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Inflow',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatPaise(incomePaise),
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
                              'Total Outflow',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatPaise(totalOutflowPaise),
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.liability,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Divider(),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expenses',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatPaise(expensePaise),
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
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Investments (SIPs)',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              CurrencyFormatter.formatPaise(
                                  investmentOutflowPaise),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.brandPrimaryLight,
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

            // Investment Outflow Section (SIPs and Mutual Fund purchases)
            _buildBreakdownSection(
              title: 'Investment Outflows (SIPs & Purchases)',
              emptyMessage:
                  'No investment purchases or SIP installments recorded in this period.',
              byCategory: investmentByCategory,
              categoriesMap: categoriesMap,
              totalPaise: investmentOutflowPaise,
              indicatorColor: AppColors.brandPrimaryLight,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Expense Breakdown Section (Sorted descending by amount)
            _buildBreakdownSection(
              title: 'Expense Breakdown',
              emptyMessage: 'No expenses recorded in this period.',
              byCategory: expenseByCategory,
              categoriesMap: categoriesMap,
              totalPaise: expensePaise,
              indicatorColor: AppColors.liability,
              isDark: isDark,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Income Breakdown Section
            _buildBreakdownSection(
              title: 'Income Sources',
              emptyMessage: 'No income recorded in this period.',
              byCategory: incomeByCategory,
              categoriesMap: categoriesMap,
              totalPaise: incomePaise,
              indicatorColor: AppColors.asset,
              isDark: isDark,
            ),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text('Error loading cash flow: $err'),
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value, bool isDark) {
    final isSelected = _cashFlowPeriod == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _cashFlowPeriod = value);
      },
    );
  }

  Widget _buildBreakdownSection({
    required String title,
    required String emptyMessage,
    required Map<int, int> byCategory,
    required Map<int, FinancialCategory> categoriesMap,
    required int totalPaise,
    required Color indicatorColor,
    required bool isDark,
  }) {
    if (byCategory.isEmpty) {
      return FinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              emptyMessage,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    // Sort descending by amount
    final sortedEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                CurrencyFormatter.formatPaise(totalPaise),
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: indicatorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...sortedEntries.map((entry) {
            final category = categoriesMap[entry.key];
            final name = category?.name ?? 'General';
            final amount = entry.value;
            final percentage = totalPaise > 0 ? (amount / totalPaise) : 0.0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${(percentage * 100).toStringAsFixed(1)}% • ${CurrencyFormatter.formatPaise(amount)}',
                        style: AppTypography.labelSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: AppSpacing.borderRadiusPill,
                    child: LinearProgressIndicator(
                      value: percentage.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
