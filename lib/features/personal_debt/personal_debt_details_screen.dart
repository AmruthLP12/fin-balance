import 'package:flutter/material.dart';
import 'personal_debt_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/cash_flow.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/notifications/personal_debt_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fin_card.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Monthly interest (paise) on what is still outstanding, or null if none.
int? personalMonthlyInterest(FinancialItem item) {
  final bps = item.interestRateBasisPoints;
  if (bps == null || bps <= 0) return null;
  final monthlyPct =
      item.interestRateType == 'monthly' ? bps / 100 : bps / 100 / 12;
  return (item.currentValuationPaise * monthlyPct / 100).round();
}

String personalRateLabel(FinancialItem item) {
  final bps = item.interestRateBasisPoints;
  if (bps == null || bps <= 0) return 'No interest';
  final r = (bps / 100).toStringAsFixed(bps % 100 == 0 ? 0 : 2);
  return '$r% per ${item.interestRateType == 'monthly' ? 'month' : 'year'}';
}

/// Details of money lent to / borrowed from a person: outstanding amount,
/// interest on it, and every payment. Works for both directions.
class PersonalDebtDetailsScreen extends ConsumerWidget {
  final int itemId;
  const PersonalDebtDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(financialItemByIdProvider(itemId)).value;
    if (item == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final lent = item.itemType == 'asset';
    final color = lent ? AppColors.asset : AppColors.liability;
    final entries = (ref
                .watch(transactionsByItemProvider(
                    (profileId: item.profileId, itemId: item.id)))
                .value ??
            const <Transaction>[])
        .toList()
      ..sort((a, b) {
        final date = b.transactionDate.compareTo(a.transactionDate);
        if (date != 0) return date;
        final created = b.createdAt.compareTo(a.createdAt);
        if (created != 0) return created;
        return b.id.compareTo(a.id);
      });
    final interestTotal = entries
        .where((t) =>
            t.transactionType == 'interest_paid' ||
            t.transactionType == 'interest_received')
        .fold<int>(0, (s, t) => s + t.amountPaise);
    final active = item.status == 'active';
    final monthly = personalMonthlyInterest(item);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => _menu(context, ref, item, v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (active)
                const PopupMenuItem(
                    value: 'close', child: Text('Mark as settled')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FinCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lent ? 'They still owe you' : 'You still owe',
                    style: AppTypography.labelSmall),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.formatPaise(item.currentValuationPaise),
                    style: AppTypography.headlineMedium
                        .copyWith(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                _row('${lent ? 'Lent' : 'Borrowed'} in total',
                    CurrencyFormatter.formatPaise(item.initialValuePaise)),
                if (item.startDate != null)
                  _row('Date', DateFormatter.formatDate(item.startDate!)),
                if (item.maturityDate != null)
                  _row(lent ? 'Expected back by' : 'To be repaid by',
                      DateFormatter.formatDate(item.maturityDate!)),
                _row('Interest', personalRateLabel(item)),
                if (item.interestDueDate != null)
                  _row(lent ? 'Interest due date' : 'Interest payable date',
                      DateFormatter.formatDate(item.interestDueDate!)),
                if (item.interestDueAmountPaise != null)
                  _row(
                      'Interest amount',
                      CurrencyFormatter.formatPaise(
                          item.interestDueAmountPaise!)),
                if (monthly != null && active)
                  _row('Interest on the remaining amount',
                      '${CurrencyFormatter.formatPaise(monthly)} / month'),
                _row(lent ? 'Interest received so far' : 'Interest paid so far',
                    CurrencyFormatter.formatPaise(interestTotal)),
                if (!active) _row('Status', 'Settled'),
                if (item.notes != null && item.notes!.isNotEmpty)
                  _row('Notes', item.notes!),
              ],
            ),
          ),
          if (active) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () =>
                        _entry(context, ref, item, interest: false),
                    child: Text(lent ? 'Money returned' : 'Repay'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _entry(context, ref, item, interest: true),
                    child: Text(lent ? 'Interest received' : 'Interest paid'),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          const Text('History', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          if (entries.isEmpty)
            const Text('Nothing recorded yet.')
          else
            for (final t in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                    personalFlowLabel(t.transactionType) ?? t.transactionType),
                subtitle: Text(DateFormatter.formatDate(t.transactionDate) +
                    ((t.notes ?? '').isEmpty ? '' : ' · ${t.notes}')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CurrencyFormatter.formatPaise(t.amountPaise),
                        style: AppTypography.titleMedium),
                    if (t.transactionType == 'interest_paid' ||
                        t.transactionType == 'interest_received' ||
                        t.transactionType == 'lend_repaid' ||
                        t.transactionType == 'debt_repayment')
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, size: 18),
                        padding: EdgeInsets.zero,
                        onSelected: (action) {
                          if (action == 'edit') {
                            _editEntry(context, ref, t);
                          } else if (action == 'delete') {
                            _deleteEntry(context, ref, t);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'edit', child: Text('Edit entry')),
                          PopupMenuItem(
                              value: 'delete', child: Text('Delete entry')),
                        ],
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _editEntry(
      BuildContext context, WidgetRef ref, Transaction entry) async {
    final amount = TextEditingController(
        text: (entry.amountPaise / 100)
            .toStringAsFixed(entry.amountPaise % 100 == 0 ? 0 : 2));
    final notes = TextEditingController(text: entry.notes ?? '');
    var date = entry.transactionDate;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                autofocus: true,
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
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => date = d);
                },
              ),
              TextField(
                  controller: notes,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)')),
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
    final note = notes.text;
    amount.dispose();
    notes.dispose();
    if (ok != true || value == null || value <= 0) return;
    try {
      await ref.read(transactionsDaoProvider).updatePersonalEntry(
            transactionId: entry.id,
            amountPaise: FinancialPrecision.rupeesToPaise(value),
            date: DateTime(date.year, date.month, date.day),
            notes: note,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not update: $e')));
      }
    }
  }

  Future<void> _deleteEntry(
      BuildContext context, WidgetRef ref, Transaction entry) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text(
            'This removes the entry. Repayment entries also restore the outstanding amount.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(transactionsDaoProvider).deletePersonalEntry(entry.id);
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Text(k, style: AppTypography.bodySmall)),
            const SizedBox(width: 8),
            Flexible(
                child: Text(v,
                    textAlign: TextAlign.end,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  Future<void> _entry(BuildContext context, WidgetRef ref, FinancialItem item,
      {required bool interest}) async {
    final dueAmount = interest ? item.interestDueAmountPaise : null;
    final amount = TextEditingController(
        text: dueAmount == null
            ? ''
            : (dueAmount / 100).toStringAsFixed(dueAmount % 100 == 0 ? 0 : 2));
    final notes = TextEditingController();
    var date = interest && item.interestDueDate != null
        ? item.interestDueDate!
        : DateTime.now();
    final lent = item.itemType == 'asset';
    final title = interest
        ? (lent ? 'Interest received' : 'Interest paid')
        : (lent ? 'Money returned' : 'Repayment');
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, setState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    helperText: interest &&
                            personalMonthlyInterest(item) != null
                        ? 'One month on the remaining amount: ${CurrencyFormatter.formatPaise(personalMonthlyInterest(item)!)}'
                        : null,
                    helperMaxLines: 2),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormatter.formatDate(date)),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: c,
                      initialDate: date,
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => date = d);
                },
              ),
              TextField(
                  controller: notes,
                  decoration:
                      const InputDecoration(labelText: 'Note (optional)')),
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
    final note = notes.text;
    amount.dispose();
    notes.dispose();
    if (ok != true || value == null || value <= 0) return;
    try {
      await ref.read(transactionsDaoProvider).recordPersonalEntry(
            itemId: item.id,
            interest: interest,
            amountPaise: FinancialPrecision.rupeesToPaise(value),
            date: DateTime(date.year, date.month, date.day),
            notes: note,
          );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref, FinancialItem item,
      String action) async {
    if (action == 'edit') {
      return PersonalDebtForm.show(context,
          lent: item.itemType == 'asset', item: item);
    }
    final db = ref.read(databaseProvider);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(action == 'close' ? 'Mark as settled?' : 'Delete?'),
        content: Text(action == 'close'
            ? 'It moves out of your totals. History is kept.'
            : 'This deletes "${item.name}" and removes all of its entries from the Activity ledger.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Yes')),
        ],
      ),
    );
    if (ok != true) return;
    if (action == 'close') {
      await db.financialItemsDao.updateItem(
          item.copyWith(status: 'closed', updatedAt: DateTime.now().toUtc()));
      await PersonalDebtReminderService.cancel(item.id);
    } else {
      await ref.read(transactionsDaoProvider).deletePersonalDebt(item.id);
      await PersonalDebtReminderService.cancel(item.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}
