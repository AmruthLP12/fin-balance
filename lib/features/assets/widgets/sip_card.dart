import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import 'edit_sip_schedule_dialog.dart';
import 'sip_installments_sheet.dart';

/// Card displaying a master SIP Plan, investment frequency, installment breakdown,
/// units accumulated, valuation, valuation status, and schedule management actions.
class SipCard extends ConsumerWidget {
  final SipPlan sip;

  const SipCard({super.key, required this.sip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final periodsAsync = ref.watch(sipPeriodsProvider(sip.id));
    final schemeAsync = ref.watch(schemeByCodeProvider(sip.schemeCode));
    final installmentsAsync = ref.watch(sipInstallmentsProvider(sip.id));
    final assetsAsync = ref.watch(activeProfileAssetsProvider);

    final schemeName =
        schemeAsync.value?.schemeName ?? 'Scheme #${sip.schemeCode}';
    final fundHouse = schemeAsync.value?.fundHouse;

    final activeProfile = ref.watch(activeProfileProvider).value;
    final profileName = activeProfile?.name ?? 'Profile';

    // Find linked holding if any
    final holdings = assetsAsync.value ?? [];
    final linkedHolding = sip.financialItemId != null
        ? holdings.where((h) => h.id == sip.financialItemId).firstOrNull
        : holdings
            .where((h) => h.externalCode == sip.schemeCode.toString())
            .firstOrNull;

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sip.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schemeName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: sip.status.toUpperCase(),
                type: _badgeTypeForStatus(sip.status),
              ),
            ],
          ),
          if (fundHouse != null && fundHouse.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              fundHouse,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Active Schedule Period Info: Frequency & Amount
          periodsAsync.when(
            data: (periods) {
              if (periods.isEmpty) {
                return const Text('No schedule periods defined.');
              }
              final activePeriod = periods.last;
              final amountStr =
                  CurrencyFormatter.formatPaise(activePeriod.amountPaise);
              final freqStr = activePeriod.frequency.toUpperCase();

              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$freqStr AMOUNT',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amountStr,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.asset,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'FREQUENCY',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activePeriod.frequency.toUpperCase(),
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Detailed Installment Breakdown & Valuation Metrics
          installmentsAsync.when(
            data: (installments) {
              final now = DateTime.now();
              final today = DateTime.utc(now.year, now.month, now.day);

              final totalCount = installments.length;
              final pastInstallments = installments
                  .where((i) => !i.scheduledDate.isAfter(today))
                  .toList();
              final futureInstallments = installments
                  .where((i) => i.scheduledDate.isAfter(today))
                  .toList();

              final confirmedInvestedPaise = installments
                  .where((i) => i.status == 'recorded')
                  .fold<int>(
                      0,
                      (sum, i) =>
                          sum + (i.actualAmountPaise ?? i.expectedAmountPaise));

              final plannedFuturePaise = futureInstallments.fold<int>(
                  0, (sum, i) => sum + i.expectedAmountPaise);

              final pendingValuationCount = installments
                  .where((i) => i.status == 'pending_valuation')
                  .length;

              final unitsAccumulated = linkedHolding != null
                  ? FinancialPrecision.microUnitsToUnits(
                      linkedHolding.unitCountMicroUnits)
                  : FinancialPrecision.microUnitsToUnits(installments
                      .where((i) => i.status == 'recorded')
                      .fold<int>(
                          0, (sum, i) => sum + (i.unitsMicroUnits ?? 0)));

              final currentValuationPaise = linkedHolding != null
                  ? linkedHolding.currentValuationPaise
                  : confirmedInvestedPaise;

              return Column(
                children: [
                  // Installment counts row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metricColumn(
                        label: 'TOTAL INSTALLMENTS',
                        value: '$totalCount',
                        isDark: isDark,
                      ),
                      _metricColumn(
                        label: 'PAST (ACTUAL)',
                        value:
                            '${pastInstallments.length} (${CurrencyFormatter.formatPaise(confirmedInvestedPaise)})',
                        valueColor: AppColors.asset,
                        isDark: isDark,
                      ),
                      _metricColumn(
                        label: 'FUTURE (PLANNED)',
                        value:
                            '${futureInstallments.length} (${CurrencyFormatter.formatPaise(plannedFuturePaise)})',
                        valueColor: AppColors.scheduled,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Units & Current Valuation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _metricColumn(
                        label: 'UNITS ACCUMULATED',
                        value: unitsAccumulated.toStringAsFixed(3),
                        isDark: isDark,
                      ),
                      _metricColumn(
                        label: 'CURRENT VALUATION',
                        value: CurrencyFormatter.formatPaise(
                            currentValuationPaise),
                        valueColor: AppColors.asset,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Valuation Status Badge & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            pendingValuationCount > 0
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 14,
                            color: pendingValuationCount > 0
                                ? AppColors.warning
                                : AppColors.asset,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pendingValuationCount > 0
                                ? '$pendingValuationCount installment(s) pending valuation'
                                : 'All past installments valued',
                            style: AppTypography.labelSmall.copyWith(
                              color: pendingValuationCount > 0
                                  ? AppColors.warning
                                  : AppColors.asset,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (pendingValuationCount > 0)
                        TextButton(
                          onPressed: () => _retryValuation(context, ref),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Retry Valuation',
                              style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppSpacing.xs),

          // Dates Summary
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Started ${DateFormatter.formatDate(sip.startDate)}${sip.endDate != null ? ' • Until ${DateFormatter.formatDate(sip.endDate!)}' : ' • Ongoing'}',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.liability, size: 20),
                tooltip: 'Delete Schedule',
                onPressed: () => _confirmDeleteSip(
                  context,
                  ref,
                  schemeName,
                  profileName,
                  installmentsAsync.value ?? [],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Installments'),
                onPressed: () => _openInstallments(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text('Edit'),
                onPressed: () => _openEditSchedule(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricColumn({
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
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  BadgeType _badgeTypeForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BadgeType.asset;
      case 'paused':
        return BadgeType.scheduled;
      case 'completed':
        return BadgeType.neutral;
      case 'stopped':
      case 'cancelled':
        return BadgeType.liability;
      default:
        return BadgeType.neutral;
    }
  }

  void _openInstallments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SipInstallmentsSheet(sip: sip),
    );
  }

  void _openEditSchedule(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => EditSipScheduleDialog(sip: sip),
    );
  }

  Future<void> _retryValuation(BuildContext context, WidgetRef ref) async {
    final sipsDao = ref.read(sipsDaoProvider);
    final count = await sipsDao.revaluePendingInstallments(sip.schemeCode);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? 'Successfully valued $count pending installment(s)!'
              : 'Historical NAV still pending for some dates.'),
          backgroundColor: count > 0 ? AppColors.asset : AppColors.warning,
        ),
      );
    }
  }

  Future<void> _confirmDeleteSip(
    BuildContext context,
    WidgetRef ref,
    String schemeName,
    String profileName,
    List<SipInstallment> installments,
  ) async {
    final recordedInstallments =
        installments.where((i) => i.status == 'recorded').toList();
    final confirmedCount = recordedInstallments.length;
    final confirmedAmountPaise = recordedInstallments.fold<int>(
      0,
      (sum, i) => sum + (i.actualAmountPaise ?? i.expectedAmountPaise),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Investment Schedule?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${sip.name}"?',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppColors.darkBorder
                      : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scheme: $schemeName', style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text('Profile: $profileName',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text('Total Installments: ${installments.length}',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text('Confirmed Transactions: $confirmedCount',
                      style: AppTypography.labelSmall),
                  const SizedBox(height: 2),
                  Text(
                    'Confirmed Amount: ${CurrencyFormatter.formatPaise(confirmedAmountPaise)}',
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All associated schedule periods, installments, and ledger transactions will be permanently removed.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.liability,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Schedule'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final sipsDao = ref.read(sipsDaoProvider);
      await sipsDao.deleteSip(sip.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted SIP schedule "${sip.name}"'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    }
  }
}
