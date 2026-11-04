import 'package:drift/drift.dart' as drift;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculations/financial_calculator.dart';
import '../../../core/calculations/investment_lifecycle_summary.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import '../widgets/investment_lifecycle_card.dart';
import 'add_investment_transaction_screen.dart';
import 'add_sip_schedule_period_screen.dart';
import 'add_swp_schedule_period_screen.dart';
import 'edit_holding_screen.dart';
import 'edit_sip_schedule_screen.dart';

/// Full-screen dedicated details page for a mutual fund holding, SIP schedules, and transaction history.
/// Organized into three clearly separated tabs:
/// 1. Overview (Financial summary, investment information, schedule periods, auto-generated lifecycle summary, editable user remarks)
/// 2. Transactions (Authoritative history, 9 supported types, charges, net cash flow, inflow/outflow, and type filtering)
/// 3. Performance History (Historical valuation chart with 1M/3M/6M/1Y/ALL range selector and touch inspection)
class SipDetailsScreen extends ConsumerStatefulWidget {
  final FinancialItem? holding;
  final SipPlan? sip;

  const SipDetailsScreen({
    super.key,
    this.holding,
    this.sip,
  }) : assert(holding != null || sip != null,
            'Either holding or sip must be provided');

  @override
  ConsumerState<SipDetailsScreen> createState() => _SipDetailsScreenState();
}

class _SipDetailsScreenState extends ConsumerState<SipDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedTimeRange = '1M'; // '1M', '3M', '6M', '1Y', 'ALL'
  String _selectedTxFilter =
      'ALL'; // 'ALL', 'PURCHASES', 'SIP', 'DIVIDENDS', 'REDEMPTIONS', 'SWP', 'SWITCHES'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int? get _schemeCode {
    if (widget.sip != null) return widget.sip!.schemeCode;
    if (widget.holding?.externalCode != null) {
      return int.tryParse(widget.holding!.externalCode!);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Resolve active profile
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final profileId = activeProfileAsync.value?.id ?? 0;
    final profileName = activeProfileAsync.value?.name ?? 'Profile';

    // 2. Watch live holdings and live SIPs
    final allHoldingsAsync = ref.watch(activeProfileAssetsProvider);
    final allSipsAsync = ref.watch(activeProfileSipPlansProvider);

    final holdings = allHoldingsAsync.value ?? [];
    final sips = allSipsAsync.value ?? [];

    // Find current holding record (live from db)
    FinancialItem? currentHolding;
    if (widget.holding != null) {
      currentHolding = holdings.firstWhere(
        (h) => h.id == widget.holding!.id,
        orElse: () => widget.holding!,
      );
    } else if (widget.sip != null) {
      currentHolding = widget.sip!.financialItemId != null
          ? holdings.firstWhere(
              (h) => h.id == widget.sip!.financialItemId,
              orElse: () => holdings.firstWhere(
                (h) => h.externalCode == widget.sip!.schemeCode.toString(),
                orElse: () => _emptyPlaceholderHolding(widget.sip!, profileId),
              ),
            )
          : holdings
              .where((h) => h.externalCode == widget.sip!.schemeCode.toString())
              .firstOrNull;
    }

    // Find linked SIP plan (if any)
    SipPlan? linkedSip;
    if (widget.sip != null) {
      linkedSip = sips.firstWhere(
        (s) => s.id == widget.sip!.id,
        orElse: () => widget.sip!,
      );
    } else if (currentHolding != null) {
      linkedSip = sips.where((s) {
        if (s.financialItemId == currentHolding!.id) return true;
        if (_schemeCode != null && s.schemeCode == _schemeCode) return true;
        return false;
      }).firstOrNull;
    }

    // Scheme master data from database
    final schemeAsync = _schemeCode != null
        ? ref.watch(schemeByCodeProvider(_schemeCode!))
        : null;
    final scheme = schemeAsync?.value;

    // Watch transactions for this item
    final txListAsync = currentHolding != null
        ? ref.watch(transactionsByItemProvider(
            (profileId: profileId, itemId: currentHolding.id)))
        : null;
    final transactions = txListAsync?.value ?? [];

    // Watch SIP schedule periods if linked SIP exists
    final periodsAsync =
        linkedSip != null ? ref.watch(sipPeriodsProvider(linkedSip.id)) : null;
    final schedulePeriods = periodsAsync?.value ?? [];

    // Watch SIP installments
    final installmentsAsync = linkedSip != null
        ? ref.watch(sipInstallmentsProvider(linkedSip.id))
        : null;
    final installments = installmentsAsync?.value ?? [];

    // Watch SWP plans if holding exists
    final swpsAsync = currentHolding != null
        ? ref.watch(swpsByHoldingProvider(currentHolding.id))
        : null;
    final swps = swpsAsync?.value ?? [];
    final linkedSwp = swps.firstOrNull;

    // Watch SWP schedule periods
    final swpPeriodsAsync =
        linkedSwp != null ? ref.watch(swpPeriodsProvider(linkedSwp.id)) : null;
    final swpSchedulePeriods = swpPeriodsAsync?.value ?? [];

    // Watch SWP installments
    final swpInstallmentsAsync = linkedSwp != null
        ? ref.watch(swpInstallmentsProvider(linkedSwp.id))
        : null;
    final swpInstallments = swpInstallmentsAsync?.value ?? [];

    // Watch favourites
    final isFav = _schemeCode != null
        ? (ref.watch(isSchemeFavoriteProvider(_schemeCode!)).value ?? false)
        : false;

    final schemeName = currentHolding?.name ??
        linkedSip?.name ??
        scheme?.schemeName ??
        'Mutual Fund Investment';
    final fundHouse = scheme?.fundHouse ?? 'Direct Mutual Fund';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              schemeName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              fundHouse,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (_schemeCode != null)
            IconButton(
              icon: Icon(
                isFav ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFav ? AppColors.brandPrimary : null,
              ),
              tooltip: isFav ? 'Remove from Favourites' : 'Add to Favourites',
              onPressed: () =>
                  _toggleFavorite(profileId, _schemeCode!, schemeName, isFav),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'More actions',
            onSelected: (val) {
              if (val == 'edit_holding' && currentHolding != null) {
                _openEditHolding(context, currentHolding);
              } else if (val == 'delete_holding' && currentHolding != null) {
                _confirmDeleteHolding(context, currentHolding);
              } else if (val == 'delete_sip' && linkedSip != null) {
                _confirmDeleteSip(context, linkedSip);
              }
            },
            itemBuilder: (ctx) => [
              if (currentHolding != null)
                const PopupMenuItem(
                  value: 'edit_holding',
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Holding'),
                    ],
                  ),
                ),
              const PopupMenuDivider(),
              if (currentHolding != null)
                const PopupMenuItem(
                  value: 'delete_holding',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.liability),
                      SizedBox(width: 8),
                      Text('Delete Holding',
                          style: TextStyle(color: AppColors.liability)),
                    ],
                  ),
                )
              else if (linkedSip != null)
                const PopupMenuItem(
                  value: 'delete_sip',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.liability),
                      SizedBox(width: 8),
                      Text('Delete SIP Plan',
                          style: TextStyle(color: AppColors.liability)),
                    ],
                  ),
                ),
            ],
          ),
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
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
            Tab(text: 'Performance History'),
          ],
        ),
      ),
      floatingActionButton: currentHolding == null
          ? null
          : FloatingActionButton(
              tooltip: 'Add transaction',
              onPressed: () =>
                  _openAddTransaction(context, currentHolding!, linkedSip),
              child: const Icon(Icons.add_rounded),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: OVERVIEW
          _buildOverviewTab(
            context: context,
            isDark: isDark,
            holding: currentHolding,
            sip: linkedSip,
            swps: swps,
            swpSchedulePeriods: swpSchedulePeriods,
            swpInstallments: swpInstallments,
            scheme: scheme,
            profileName: profileName,
            transactions: transactions,
            schedulePeriods: schedulePeriods,
            installments: installments,
          ),

          // TAB 2: TRANSACTIONS
          _buildTransactionsTab(
            context: context,
            isDark: isDark,
            holding: currentHolding,
            sip: linkedSip,
            transactions: transactions,
          ),

          // TAB 3: PERFORMANCE HISTORY
          _buildPerformanceHistoryTab(
            context: context,
            isDark: isDark,
            holding: currentHolding,
            scheme: scheme,
            transactions: transactions,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TAB 1: OVERVIEW
  // =========================================================================

  Widget _buildOverviewTab({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required SipPlan? sip,
    required List<SwpPlan> swps,
    required List<SwpSchedulePeriod> swpSchedulePeriods,
    required List<SwpInstallment> swpInstallments,
    required MutualFundScheme? scheme,
    required String profileName,
    required List<Transaction> transactions,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<SipInstallment> installments,
  }) {
    final investedPaise = holding?.initialValuePaise ?? 0;
    final currentValuationPaise = holding?.currentValuationPaise ?? 0;
    final unitsHeld =
        FinancialPrecision.microUnitsToUnits(holding?.unitCountMicroUnits ?? 0);

    final pnlPaise = FinancialCalculator.calculateProfitLossPaise(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );
    final absReturn = FinancialCalculator.calculateAbsoluteReturn(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );
    final xirr = FinancialCalculator.calculateHoldingXirr(
      transactions: transactions,
      currentValuationPaise: currentValuationPaise,
    );

    final isProfit = pnlPaise >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Financial Summary Hero Card
              FinCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CURRENT VALUATION',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        StatusBadge(
                          label:
                              '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(pnlPaise)} (${absReturn.toStringAsFixed(2)}%)',
                          type:
                              isProfit ? BadgeType.asset : BadgeType.liability,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      CurrencyFormatter.formatPaise(currentValuationPaise),
                      style: AppTypography.heroAmount.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (scheme?.latestNavDate != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Valuation based on cached NAV of ${DateFormatter.formatDate(scheme!.latestNavDate!)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // 2x2 Metric Grid
                    Row(
                      children: [
                        Expanded(
                          child: _metricCell(
                            label: 'TOTAL INVESTED',
                            value: CurrencyFormatter.formatPaise(investedPaise),
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _metricCell(
                            label: 'PROFIT / LOSS',
                            value:
                                '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(pnlPaise)}',
                            valueColor: isProfit
                                ? AppColors.asset
                                : AppColors.liability,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _metricCell(
                            label: 'ABSOLUTE RETURN',
                            value:
                                '${absReturn >= 0 ? '+' : ''}${absReturn.toStringAsFixed(2)}%',
                            valueColor: absReturn >= 0
                                ? AppColors.asset
                                : AppColors.liability,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _metricCell(
                            label: 'XIRR / IRR',
                            value: xirr != null
                                ? '${xirr >= 0 ? '+' : ''}${xirr.toStringAsFixed(2)}% p.a.'
                                : '—',
                            valueColor: xirr != null && xirr >= 0
                                ? AppColors.asset
                                : null,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Investment Information Card
              FinCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Investment Information',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _infoRow('Scheme Name',
                        holding?.name ?? scheme?.schemeName ?? '—', isDark),
                    _infoRow('AMC / Fund House',
                        scheme?.fundHouse ?? 'Direct Mutual Fund', isDark),
                    _infoRow(
                        'Category',
                        scheme?.schemeCategory ?? 'Equity / Mutual Fund',
                        isDark),
                    _infoRow(
                        'Units Held', unitsHeld.toStringAsFixed(4), isDark),
                    _infoRow(
                      'Latest NAV',
                      scheme != null &&
                              scheme.latestNavMicroPaise != null &&
                              scheme.latestNavMicroPaise! > 0
                          ? '₹${FinancialPrecision.microPaiseToNav(scheme.latestNavMicroPaise!).toStringAsFixed(4)}${scheme.latestNavDate != null ? ' (${DateFormatter.formatDate(scheme.latestNavDate!)})' : ''}'
                          : '—',
                      isDark,
                    ),
                    _infoRow(
                      'Investment Start Date',
                      holding?.startDate != null
                          ? DateFormatter.formatDate(holding!.startDate!)
                          : (sip != null
                              ? DateFormatter.formatDate(sip.startDate)
                              : '—'),
                      isDark,
                    ),
                    _infoRow('Status',
                        (holding?.status ?? 'active').toUpperCase(), isDark),
                    _infoRow('Profile', profileName, isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. SIP Schedule Periods Section (Minimal format)
              _buildSipScheduleSection(
                context: context,
                isDark: isDark,
                holding: holding,
                sip: sip,
                schedulePeriods: schedulePeriods,
                installments: installments,
              ),
              const SizedBox(height: AppSpacing.md),

              // 4. SWP Withdrawal Schedules Section (Minimal format)
              _buildSwpScheduleSection(
                context: context,
                isDark: isDark,
                holding: holding,
                swps: swps,
                schedulePeriods: swpSchedulePeriods,
                installments: swpInstallments,
              ),
              const SizedBox(height: AppSpacing.md),

              // 5. Investment Lifecycle (Chronological Point-wise events)
              _buildLifecycleSection(
                context: context,
                isDark: isDark,
                holding: holding,
                sips: sip != null ? [sip] : [],
                schedulePeriods: schedulePeriods,
                swps: swps,
                swpPeriods: swpSchedulePeriods,
                transactions: transactions,
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. My Remarks (User notes point-wise, independently editable)
              _buildMyRemarksSection(
                context: context,
                isDark: isDark,
                holding: holding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSipScheduleSection({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required SipPlan? sip,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<SipInstallment> installments,
  }) {
    if (holding == null && sip == null) return const SizedBox.shrink();

    final hasActivePeriod = schedulePeriods.any((p) => p.status == 'active');
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SIP Investment Schedules',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              tooltip: 'SIP schedule actions',
              onSelected: (v) {
                if (v == 'new') {
                  _openAddSipSchedule(context, holding, sip);
                } else if (v == 'edit' && sip != null) {
                  _openEditSipSchedule(context, sip);
                } else if (v == 'close' && sip != null) {
                  _confirmCloseSipPeriod(context, sip);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'new',
                    child: Text(sip == null ? 'Set up SIP' : 'New period')),
                if (sip != null)
                  const PopupMenuItem(
                      value: 'edit', child: Text('Edit period')),
                if (sip != null && hasActivePeriod)
                  const PopupMenuItem(
                      value: 'close', child: Text('Close period')),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (schedulePeriods.isEmpty && sip == null)
          FinCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 24, color: AppColors.brandPrimary),
                    const SizedBox(height: 4),
                    Text(
                      'No active SIP schedule for this holding.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          FinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedulePeriods.isNotEmpty) ...[
                  ...schedulePeriods.map((p) {
                    final isClosed =
                        p.status == 'closed' || p.status == 'superseded';

                    final periodInstallments = installments
                        .where((i) => i.schedulePeriodId == p.id)
                        .toList();
                    final nextInstallment = periodInstallments
                            .where((i) =>
                                i.status == 'upcoming' &&
                                !i.scheduledDate.isBefore(startOfToday))
                            .firstOrNull ??
                        periodInstallments
                            .where((i) => i.status == 'upcoming')
                            .firstOrNull;

                    String statusText;
                    if (nextInstallment != null) {
                      statusText =
                          'Next: ${DateFormatter.formatDate(nextInstallment.scheduledDate)}';
                    } else if (isClosed && p.effectiveTo != null) {
                      statusText =
                          'Ended: ${DateFormatter.formatDate(p.effectiveTo!)}';
                    } else if (isClosed) {
                      statusText = 'Closed';
                    } else {
                      statusText = 'Active';
                    }

                    final minimalText =
                        'SIP · ${CurrencyFormatter.formatPaise(p.amountPaise)} · $statusText';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isClosed
                            ? (isDark
                                ? AppColors.darkSurface.withValues(alpha: 0.5)
                                : AppColors.lightBorder.withValues(alpha: 0.3))
                            : AppColors.brandPrimary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: isClosed
                              ? Colors.transparent
                              : AppColors.brandPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              minimalText,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isClosed
                                    ? (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted)
                                    : null,
                              ),
                            ),
                          ),
                          StatusBadge(
                            label: isClosed ? 'CLOSED' : 'ACTIVE',
                            type:
                                isClosed ? BadgeType.neutral : BadgeType.asset,
                          ),
                        ],
                      ),
                    );
                  }),
                ] else if (sip != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'SIP · ${sip.status.toUpperCase()}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: sip.status.toUpperCase(),
                          type: sip.status.toLowerCase() == 'active'
                              ? BadgeType.asset
                              : BadgeType.neutral,
                        ),
                      ],
                    ),
                  ),
                ],
                if (installments.any((i) => i.status == 'pending_valuation'))
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Some installments are awaiting a historical NAV',
                            style: AppTypography.labelSmall
                                .copyWith(color: AppColors.warning),
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              _retryValuation(context, holding, sip),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSwpScheduleSection({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required List<SwpPlan> swps,
    required List<SwpSchedulePeriod> schedulePeriods,
    required List<SwpInstallment> installments,
  }) {
    if (holding == null) return const SizedBox.shrink();

    final activeSwp = swps.firstOrNull;
    final hasActivePeriod = schedulePeriods.any((p) => p.status == 'active');
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'SWP Withdrawal Schedules',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded),
              tooltip: 'SWP schedule actions',
              onSelected: (v) {
                if (v == 'new') {
                  _openAddSwpSchedule(context, holding, activeSwp);
                } else if (v == 'close' && activeSwp != null) {
                  _confirmCloseSwpPeriod(context, activeSwp);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    value: 'new',
                    child:
                        Text(activeSwp == null ? 'Set up SWP' : 'New period')),
                if (activeSwp != null && hasActivePeriod)
                  const PopupMenuItem(
                      value: 'close', child: Text('Close period')),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (schedulePeriods.isEmpty && activeSwp == null)
          FinCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.outbox_rounded,
                        size: 24, color: AppColors.liability),
                    const SizedBox(height: 4),
                    Text(
                      'No active SWP schedule for this holding.',
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          FinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...schedulePeriods.map((p) {
                  final isClosed =
                      p.status == 'closed' || p.status == 'superseded';

                  final periodInstallments = installments
                      .where((i) => i.schedulePeriodId == p.id)
                      .toList();
                  final nextInstallment = periodInstallments
                          .where((i) =>
                              i.status == 'upcoming' &&
                              !i.scheduledDate.isBefore(startOfToday))
                          .firstOrNull ??
                      periodInstallments
                          .where((i) => i.status == 'upcoming')
                          .firstOrNull;

                  String statusText;
                  if (nextInstallment != null) {
                    statusText =
                        'Next: ${DateFormatter.formatDate(nextInstallment.scheduledDate)}';
                  } else if (isClosed && p.effectiveTo != null) {
                    statusText =
                        'Ended: ${DateFormatter.formatDate(p.effectiveTo!)}';
                  } else if (isClosed) {
                    statusText = 'Closed';
                  } else {
                    statusText = 'Active';
                  }

                  final valStr = p.amountPaise != null
                      ? CurrencyFormatter.formatPaise(p.amountPaise!)
                      : (p.unitsMicroUnits != null
                          ? '${FinancialPrecision.microUnitsToUnits(p.unitsMicroUnits!).toStringAsFixed(4)} Units'
                          : 'Configured Amount');

                  final minimalText = 'SWP · $valStr · $statusText';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isClosed
                          ? (isDark
                              ? AppColors.darkSurface.withValues(alpha: 0.5)
                              : AppColors.lightBorder.withValues(alpha: 0.3))
                          : AppColors.liability.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(
                        color: isClosed
                            ? Colors.transparent
                            : AppColors.liability.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            minimalText,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isClosed
                                  ? (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted)
                                  : null,
                            ),
                          ),
                        ),
                        StatusBadge(
                          label: isClosed ? 'CLOSED' : 'ACTIVE',
                          type: isClosed
                              ? BadgeType.neutral
                              : BadgeType.liability,
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLifecycleSection({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required List<SipPlan> sips,
    required List<SipSchedulePeriod> schedulePeriods,
    required List<SwpPlan> swps,
    required List<SwpSchedulePeriod> swpPeriods,
    required List<Transaction> transactions,
  }) {
    if (holding == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Investment Lifecycle',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        InvestmentLifecycleCard(
          overview: InvestmentLifecycleSummary.buildOverview(
            holding: holding,
            schedulePeriods: schedulePeriods,
            swpPeriods: swpPeriods,
            transactions: transactions,
          ),
          events: InvestmentLifecycleSummary.buildTimeline(
            holding: holding,
            sips: sips,
            schedulePeriods: schedulePeriods,
            swps: swps,
            swpPeriods: swpPeriods,
            transactions: transactions,
          ),
        ),
      ],
    );
  }

  Widget _buildMyRemarksSection({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
  }) {
    final userRemarks = holding?.notes;
    final hasRemarks = userRemarks != null && userRemarks.trim().isNotEmpty;

    final lines = hasRemarks
        ? userRemarks
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList()
        : <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Remarks',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (holding != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Remarks',
                visualDensity: VisualDensity.compact,
                onPressed: () => _editPersonalRemarks(context, holding),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        FinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!hasRemarks)
                InkWell(
                  onTap: holding != null
                      ? () => _editPersonalRemarks(context, holding)
                      : null,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_circle_outline_rounded,
                          size: 16,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No remarks added. Tap to add notes.',
                            style: AppTypography.bodySmall.copyWith(
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...lines.map((line) {
                  final cleanLine = line.replaceFirst(RegExp(r'^[-*•]\s*'), '');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 6, right: 8),
                          child: Icon(Icons.circle,
                              size: 5,
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                        ),
                        Expanded(
                          child: Text(
                            cleanLine,
                            style: AppTypography.bodySmall.copyWith(
                              height: 1.4,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // TAB 2: TRANSACTIONS
  // =========================================================================

  Widget _buildTransactionsTab({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required SipPlan? sip,
    required List<Transaction> transactions,
  }) {
    if (holding == null) {
      return const Center(child: Text('No holding record associated.'));
    }

    final sortedTxs = List<Transaction>.from(transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    // Filter transactions
    final filteredTxs = sortedTxs.where((tx) {
      final type = tx.transactionType.toLowerCase();
      switch (_selectedTxFilter) {
        case 'PURCHASES':
          return type == 'investment_purchase' || type == 'sip_investment';
        case 'SIP':
          return type == 'sip_investment';
        case 'DIVIDENDS':
          return type == 'dividend_reinvestment' || type == 'dividend_payout';
        case 'REDEMPTIONS':
          return type == 'redemption' || type == 'investment_sale';
        case 'SWP':
          return type == 'swp_withdrawal';
        case 'SWITCHES':
          return type == 'switch_in' || type == 'switch_out';
        case 'ALL':
        default:
          return true;
      }
    }).toList();

    return Column(
      children: [
        // Action & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                'Transactions (${filteredTxs.length})',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _filterChip('ALL', 'All (${sortedTxs.length})', isDark),
              _filterChip('PURCHASES', 'Purchases', isDark),
              _filterChip('SIP', 'SIP', isDark),
              _filterChip('DIVIDENDS', 'Dividends', isDark),
              _filterChip('REDEMPTIONS', 'Redemptions', isDark),
              _filterChip('SWP', 'SWP', isDark),
              _filterChip('SWITCHES', 'Switches', isDark),
            ],
          ),
        ),
        const Divider(height: 1),

        // Transaction List
        Expanded(
          child: filteredTxs.isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.receipt_long_rounded,
                    title: 'No Matching Transactions',
                    description: _selectedTxFilter == 'ALL'
                        ? 'No transactions recorded yet for this investment.'
                        : 'No transactions found matching the selected filter.',
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
                  itemCount: filteredTxs.length,
                  itemBuilder: (context, idx) {
                    final tx = filteredTxs[idx];
                    return _transactionRowCard(context, tx, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _selectedTxFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Colors.white
              : (isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary),
        ),
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightBackground,
        selectedColor: AppColors.brandPrimary,
        checkmarkColor: Colors.white,
        onSelected: (_) {
          setState(() => _selectedTxFilter = key);
        },
      ),
    );
  }

  Widget _transactionRowCard(
      BuildContext context, Transaction tx, bool isDark) {
    final type = tx.transactionType.toLowerCase();

    final isInflow = type == 'redemption' ||
        type == 'swp_withdrawal' ||
        type == 'switch_out' ||
        type == 'dividend_payout' ||
        type == 'investment_sale';

    final isReinvest = type == 'dividend_reinvestment';

    final Color badgeColor = isReinvest
        ? AppColors.brandPrimary
        : (isInflow ? AppColors.asset : AppColors.liability);

    final String sign = isReinvest ? '' : (isInflow ? '+' : '-');

    final String displayType = switch (type) {
      'investment_purchase' => 'One-time Purchase',
      'sip_investment' => 'SIP Installment',
      'dividend_reinvestment' => 'IDCW Reinvestment',
      'dividend_payout' => 'IDCW Payout (Cash)',
      'redemption' => 'Redemption',
      'swp_withdrawal' => 'SWP Withdrawal',
      'switch_in' => 'Switch In',
      'switch_out' => 'Switch Out',
      _ => tx.transactionType.replaceAll('_', ' ').toUpperCase(),
    };

    final charges = tx.chargesPaise;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isInflow
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          size: 16,
                          color: badgeColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayType,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${CurrencyFormatter.formatPaise(tx.amountPaise)}',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Details row: Date, NAV, Units, Charges
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  DateFormatter.formatDate(tx.transactionDate),
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
                if (tx.unitPriceMicroPaise != null &&
                    tx.unitPriceMicroPaise! > 0)
                  Text(
                    'NAV: ₹${FinancialPrecision.microPaiseToNav(tx.unitPriceMicroPaise!).toStringAsFixed(4)}',
                    style: AppTypography.labelSmall,
                  ),
                if (tx.unitsMicroUnits != null && tx.unitsMicroUnits! > 0)
                  Text(
                    'Units: ${FinancialPrecision.microUnitsToUnits(tx.unitsMicroUnits!).toStringAsFixed(4)}',
                    style: AppTypography.labelSmall,
                  ),
              ],
            ),

            if (charges > 0) ...[
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Text(
                    'Charges / Fees: ${CurrencyFormatter.formatPaise(charges)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (tx.netAmountPaise != null)
                    Text(
                      'Net Cash: ${CurrencyFormatter.formatPaise(tx.netAmountPaise!)}',
                      style: AppTypography.labelSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],

            if (tx.notes != null && tx.notes!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                tx.notes!,
                style: AppTypography.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // TAB 3: PERFORMANCE HISTORY
  // =========================================================================

  Widget _buildPerformanceHistoryTab({
    required BuildContext context,
    required bool isDark,
    required FinancialItem? holding,
    required MutualFundScheme? scheme,
    required List<Transaction> transactions,
  }) {
    if (_schemeCode == null) {
      return const Center(
          child: Text('No scheme code available for NAV history.'));
    }

    final totalUnits =
        FinancialPrecision.microUnitsToUnits(holding?.unitCountMicroUnits ?? 0);

    final navHistoryAsync = ref.watch(
      schemeNavHistoryRangeProvider(
          (schemeCode: _schemeCode!, range: _selectedTimeRange)),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Range Header
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: AppSpacing.xs,
                children: [
                  Text(
                    'Portfolio Valuation Over Time',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: ['1M', '3M', '6M', '1Y', 'ALL'].map((range) {
                        final isSelected = _selectedTimeRange == range;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () =>
                              setState(() => _selectedTimeRange = range),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              range,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Delayed NAV Disclaimer
              if (scheme?.latestNavDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 14, color: AppColors.brandPrimary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Valuations computed as (Historical Units Held × Historical NAV). Delayed NAVs may apply on weekends and market holidays.',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // FL Chart LineChart Card
              FinCard(
                child: navHistoryAsync.when(
                  data: (navs) {
                    if (navs.length < 2) {
                      return SizedBox(
                        height: 280,
                        child: Center(
                          child: SingleChildScrollView(
                            child: EmptyStateView(
                              icon: Icons.show_chart_rounded,
                              title: 'Insufficient Performance Data',
                              description:
                                  'At least 2 historical NAV data points are required to plot the performance trajectory for $_selectedTimeRange.',
                            ),
                          ),
                        ),
                      );
                    }

                    final sortedNavs = List<NavHistoryData>.from(navs)
                      ..sort((a, b) => a.navDate.compareTo(b.navDate));

                    final spots = <FlSpot>[];
                    double minVal = double.infinity;
                    double maxVal = double.negativeInfinity;

                    for (int i = 0; i < sortedNavs.length; i++) {
                      final item = sortedNavs[i];
                      final unitsAtDate = _computeUnitsAtDate(
                        item.navDate,
                        totalUnits,
                        transactions,
                      );
                      final navRupees = FinancialPrecision.microPaiseToNav(
                          item.navMicroPaise);
                      final valRupees = unitsAtDate * navRupees;

                      if (valRupees < minVal) minVal = valRupees;
                      if (valRupees > maxVal) maxVal = valRupees;

                      spots.add(FlSpot(i.toDouble(), valRupees));
                    }

                    if (minVal == maxVal) {
                      minVal = (minVal * 0.95).clamp(0.0, double.infinity);
                      maxVal = maxVal * 1.05;
                    }

                    final yRange = maxVal - minVal;
                    final yMin =
                        (minVal - yRange * 0.1).clamp(0.0, double.infinity);
                    final yMax = maxVal + yRange * 0.1;

                    return SizedBox(
                      height: 300,
                      child: LineChart(
                        LineChartData(
                          minX: 0,
                          maxX: (sortedNavs.length - 1).toDouble(),
                          minY: yMin,
                          maxY: yMax,
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval:
                                (yRange / 4).clamp(1.0, double.infinity),
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: isDark
                                  ? AppColors.darkBorder.withValues(alpha: 0.5)
                                  : AppColors.lightBorder
                                      .withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: [4, 4],
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 55,
                                interval:
                                    (yRange / 4).clamp(1.0, double.infinity),
                                getTitlesWidget: (value, meta) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: Text(
                                      '₹${_formatShortAmount(value)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                        fontSize: 10,
                                      ),
                                      textAlign: TextAlign.end,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 24,
                                interval: (sortedNavs.length / 4)
                                    .clamp(1.0, double.infinity),
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= sortedNavs.length) {
                                    return const SizedBox();
                                  }
                                  final date = sortedNavs[idx].navDate;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      '${date.day}/${date.month}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            enabled: true,
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final idx = spot.x.toInt();
                                  if (idx >= 0 && idx < sortedNavs.length) {
                                    final item = sortedNavs[idx];
                                    final dateStr =
                                        DateFormatter.formatDate(item.navDate);
                                    final valStr =
                                        CurrencyFormatter.formatPaise(
                                            FinancialPrecision.rupeesToPaise(
                                                spot.y));
                                    final navRupees =
                                        FinancialPrecision.microPaiseToNav(
                                            item.navMicroPaise);
                                    return LineTooltipItem(
                                      '$valStr\n$dateStr\nNAV: ₹${navRupees.toStringAsFixed(2)}',
                                      const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    );
                                  }
                                  return null;
                                }).toList();
                              },
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              curveSmoothness: 0.2,
                              color: AppColors.brandPrimary,
                              barWidth: 2.5,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    AppColors.brandPrimary
                                        .withValues(alpha: 0.25),
                                    AppColors.brandPrimary
                                        .withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SizedBox(
                    height: 260,
                    child: Center(
                      child: Text(
                        'Unable to load NAV performance history: $e',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.liability),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ACTIONS & NAVIGATION
  // =========================================================================

  Future<void> _openEditHolding(
      BuildContext context, FinancialItem holding) async {
    final result = await EditHoldingScreen.push(context, holding);
    if (result == true && mounted) {
      ref.invalidate(activeProfileAssetsProvider);
    }
  }

  Future<void> _openEditSipSchedule(BuildContext context, SipPlan sip) async {
    final result = await EditSipScheduleScreen.push(context, sip);
    if (result == true && mounted) {
      ref.invalidate(activeProfileSipPlansProvider);
      ref.invalidate(sipPeriodsProvider(sip.id));
      ref.invalidate(sipInstallmentsProvider(sip.id));
    }
  }

  Future<void> _retryValuation(
    BuildContext context,
    FinancialItem? holding,
    SipPlan? sip,
  ) async {
    final code = sip?.schemeCode ?? _schemeCode;
    if (code == null) return;
    try {
      await ref
          .read(navSyncServiceProvider)
          .getOrFetchSchemeDetails(code, includeHistoricalNav: true);
    } catch (_) {}
    final count =
        await ref.read(sipsDaoProvider).revaluePendingInstallments(code);
    if (!context.mounted) return;
    ref.invalidate(activeProfileAssetsProvider);
    if (sip != null) ref.invalidate(sipInstallmentsProvider(sip.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(count > 0
            ? 'Valued $count installment(s).'
            : 'Historical NAV is still unavailable for some dates.'),
      ),
    );
  }

  Future<void> _openAddSipSchedule(
    BuildContext context,
    FinancialItem? holding,
    SipPlan? sip,
  ) async {
    if (holding == null) return;
    final result = await AddSipSchedulePeriodScreen.push(
      context,
      holding: holding,
      existingSip: sip,
    );
    if (result == true && mounted) {
      ref.invalidate(activeProfileSipPlansProvider);
      if (sip != null) {
        ref.invalidate(sipPeriodsProvider(sip.id));
        ref.invalidate(sipInstallmentsProvider(sip.id));
      }
    }
  }

  Future<void> _confirmCloseSipPeriod(
    BuildContext context,
    SipPlan sip,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close SIP Schedule Period?'),
        content: Text(
          'This will close the active schedule period for "${sip.name}" as of today and cancel remaining upcoming planned installments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Period'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final sipsDao = ref.read(sipsDaoProvider);
      await sipsDao.closeSchedulePeriod(sipPlanId: sip.id);
      ref.invalidate(activeProfileSipPlansProvider);
      ref.invalidate(sipPeriodsProvider(sip.id));
      ref.invalidate(sipInstallmentsProvider(sip.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SIP schedule period closed.')),
        );
      }
    }
  }

  Future<void> _openAddSwpSchedule(
    BuildContext context,
    FinancialItem? holding,
    SwpPlan? swp,
  ) async {
    if (holding == null) return;
    final result = await AddSwpSchedulePeriodScreen.push(
      context,
      holding: holding,
      existingSwp: swp,
    );
    if (result == true && mounted) {
      ref.invalidate(swpsByHoldingProvider);
      if (swp != null) {
        ref.invalidate(swpPeriodsProvider(swp.id));
        ref.invalidate(swpInstallmentsProvider(swp.id));
      }
    }
  }

  Future<void> _confirmCloseSwpPeriod(
    BuildContext context,
    SwpPlan swp,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Close SWP Schedule Period?'),
        content: Text(
          'This will close the active SWP schedule period for "${swp.name}" as of today and cancel remaining upcoming planned withdrawals.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Period'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final swpsDao = ref.read(swpsDaoProvider);
      await swpsDao.closeSchedulePeriod(swpPlanId: swp.id);
      ref.invalidate(swpsByHoldingProvider);
      ref.invalidate(swpPeriodsProvider(swp.id));
      ref.invalidate(swpInstallmentsProvider(swp.id));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('SWP schedule period closed.')),
        );
      }
    }
  }

  Future<void> _openAddTransaction(
    BuildContext context,
    FinancialItem holding,
    SipPlan? sip,
  ) async {
    final result = await AddInvestmentTransactionScreen.push(
      context,
      holding: holding,
      sips: sip != null ? [sip] : [],
    );
    if (result == true && mounted) {
      ref.invalidate(activeProfileAssetsProvider);
      ref.invalidate(activeProfileTransactionsProvider);
    }
  }

  Future<void> _editPersonalRemarks(
    BuildContext context,
    FinancialItem holding,
  ) async {
    final controller = TextEditingController(text: holding.notes ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Personal Notes'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText:
                'Enter investment goal, target horizon, or personal notes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.financialItemsDao.updateItem(
        holding.copyWith(
          notes: drift.Value(controller.text.trim().isNotEmpty
              ? controller.text.trim()
              : null),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      ref.invalidate(activeProfileAssetsProvider);
    }
  }

  Future<void> _toggleFavorite(
    int profileId,
    int schemeCode,
    String schemeName,
    bool isFav,
  ) async {
    final dao = ref.read(mutualFundDaoProvider);
    await dao.toggleFavorite(
      profileId: profileId,
      schemeCode: schemeCode,
      schemeName: schemeName,
    );
    ref.invalidate(isSchemeFavoriteProvider);
  }

  Future<void> _confirmDeleteHolding(
      BuildContext context, FinancialItem holding) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Investment Holding?'),
        content: Text(
          'This will delete the holding "${holding.name}". Linked SIPs and transactions will be removed consistently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.financialItemsDao.deleteHoldingCascade(holding.id);
      ref.invalidate(activeProfileAssetsProvider);
      ref.invalidate(activeProfileTransactionsProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _confirmDeleteSip(BuildContext context, SipPlan sip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete SIP Plan?'),
        content: Text(
          'This will delete the SIP schedule "${sip.name}". Confirmed past investments are preserved in holding records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final sipsDao = ref.read(sipsDaoProvider);
      await sipsDao.deleteSip(sip.id);
      ref.invalidate(activeProfileSipPlansProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  Widget _metricCell({
    required String label,
    required String value,
    Color? valueColor,
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  double _computeUnitsAtDate(
    DateTime date,
    double totalUnits,
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) return totalUnits;
    int microUnits = 0;
    for (final tx in transactions) {
      if (tx.transactionDate.isBefore(date) ||
          tx.transactionDate.isAtSameMomentAs(date)) {
        final type = tx.transactionType.toLowerCase();
        if (type == 'investment_purchase' ||
            type == 'sip_investment' ||
            type == 'dividend_reinvestment' ||
            type == 'switch_in') {
          microUnits += tx.unitsMicroUnits ?? 0;
        } else if (type == 'redemption' ||
            type == 'swp_withdrawal' ||
            type == 'switch_out' ||
            type == 'investment_sale') {
          microUnits -= tx.unitsMicroUnits ?? 0;
        }
      }
    }
    if (microUnits <= 0) return totalUnits;
    return FinancialPrecision.microUnitsToUnits(microUnits);
  }

  String _formatShortAmount(double value) {
    if (value >= 10000000) {
      return '${(value / 10000000).toStringAsFixed(1)}Cr';
    } else if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  FinancialItem _emptyPlaceholderHolding(SipPlan sip, int profileId) {
    return FinancialItem(
      id: 0,
      profileId: profileId,
      name: sip.name,
      itemType: 'asset',
      subType: 'mutual_fund',
      categoryId: 1,
      externalCode: sip.schemeCode.toString(),
      status: 'active',
      initialValuePaise: 0,
      currentValuationPaise: 0,
      unitCountMicroUnits: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
