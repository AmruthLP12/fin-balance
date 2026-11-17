import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/asset_categories.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import '../loan_calculator.dart';
import '../widgets/add_liability_dialog.dart';

BadgeType loanBadgeType(FinancialItem loan) => LoanCalculator.isClosed(loan)
    ? BadgeType.asset
    : LoanCalculator.termEnded(loan)
        ? BadgeType.liability
        : BadgeType.scheduled;

/// Loan details with the same layout as the SIP details: actions in the app
/// bar menu, and Overview / Payments / Schedule tabs.
class LoanDetailsScreen extends ConsumerWidget {
  final FinancialItem item;

  const LoanDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    // Watch the live row so edits and payments show up immediately.
    final loan = ref
            .watch(activeProfileAllLiabilitiesProvider)
            .value
            ?.where((l) => l.id == item.id)
            .firstOrNull ??
        item;
    final payments = (ref
                .watch(transactionsByItemProvider(
                    (profileId: loan.profileId, itemId: loan.id)))
                .value ??
            const <Transaction>[])
        .where((t) => t.transactionType == 'debt_repayment')
        .toList()
      ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    final lender = loan.lenderName;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loan.name,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              Text(
                [
                  categoryLabel(loan.subType),
                  if (lender != null && lender.isNotEmpty) lender,
                ].join(' · '),
                style: AppTypography.labelSmall.copyWith(color: muted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More actions',
              onSelected: (v) => _onAction(context, ref, loan, v),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit_note_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Loan'),
                  ]),
                ),
                if (LoanCalculator.isOngoing(loan))
                  const PopupMenuItem(
                    value: 'close',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Close Loan'),
                    ]),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.liability),
                    SizedBox(width: 8),
                    Text('Delete Loan',
                        style: TextStyle(color: AppColors.liability)),
                  ]),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            labelColor:
                isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
            unselectedLabelColor: muted,
            indicatorColor:
                isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Payments'),
              Tab(text: 'Schedule'),
            ],
          ),
        ),
        floatingActionButton: LoanCalculator.isOngoing(loan)
            ? FloatingActionButton(
                tooltip: 'Record payment',
                onPressed: () => showLoanRepaymentDialog(context, ref, loan),
                child: const Icon(Icons.add_rounded),
              )
            : null,
        body: TabBarView(
          children: [
            _OverviewTab(loan: loan, payments: payments, isDark: isDark),
            _PaymentsTab(payments: payments, isDark: isDark),
            _ScheduleTab(loan: loan, payments: payments, isDark: isDark),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, WidgetRef ref,
      FinancialItem loan, String action) async {
    final db = ref.read(databaseProvider);
    if (action == 'edit') {
      await AddLiabilityDialog.show(context, liability: loan);
    } else if (action == 'close') {
      if (await _confirm(
          context,
          'Close loan?',
          'Close "${loan.name}"? It moves to Closed and no longer counts in your totals.',
          'Close loan')) {
        await db.financialItemsDao.updateItem(
            loan.copyWith(status: 'closed', updatedAt: DateTime.now().toUtc()));
      }
    } else if (action == 'delete') {
      if (await _confirm(
          context,
          'Delete loan?',
          'This permanently deletes the loan. Its payment history is kept as unlinked transactions.',
          'Delete')) {
        await db.financialItemsDao.deleteItem(loan.id);
        if (context.mounted) Navigator.of(context).pop();
      }
    }
  }

  static Future<bool> _confirm(
      BuildContext context, String title, String body, String ok) async {
    return await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: Text(title),
            content: Text(body),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true), child: Text(ok)),
            ],
          ),
        ) ??
        false;
  }
}

class _OverviewTab extends StatelessWidget {
  final FinancialItem loan;
  final List<Transaction> payments;
  final bool isDark;

  const _OverviewTab(
      {required this.loan, required this.payments, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final remaining = loan.currentValuationPaise;
    final principal = loan.initialValuePaise;
    final repaid = (principal - remaining).clamp(0, principal).toInt();
    final progress = principal > 0 ? repaid / principal : 0.0;
    final paidInApp = payments.fold<int>(0, (s, t) => s + t.amountPaise);
    final maturity = LoanCalculator.maturityDate(loan);
    final tenure = [
      if ((loan.tenureYears ?? 0) > 0) '${loan.tenureYears} yrs',
      if ((loan.tenureMonths ?? 0) > 0) '${loan.tenureMonths} mths',
      if ((loan.tenureDays ?? 0) > 0) '${loan.tenureDays} days',
    ].join(' ');
    final ongoing = LoanCalculator.isOngoing(loan);

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: AppTypography.bodyMedium.copyWith(color: muted))),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                  child: Text(value,
                      textAlign: TextAlign.end,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600))),
            ],
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FinCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('REMAINING BALANCE',
                            style: AppTypography.labelSmall.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        StatusBadge(
                            label: LoanCalculator.status(loan),
                            type: loanBadgeType(loan)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(CurrencyFormatter.formatPaise(remaining),
                        style: AppTypography.heroAmount.copyWith(
                            color: ongoing
                                ? AppColors.liability
                                : (isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary))),
                    if (ongoing && LoanCalculator.termEnded(loan)) ...[
                      const SizedBox(height: 2),
                      Text(
                          'Term ended${maturity != null ? ' on ${DateFormatter.formatDate(maturity)}' : ''}; this amount is still owed.',
                          style: AppTypography.labelSmall
                              .copyWith(color: AppColors.liability)),
                    ] else if (ongoing &&
                        LoanCalculator.monthsLeft(loan) > 0) ...[
                      const SizedBox(height: 2),
                      Text('${LoanCalculator.monthsLeft(loan)} months left',
                          style:
                              AppTypography.labelSmall.copyWith(color: muted)),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 8,
                          color: AppColors.asset),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Repaid ${CurrencyFormatter.formatPaise(repaid)} of ${CurrencyFormatter.formatPaise(principal)}',
                        style: AppTypography.labelSmall.copyWith(color: muted)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FinCard(
                child: Column(
                  children: [
                    row('Loan type', categoryLabel(loan.subType)),
                    if (loan.lenderName?.isNotEmpty == true)
                      row('Lender', loan.lenderName!),
                    row('Sanctioned / principal',
                        CurrencyFormatter.formatPaise(principal)),
                    if (loan.interestRateBasisPoints != null)
                      row(
                          'Interest rate',
                          '${(loan.interestRateBasisPoints! / 100).toStringAsFixed(2)}% ${loan.interestRateType ?? ''}'
                              .trim()),
                    if (loan.emiPaise != null)
                      row('EMI', CurrencyFormatter.formatPaise(loan.emiPaise!)),
                    if (tenure.isNotEmpty) row('Tenure', tenure),
                    row(
                        'Start date',
                        loan.startDate == null
                            ? 'Not set'
                            : DateFormatter.formatDate(loan.startDate!)),
                    row(
                        'Maturity date',
                        maturity == null
                            ? 'Not set'
                            : DateFormatter.formatDate(maturity)),
                    row('Paid via FinBalance',
                        '${CurrencyFormatter.formatPaise(paidInApp)} (${payments.length} payments)'),
                    if (loan.notes?.isNotEmpty == true)
                      row('Notes', loan.notes!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  final List<Transaction> payments;
  final bool isDark;

  const _PaymentsTab({required this.payments, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('No payments recorded yet. Use + to record one.',
            textAlign: TextAlign.center),
      ));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
      itemCount: payments.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final t = payments[i];
        return FinCard(
          child: Row(
            children: [
              const Icon(Icons.payments_outlined, color: AppColors.asset),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormatter.formatDate(t.transactionDate),
                        style: AppTypography.titleMedium),
                    if (t.notes?.isNotEmpty == true)
                      Text(t.notes!, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              Text(CurrencyFormatter.formatPaise(t.amountPaise),
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      },
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  final FinancialItem loan;
  final List<Transaction> payments;
  final bool isDark;

  const _ScheduleTab(
      {required this.loan, required this.payments, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final start = loan.startDate;
    final end = LoanCalculator.maturityDate(loan);
    if (start == null || end == null) {
      return const Center(
          child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Set a start date and tenure to see the monthly schedule.',
            textAlign: TextAlign.center),
      ));
    }
    final paid = <String, int>{};
    for (final t in payments) {
      final k = _key(t.transactionDate);
      paid[k] = (paid[k] ?? 0) + t.amountPaise;
    }
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final emi = loan.emiPaise;
    final closed = LoanCalculator.isClosed(loan);
    final lastPaid = payments.isEmpty
        ? null
        : payments
            .map((t) =>
                DateTime(t.transactionDate.year, t.transactionDate.month))
            .reduce((a, b) => a.isAfter(b) ? a : b);
    final months = <DateTime>[];
    for (var m = DateTime(start.year, start.month);
        !m.isAfter(DateTime(end.year, end.month)) && months.length < 1200;
        m = DateTime(m.year, m.month + 1)) {
      months.add(m);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, 88),
      itemCount: months.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (_, i) {
        final m = months[i];
        final p = paid[_key(m)] ?? 0;
        final due = !m.isAfter(thisMonth);
        final (label, type) = p > 0 && (emi == null || p >= emi * 0.99)
            ? ('PAID', BadgeType.asset)
            : p > 0
                ? ('PARTIAL', BadgeType.scheduled)
                : closed && (lastPaid == null || m.isAfter(lastPaid))
                    ? ('PRECLOSED', BadgeType.neutral)
                    : due && m.isBefore(thisMonth)
                        ? ('NOT RECORDED', BadgeType.neutral)
                        : ('UPCOMING', BadgeType.scheduled);
        return FinCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_months[m.month - 1]} ${m.year}',
                        style: AppTypography.titleMedium),
                    Text(
                        emi == null
                            ? 'Paid ${CurrencyFormatter.formatPaise(p)}'
                            : 'EMI ${CurrencyFormatter.formatPaise(emi)} · paid ${CurrencyFormatter.formatPaise(p)}',
                        style: AppTypography.bodySmall),
                  ],
                ),
              ),
              StatusBadge(label: label, type: type),
            ],
          ),
        );
      },
    );
  }

  static String _key(DateTime d) => '${d.year}-${d.month}';
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

/// Dialog to record a dated repayment; reduces the remaining balance.
Future<void> showLoanRepaymentDialog(
    BuildContext context, WidgetRef ref, FinancialItem item) async {
  final controller = TextEditingController();
  final notesController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var paymentDate = DateTime.now();
  final result =
      await showDialog<({double amount, DateTime date, String notes})>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Record payment for ${item.name}'),
      content: StatefulBuilder(
        builder: (context, setDialogState) => Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              validator: (value) => (double.tryParse(value ?? '') ?? 0) <= 0
                  ? 'Enter a valid amount'
                  : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Payment date'),
              subtitle: Text(DateFormatter.formatDate(paymentDate)),
              trailing: const Icon(Icons.calendar_today_outlined, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: paymentDate,
                  firstDate: item.startDate ?? DateTime(2000),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setDialogState(() => paymentDate = picked);
                }
              },
            ),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
          ]),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context, (
                amount: double.parse(controller.text.trim()),
                date: paymentDate,
                notes: notesController.text.trim(),
              ));
            }
          },
          child: const Text('Save payment'),
        ),
      ],
    ),
  );
  controller.dispose();
  notesController.dispose();
  if (result == null || !context.mounted) return;
  try {
    await ref.read(transactionsDaoProvider).recordDebtRepayment(
          profileId: item.profileId,
          financialItemId: item.id,
          categoryId: item.categoryId,
          transactionDate: result.date,
          amountPaise: FinancialPrecision.rupeesToPaise(result.amount),
          notes: result.notes,
        );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $error')));
    }
  }
}
