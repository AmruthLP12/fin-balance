import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/scheduling/investment_schedule_service.dart';
import '../../../database/precision/financial_precision.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';

/// Sheet displaying all installments generated for a SIP Plan, with actions to record or skip.
class SipInstallmentsSheet extends ConsumerWidget {
  final SipPlan sip;

  const SipInstallmentsSheet({super.key, required this.sip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final installmentsAsync = ref.watch(sipInstallmentsProvider(sip.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sip.name,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Installment Ledger & Projections',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded),
                      tooltip: 'Schedule Options',
                      onSelected: (val) {
                        if (val == 'cancel_future') {
                          _confirmCancelFuture(context, ref);
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: 'cancel_future',
                          child: Row(
                            children: [
                              Icon(Icons.stop_circle_outlined,
                                  color: AppColors.warning, size: 20),
                              SizedBox(width: AppSpacing.sm),
                              Text('Cancel Future Installments'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              Expanded(
                child: installmentsAsync.when(
                  data: (installments) {
                    if (installments.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.calendar_month_rounded,
                        title: 'No Installments Generated',
                        description:
                            'Installments are generated according to the SIP schedule periods.',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: AppSpacing.screenPadding,
                      itemCount: installments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final inst = installments[index];
                        final isRecorded = inst.status == 'recorded';
                        final isUpcoming = inst.status == 'upcoming';
                        final amount =
                            inst.actualAmountPaise ?? inst.expectedAmountPaise;

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightSurfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(
                              color: isRecorded
                                  ? AppColors.asset.withValues(alpha: 0.3)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isRecorded
                                    ? Icons.check_circle_rounded
                                    : (inst.isSimulated
                                        ? Icons.query_builder_rounded
                                        : Icons.schedule_rounded),
                                color: isRecorded
                                    ? AppColors.asset
                                    : (inst.isSimulated
                                        ? AppColors.scheduled
                                        : (isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted)),
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormatter.formatDate(
                                              inst.scheduledDate),
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        StatusBadge(
                                          label: inst.status.toUpperCase(),
                                          type:
                                              _badgeTypeForStatus(inst.status),
                                        ),
                                        if (inst.isSimulated) ...[
                                          const SizedBox(width: AppSpacing.xs),
                                          const StatusBadge(
                                            label: 'SIMULATED',
                                            type: BadgeType.neutral,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatPaise(amount),
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUpcoming) ...[
                                IconButton(
                                  icon: const Icon(Icons.check_rounded,
                                      color: AppColors.asset),
                                  tooltip: 'Record as Invested',
                                  onPressed: () =>
                                      _markRecorded(context, ref, inst),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded,
                                      color: AppColors.warning),
                                  tooltip: 'Skip Installment',
                                  onPressed: () => _skipInstallment(ref, inst),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel_outlined,
                                      color: AppColors.liability, size: 20),
                                  tooltip: 'Cancel Installment',
                                  onPressed: () =>
                                      _cancelInstallment(ref, inst),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit Installment',
                                onPressed: () =>
                                    _editInstallment(context, ref, inst),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded,
                                    color: AppColors.liability, size: 20),
                                tooltip: 'Delete Installment',
                                onPressed: () => _confirmDeleteInstallment(
                                    context, ref, inst),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BadgeType _badgeTypeForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'recorded':
        return BadgeType.asset;
      case 'upcoming':
        return BadgeType.scheduled;
      case 'skipped':
        return BadgeType.neutral;
      case 'cancelled':
        return BadgeType.liability;
      default:
        return BadgeType.neutral;
    }
  }

  Future<void> _markRecorded(
      BuildContext context, WidgetRef ref, SipInstallment inst) async {
    final sipsDao = ref.read(sipsDaoProvider);
    await sipsDao.recordActualInstallment(
      installmentId: inst.id,
      actualDate: inst.scheduledDate,
      actualAmountPaise: inst.expectedAmountPaise,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment marked as recorded & investment logged!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Edit the date and amount. Recorded installments update their linked
  /// investment too (units follow the saved NAV); weekends move to Monday.
  Future<void> _editInstallment(
      BuildContext context, WidgetRef ref, SipInstallment inst) async {
    final recorded = inst.status == 'recorded' && inst.transactionId != null;
    var date = recorded
        ? (inst.actualInvestmentDate ?? inst.scheduledDate)
        : inst.scheduledDate;
    final paise = recorded
        ? (inst.actualAmountPaise ?? inst.expectedAmountPaise)
        : inst.expectedAmountPaise;
    final amount = TextEditingController(
        text: (paise / 100).toStringAsFixed(paise % 100 == 0 ? 0 : 2));
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Edit installment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormatter.formatDate(date)),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => date = d);
                },
              ),
              const Text('A Saturday or Sunday moves to Monday.',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Save')),
          ],
        ),
      ),
    );
    final value = double.tryParse(amount.text.trim());
    amount.dispose();
    if (ok != true || value == null || value <= 0) return;
    final newPaise = FinancialPrecision.rupeesToPaise(value);
    final day = InvestmentScheduleService.nextWeekday(
        DateTime(date.year, date.month, date.day));
    final dao = ref.read(sipsDaoProvider);
    if (recorded) {
      final nav = inst.purchaseNavMicroPaise;
      await dao.updateLinkedTransaction(
        transactionId: inst.transactionId!,
        date: day,
        amountPaise: newPaise,
        purchaseNavMicroPaise: nav,
        unitsMicroUnits: nav != null && nav > 0
            ? FinancialPrecision.calculateUnitsPurchased(
                amountPaise: newPaise, navMicroPaise: nav)
            : inst.unitsMicroUnits,
        notes: inst.notes,
      );
    } else {
      await dao.updatePlannedInstallment(
          installmentId: inst.id, date: day, amountPaise: newPaise);
    }
  }

  Future<void> _skipInstallment(WidgetRef ref, SipInstallment inst) async {
    final sipsDao = ref.read(sipsDaoProvider);
    await sipsDao.skipInstallment(inst.id);
  }

  Future<void> _cancelInstallment(WidgetRef ref, SipInstallment inst) async {
    final sipsDao = ref.read(sipsDaoProvider);
    await sipsDao.cancelInstallment(inst.id);
  }

  Future<void> _confirmCancelFuture(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Future Installments?'),
        content: const Text(
          'This will cancel all upcoming scheduled installments for this SIP plan. Past recorded investments and accumulated units will remain completely intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Active'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.warning),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cancel Future'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final sipsDao = ref.read(sipsDaoProvider);
      final count = await sipsDao.cancelFutureInstallments(sip.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cancelled $count future installment(s).'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteInstallment(
      BuildContext context, WidgetRef ref, SipInstallment inst) async {
    final isRecorded = inst.status == 'recorded';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Installment?'),
        content: Text(
          isRecorded
              ? 'This installment is marked as recorded. Deleting it will remove the linked ledger transaction and deduct ${inst.unitsMicroUnits != null ? (inst.unitsMicroUnits! / 1000000).toStringAsFixed(3) : 0} units from the holding.'
              : 'Are you sure you want to remove this installment from the schedule?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final sipsDao = ref.read(sipsDaoProvider);
      await sipsDao.deleteInstallment(inst.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Installment deleted.'),
          ),
        );
      }
    }
  }
}
