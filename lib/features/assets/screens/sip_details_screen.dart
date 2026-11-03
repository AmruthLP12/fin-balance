import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculations/financial_calculator.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import '../widgets/edit_holding_dialog.dart';
import '../widgets/edit_sip_schedule_dialog.dart';

/// Full-screen dedicated details page for a mutual fund holding and its linked SIP schedule.
/// Replaces the cramped bottom-sheet popup with an elegant, responsive full-screen experience.
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

class _SipDetailsScreenState extends ConsumerState<SipDetailsScreen> {
  String _selectedTimeRange = '1M'; // '1M', '3M', '6M', '1Y', 'ALL'

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

    // 3. Watch master scheme and live details
    final schemeCode = _schemeCode;
    final schemeAsync = schemeCode != null
        ? ref.watch(schemeByCodeProvider(schemeCode))
        : const AsyncValue<MutualFundScheme?>.data(null);
    final scheme = schemeAsync.value;

    // Watch favorite state
    final isFavAsync = schemeCode != null
        ? ref.watch(isSchemeFavoriteProvider(schemeCode))
        : const AsyncValue.data(false);
    final isFavorite = isFavAsync.value ?? false;

    // 4. Watch transactions for this holding
    final transactionsAsync = currentHolding != null
        ? ref.watch(transactionsByItemProvider(
            (profileId: currentHolding.profileId, itemId: currentHolding.id),
          ))
        : const AsyncValue<List<Transaction>>.data([]);
    final transactions = transactionsAsync.value ?? [];

    // 5. Watch SIP installments if linked
    final installmentsAsync = linkedSip != null
        ? ref.watch(sipInstallmentsProvider(linkedSip.id))
        : const AsyncValue<List<SipInstallment>>.data([]);
    final installments = installmentsAsync.value ?? [];

    // Valuation calculations
    final investedPaise = currentHolding?.initialValuePaise ??
        installments.where((i) => i.status == 'recorded').fold<int>(0,
            (sum, i) => sum + (i.actualAmountPaise ?? i.expectedAmountPaise));

    final currentValuationPaise =
        currentHolding?.currentValuationPaise ?? investedPaise;
    final profitLossPaise = FinancialCalculator.calculateProfitLossPaise(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );
    final isProfit = profitLossPaise >= 0;
    final absoluteReturn = FinancialCalculator.calculateAbsoluteReturn(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );

    // XIRR calculation using actual transactions
    final xirr = FinancialCalculator.calculateHoldingXirr(
      transactions: transactions,
      currentValuationPaise: currentValuationPaise,
      valuationDate: scheme?.latestNavDate,
    );

    final unitsHeld = currentHolding != null
        ? FinancialPrecision.microUnitsToUnits(
            currentHolding.unitCountMicroUnits)
        : FinancialPrecision.microUnitsToUnits(
            installments
                .where((i) => i.status == 'recorded')
                .fold<int>(0, (sum, i) => sum + (i.unitsMicroUnits ?? 0)),
          );

    final schemeName = scheme?.schemeName ??
        currentHolding?.name ??
        linkedSip?.name ??
        (schemeCode != null ? 'Scheme #$schemeCode' : 'Mutual Fund');

    final fundHouse = scheme?.fundHouse;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Investments',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          schemeName,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (schemeCode != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite ? AppColors.scheduled : null,
              ),
              tooltip:
                  isFavorite ? 'Remove from Favourites' : 'Add to Favourites',
              onPressed: () =>
                  _toggleFavorite(context, schemeCode, schemeName, scheme),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: 'Holding Options',
            onSelected: (val) {
              if (val == 'edit_holding' && currentHolding != null) {
                _openEditHolding(context, currentHolding);
              } else if (val == 'edit_sip' && linkedSip != null) {
                _openEditSipSchedule(context, linkedSip);
              } else if (val == 'delete') {
                _confirmDelete(context, currentHolding, linkedSip, schemeName,
                    profileName);
              }
            },
            itemBuilder: (ctx) => [
              if (currentHolding != null)
                const PopupMenuItem(
                  value: 'edit_holding',
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Edit Holding'),
                    ],
                  ),
                ),
              if (linkedSip != null)
                const PopupMenuItem(
                  value: 'edit_sip',
                  child: Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Edit SIP Schedule'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: AppColors.liability, size: 20),
                    SizedBox(width: 8),
                    Text('Remove from Portfolio',
                        style: TextStyle(color: AppColors.liability)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            // Metadata chips & Subtitle Header
            if (fundHouse != null && fundHouse.isNotEmpty) ...[
              Text(
                fundHouse,
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],

            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                const StatusBadge(
                  label: 'Mutual Fund',
                  type: BadgeType.asset,
                ),
                if (scheme?.planType != null)
                  StatusBadge(
                    label: scheme!.planType!,
                    type: BadgeType.brand,
                  ),
                if (scheme?.optionType != null)
                  StatusBadge(
                    label: scheme!.optionType!,
                    type: BadgeType.neutral,
                  ),
                if (scheme?.schemeCategory != null)
                  StatusBadge(
                    label: scheme!.schemeCategory!,
                    type: BadgeType.neutral,
                  ),
                if (schemeCode != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurfaceHighlight
                          : AppColors.lightSurfaceHighlight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Text(
                      'Code: $schemeCode',
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
            const SizedBox(height: AppSpacing.md),

            // SECTION A: Overview Hero Card
            _buildSectionAOverview(
              context: context,
              isDark: isDark,
              currentValuationPaise: currentValuationPaise,
              investedPaise: investedPaise,
              profitLossPaise: profitLossPaise,
              isProfit: isProfit,
              absoluteReturn: absoluteReturn,
              xirr: xirr,
              unitsHeld: unitsHeld,
              scheme: scheme,
            ),
            const SizedBox(height: AppSpacing.lg),

            // SECTION B: Performance Graph
            _buildSectionBPerformanceGraph(
              context: context,
              isDark: isDark,
              schemeCode: schemeCode,
              unitsHeld: unitsHeld,
              transactions: transactions,
            ),
            const SizedBox(height: AppSpacing.lg),

            // SECTION C: Transaction History
            _buildSectionCTransactions(
              context: context,
              isDark: isDark,
              transactions: transactions,
            ),
            const SizedBox(height: AppSpacing.lg),

            // SECTION D: SIP Schedule (if linked)
            if (linkedSip != null) ...[
              _buildSectionDSipSchedule(
                context: context,
                isDark: isDark,
                sip: linkedSip,
                installments: installments,
                schemeName: schemeName,
                profileName: profileName,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// SECTION A: Overview Card
  Widget _buildSectionAOverview({
    required BuildContext context,
    required bool isDark,
    required int currentValuationPaise,
    required int investedPaise,
    required int profitLossPaise,
    required bool isProfit,
    required double absoluteReturn,
    required double? xirr,
    required double unitsHeld,
    required MutualFundScheme? scheme,
  }) {
    return FinCard(
      backgroundColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
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
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              StatusBadge(
                label: isProfit
                    ? '+${absoluteReturn.toStringAsFixed(2)}% Abs'
                    : '${absoluteReturn.toStringAsFixed(2)}% Abs',
                type: isProfit ? BadgeType.asset : BadgeType.liability,
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
                child: _buildMetricBlock(
                  label: 'TOTAL INVESTED',
                  value: CurrencyFormatter.formatPaise(investedPaise),
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMetricBlock(
                  label: 'PROFIT / LOSS',
                  value:
                      '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(profitLossPaise)}',
                  valueColor: isProfit ? AppColors.asset : AppColors.liability,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricBlock(
                  label: 'ANNUALIZED RETURN (XIRR)',
                  value: xirr != null ? '${xirr.toStringAsFixed(2)}%' : '—',
                  valueColor: (xirr != null && xirr >= 0)
                      ? AppColors.asset
                      : ((xirr != null && xirr < 0)
                          ? AppColors.liability
                          : null),
                  helperText: xirr != null
                      ? 'Dated cash flows'
                      : 'Requires multi-day history',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMetricBlock(
                  label: 'UNITS HELD',
                  value: unitsHeld.toStringAsFixed(3),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildMetricBlock(
                  label: 'LATEST NAV',
                  value: scheme?.latestNavMicroPaise != null
                      ? '₹${FinancialPrecision.microPaiseToNav(scheme!.latestNavMicroPaise!).toStringAsFixed(4)}'
                      : '—',
                  isDark: isDark,
                ),
              ),
              Expanded(
                child: _buildMetricBlock(
                  label: 'NAV DATE',
                  value: scheme?.latestNavDate != null
                      ? DateFormatter.formatDate(scheme!.latestNavDate!)
                      : '—',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBlock({
    required String label,
    required String value,
    Color? valueColor,
    String? helperText,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ??
                (isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary),
            fontSize: 14,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 1),
          Text(
            helperText,
            style: AppTypography.labelSmall.copyWith(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              fontSize: 9,
            ),
          ),
        ],
      ],
    );
  }

  /// SECTION B: Performance Graph
  Widget _buildSectionBPerformanceGraph({
    required BuildContext context,
    required bool isDark,
    required int? schemeCode,
    required double unitsHeld,
    required List<Transaction> transactions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              'Performance History',
              style: AppTypography.titleLarge.copyWith(
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Time range selector
            Container(
              decoration: BoxDecoration(
                color:
                    isDark ? AppColors.darkSurface : AppColors.lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['1M', '3M', '6M', '1Y', 'ALL'].map((range) {
                  final isSelected = _selectedTimeRange == range;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() => _selectedTimeRange = range),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        range,
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
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

        // Line Chart Card
        if (schemeCode == null)
          const FinCard(
            child: EmptyStateView(
              icon: Icons.show_chart_rounded,
              title: 'No Historical Data',
              description:
                  'Historical performance requires a tracked mutual fund scheme code.',
            ),
          )
        else
          ref
              .watch(schemeNavHistoryRangeProvider(
                  (schemeCode: schemeCode, range: _selectedTimeRange)))
              .when(
                loading: () => const FinCard(
                  child: SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => FinCard(
                  child: EmptyStateView(
                    icon: Icons.error_outline_rounded,
                    title: 'Unable to Load Performance Curve',
                    description: err.toString(),
                  ),
                ),
                data: (navPoints) {
                  // Sort ascending by date for chronological curve
                  final sortedNavs = List<NavHistoryData>.from(navPoints)
                    ..sort((a, b) => a.navDate.compareTo(b.navDate));

                  if (sortedNavs.length < 2) {
                    return const FinCard(
                      child: EmptyStateView(
                        icon: Icons.timeline_rounded,
                        title: 'Insufficient Historical Points',
                        description:
                            'At least 2 historical NAV points are required to plot the performance curve. Daily synchronization will populate this chart over time.',
                      ),
                    );
                  }

                  // Compute spots (index, valuation in Rupees)
                  final spots = <FlSpot>[];
                  double minY = double.infinity;
                  double maxY = double.negativeInfinity;

                  for (int i = 0; i < sortedNavs.length; i++) {
                    final nav = sortedNavs[i];
                    // Compute units at that date
                    final unitsAtDate = _computeUnitsAtDate(
                        nav.navDate, unitsHeld, transactions);
                    final navRupees =
                        FinancialPrecision.microPaiseToNav(nav.navMicroPaise);
                    final valuationRupees = unitsAtDate * navRupees;

                    if (valuationRupees < minY) minY = valuationRupees;
                    if (valuationRupees > maxY) maxY = valuationRupees;

                    spots.add(FlSpot(i.toDouble(), valuationRupees));
                  }

                  if (minY == maxY) {
                    minY *= 0.9;
                    maxY *= 1.1;
                  }

                  return FinCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              lineTouchData: LineTouchData(
                                enabled: true,
                                touchTooltipData: LineTouchTooltipData(
                                  getTooltipColor: (_) => isDark
                                      ? AppColors.darkSurfaceElevated
                                      : AppColors.lightSurfaceElevated,
                                  getTooltipItems: (touchedSpots) {
                                    return touchedSpots.map((spot) {
                                      final idx = spot.x
                                          .toInt()
                                          .clamp(0, sortedNavs.length - 1);
                                      final navItem = sortedNavs[idx];
                                      final dateStr = DateFormatter.formatDate(
                                          navItem.navDate);
                                      final formattedVal =
                                          CurrencyFormatter.format(spot.y);
                                      return LineTooltipItem(
                                        '$formattedVal\n$dateStr',
                                        TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextPrimary
                                              : AppColors.lightTextPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      );
                                    }).toList();
                                  },
                                ),
                              ),
                              gridData: FlGridData(
                                show: true,
                                drawVerticalLine: false,
                                horizontalInterval: ((maxY - minY) / 4)
                                    .clamp(1.0, double.infinity),
                                getDrawingHorizontalLine: (value) => FlLine(
                                  color: isDark
                                      ? AppColors.darkBorder
                                          .withValues(alpha: 0.4)
                                      : AppColors.lightBorder
                                          .withValues(alpha: 0.6),
                                  strokeWidth: 1,
                                ),
                              ),
                              titlesData: FlTitlesData(
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 22,
                                    interval: (sortedNavs.length / 4)
                                        .clamp(1.0, double.infinity),
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= sortedNavs.length) {
                                        return const SizedBox();
                                      }
                                      final date = sortedNavs[idx].navDate;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4.0),
                                        child: Text(
                                          '${date.day}/${date.month}',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            color: isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted,
                                            fontSize: 9,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (sortedNavs.length - 1).toDouble(),
                              minY: minY * 0.98,
                              maxY: maxY * 1.02,
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
                                            .withValues(alpha: 0.3),
                                        AppColors.brandPrimary
                                            .withValues(alpha: 0.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${sortedNavs.length} recorded daily NAV points',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              'Range: ${DateFormatter.formatDate(sortedNavs.first.navDate)} – ${DateFormatter.formatDate(sortedNavs.last.navDate)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      ],
    );
  }

  /// SECTION C: Transaction History
  Widget _buildSectionCTransactions({
    required BuildContext context,
    required bool isDark,
    required List<Transaction> transactions,
  }) {
    final sortedTx = List<Transaction>.from(transactions)
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Transaction History (${sortedTx.length})',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (sortedTx.isEmpty)
          const FinCard(
            child: EmptyStateView(
              icon: Icons.history_rounded,
              title: 'No Transactions Logged',
              description:
                  'Completed investments and SIP purchases for this holding will appear here.',
            ),
          )
        else
          ...sortedTx.map((tx) {
            final isPurchase = tx.transactionType == 'investment_purchase';
            final isSale = tx.transactionType == 'investment_sale';
            final units = tx.unitsMicroUnits != null
                ? FinancialPrecision.microUnitsToUnits(tx.unitsMicroUnits!)
                : null;
            final navRupees = tx.unitPriceMicroPaise != null
                ? FinancialPrecision.microPaiseToNav(tx.unitPriceMicroPaise!)
                : null;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: FinCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isPurchase
                            ? AppColors.asset.withValues(alpha: 0.15)
                            : (isSale
                                ? AppColors.liability.withValues(alpha: 0.15)
                                : AppColors.brandPrimary
                                    .withValues(alpha: 0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPurchase
                            ? Icons.arrow_downward_rounded
                            : (isSale
                                ? Icons.arrow_upward_rounded
                                : Icons.swap_horiz_rounded),
                        color: isPurchase
                            ? AppColors.asset
                            : (isSale
                                ? AppColors.liability
                                : AppColors.brandPrimary),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPurchase
                                ? 'Purchase / Installment'
                                : (isSale
                                    ? 'Redemption / Sale'
                                    : 'Transaction'),
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            DateFormatter.formatDate(tx.transactionDate),
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                              fontSize: 11,
                            ),
                          ),
                          if (units != null)
                            Text(
                              '${units.toStringAsFixed(3)} units${navRupees != null ? ' @ ₹${navRupees.toStringAsFixed(4)}' : ''}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (isPurchase ? '+' : (isSale ? '−' : '')) +
                              CurrencyFormatter.formatPaise(tx.amountPaise),
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPurchase
                                ? AppColors.asset
                                : (isSale
                                    ? AppColors.liability
                                    : (isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.lightTextPrimary)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// SECTION D: SIP Schedule
  Widget _buildSectionDSipSchedule({
    required BuildContext context,
    required bool isDark,
    required SipPlan sip,
    required List<SipInstallment> installments,
    required String schemeName,
    required String profileName,
  }) {
    final periodsAsync = ref.watch(sipPeriodsProvider(sip.id));
    final currentPeriod =
        periodsAsync.value?.where((p) => p.status == 'active').firstOrNull ??
            periodsAsync.value?.firstOrNull;

    final installmentAmountPaise = currentPeriod?.amountPaise ?? 0;
    final frequency = currentPeriod?.frequency ?? 'monthly';

    final recorded = installments.where((i) => i.status == 'recorded').toList();
    final pending =
        installments.where((i) => i.status == 'pending_valuation').toList();
    final upcoming = installments
        .where((i) => i.status == 'upcoming' || i.status == 'simulated')
        .toList();
    final cancelled = installments
        .where((i) => i.status == 'cancelled' || i.status == 'skipped')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'SIP Investment Schedule',
          actionLabel: 'Edit Schedule',
          onActionTap: () => _openEditSipSchedule(context, sip),
        ),
        const SizedBox(height: AppSpacing.sm),
        FinCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      sip.name,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(
                    label: sip.status.toUpperCase(),
                    type: _badgeTypeForStatus(sip.status),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Installment details row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricBlock(
                    label: 'INSTALLMENT AMOUNT',
                    value:
                        CurrencyFormatter.formatPaise(installmentAmountPaise),
                    valueColor: AppColors.brandPrimary,
                    isDark: isDark,
                  ),
                  _buildMetricBlock(
                    label: 'FREQUENCY',
                    value: frequency.toUpperCase(),
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMetricBlock(
                    label: 'STARTED ON',
                    value: DateFormatter.formatDate(sip.startDate),
                    isDark: isDark,
                  ),
                  _buildMetricBlock(
                    label: 'END DATE',
                    value: sip.endDate != null
                        ? DateFormatter.formatDate(sip.endDate!)
                        : 'Ongoing',
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.sm),

              // Status Counts Breakdown
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusBadge(
                    label: '${recorded.length} Confirmed Investments',
                    type: BadgeType.asset,
                  ),
                  if (pending.isNotEmpty)
                    StatusBadge(
                      label: '${pending.length} Pending Valuation',
                      type: BadgeType.scheduled,
                    ),
                  StatusBadge(
                    label: '${upcoming.length} Planned Future',
                    type: BadgeType.neutral,
                  ),
                  if (cancelled.isNotEmpty)
                    StatusBadge(
                      label: '${cancelled.length} Cancelled / Skipped',
                      type: BadgeType.liability,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Note: Planned future installments are forward projections and do not contribute to invested capital, current valuation, IRR, or actual portfolio net worth.',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (pending.isNotEmpty)
                    TextButton.icon(
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Retry Valuation',
                          style: TextStyle(fontSize: 12)),
                      onPressed: () =>
                          _retryValuation(context, ref, sip.schemeCode),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined,
                        color: AppColors.warning, size: 16),
                    label: const Text('Cancel Future',
                        style:
                            TextStyle(color: AppColors.warning, fontSize: 12)),
                    onPressed: () => _confirmCancelFuture(context, ref, sip.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  double _computeUnitsAtDate(
    DateTime date,
    double totalUnits,
    List<Transaction> transactions,
  ) {
    if (transactions.isEmpty) return totalUnits;
    // Calculate cumulative units up to target date
    int microUnits = 0;
    for (final tx in transactions) {
      if (tx.transactionDate.isBefore(date) ||
          tx.transactionDate.isAtSameMomentAs(date)) {
        if (tx.transactionType == 'investment_purchase') {
          microUnits += tx.unitsMicroUnits ?? 0;
        } else if (tx.transactionType == 'investment_sale') {
          microUnits -= tx.unitsMicroUnits ?? 0;
        }
      }
    }
    if (microUnits <= 0) {
      return totalUnits; // Fallback if transactions didn't log microUnits
    }
    return FinancialPrecision.microUnitsToUnits(microUnits);
  }

  BadgeType _badgeTypeForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BadgeType.asset;
      case 'paused':
        return BadgeType.scheduled;
      case 'stopped':
      case 'cancelled':
        return BadgeType.liability;
      default:
        return BadgeType.neutral;
    }
  }

  FinancialItem _emptyPlaceholderHolding(SipPlan sip, int profileId) {
    return FinancialItem(
      id: 0,
      profileId: profileId,
      categoryId: 1,
      name: sip.name,
      itemType: 'asset',
      subType: 'mutual_fund',
      externalCode: sip.schemeCode.toString(),
      initialValuePaise: 0,
      currentValuationPaise: 0,
      unitCountMicroUnits: 0,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    int schemeCode,
    String schemeName,
    MutualFundScheme? scheme,
  ) async {
    final profileId = ref.read(activeProfileIdProvider);
    final dao = ref.read(mutualFundDaoProvider);
    final nowFav = await dao.toggleFavorite(
      profileId: profileId,
      schemeCode: schemeCode,
      schemeName: schemeName,
      fundHouse: scheme?.fundHouse,
      planType: scheme?.planType,
      optionType: scheme?.optionType,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(nowFav
              ? 'Added "$schemeName" to favourites!'
              : 'Removed "$schemeName" from favourites.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _openEditHolding(BuildContext context, FinancialItem item) {
    showDialog<void>(
      context: context,
      builder: (_) => EditHoldingDialog(holding: item),
    );
  }

  void _openEditSipSchedule(BuildContext context, SipPlan sip) {
    showDialog<void>(
      context: context,
      builder: (_) => EditSipScheduleDialog(sip: sip),
    );
  }

  void _confirmDelete(
    BuildContext context,
    FinancialItem? holding,
    SipPlan? sip,
    String schemeName,
    String profileName,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Portfolio?'),
        content: Text(
          'Are you sure you want to remove "$schemeName" from $profileName’s portfolio? This will remove all associated transactions and schedules.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () async {
              Navigator.of(ctx).pop(); // dismiss dialog
              if (holding != null) {
                final itemsDao = ref.read(financialItemsDaoProvider);
                await itemsDao.deleteHoldingCascade(holding.id);
              } else if (sip != null) {
                final sipsDao = ref.read(sipsDaoProvider);
                await sipsDao.deleteSip(sip.id);
              }
              if (context.mounted) {
                Navigator.of(context).pop(); // pop details screen back to list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "$schemeName" from portfolio.'),
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

  void _confirmCancelFuture(BuildContext context, WidgetRef ref, int sipId) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Future Installments?'),
        content: const Text(
          'This will cancel all upcoming scheduled installments and stop the SIP plan. Past recorded investments and units will be safely preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Schedule'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.scheduled),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final sipsDao = ref.read(sipsDaoProvider);
              await sipsDao.cancelFutureInstallments(sipId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Cancelled future installments. SIP stopped.'),
                  ),
                );
              }
            },
            child: const Text('Cancel Future'),
          ),
        ],
      ),
    );
  }

  Future<void> _retryValuation(
      BuildContext context, WidgetRef ref, int schemeCode) async {
    final sipsDao = ref.read(sipsDaoProvider);
    final count = await sipsDao.revaluePendingInstallments(schemeCode);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Successfully valued $count pending installment(s).'
              : 'Valuation not updated. Ensure internet connectivity is active.'),
        ),
      );
    }
  }
}
