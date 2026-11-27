import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fin_card.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';
import 'savings_form.dart';

const _depositType = 'investment_purchase';
const _interestType = 'interest_received';

String _entryLabel(String type) => switch (type) {
      _depositType => 'Deposit',
      'voluntary_deposit' => 'Deposit', // older entries; one deposit type now
      _interestType => 'Interest credited',
      _ => type,
    };

/// A PPF / SSS account: balance, every deposit and interest entry (all
/// editable), and the optional monthly deduction.
class SavingsDetailsScreen extends ConsumerWidget {
  final int itemId;
  const SavingsDetailsScreen({super.key, required this.itemId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(financialItemByIdProvider(itemId)).value;
    if (item == null) {
      return Scaffold(appBar: AppBar(), body: const SizedBox.shrink());
    }
    final entries = (ref
                .watch(transactionsByItemProvider(
                    (profileId: item.profileId, itemId: item.id)))
                .value ??
            const <Transaction>[])
        .toList()
      ..sort((a, b) {
        final d = b.transactionDate.compareTo(a.transactionDate);
        return d != 0 ? d : b.id.compareTo(a.id);
      });
    final schedule = (ref
                .watch(schedulesByItemProvider(
                    (profileId: item.profileId, itemId: item.id)))
                .value ??
            const <RecurringTransaction>[])
        .where(
            (s) => s.recurringType == 'savings_deposit' && s.status == 'active')
        .firstOrNull;
    final interest = entries
        .where((t) => t.transactionType == _interestType)
        .fold<int>(0, (s, t) => s + t.amountPaise);

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => v == 'edit'
                ? SavingsFormScreen.show(context,
                    subType: item.subType, item: item)
                : _deleteAccount(context, ref, item),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit account')),
              PopupMenuItem(value: 'delete', child: Text('Delete account')),
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
                const Text('Balance', style: AppTypography.labelSmall),
                const SizedBox(height: 4),
                Text(CurrencyFormatter.formatPaise(item.currentValuationPaise),
                    style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.asset, fontWeight: FontWeight.bold)),
                const SizedBox(height: AppSpacing.sm),
                _row('Deposited',
                    CurrencyFormatter.formatPaise(item.initialValuePaise)),
                _row('Interest credited so far',
                    CurrencyFormatter.formatPaise(interest)),
                if (item.bankName != null) _row('Bank', item.bankName!),
                if (item.startDate != null)
                  _row('Opened', DateFormatter.formatDate(item.startDate!)),
                if (item.maturityDate != null)
                  _row('Matures', DateFormatter.formatDate(item.maturityDate!)),
                _row(
                    'Monthly deduction',
                    schedule == null
                        ? 'None'
                        : '${CurrencyFormatter.formatPaise(schedule.amountPaise)} on day ${schedule.scheduledDay}'
                            '${schedule.nextDueDate == null ? '' : ' · next ${DateFormatter.formatDate(schedule.nextDueDate!)}'}'),
                if (item.notes != null && item.notes!.isNotEmpty)
                  _row('Notes', item.notes!),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Deposit'),
                onPressed: () => _add(context, ref, item, _depositType),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded),
                label: const Text('Interest'),
                onPressed: () => _add(context, ref, item, _interestType),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text('History', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          if (entries.isEmpty)
            const Text('Nothing recorded yet.')
          else
            for (final t in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_entryLabel(t.transactionType)),
                subtitle: Text(DateFormatter.formatDate(t.transactionDate) +
                    ((t.notes ?? '').isEmpty ? '' : ' · ${t.notes}')),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(CurrencyFormatter.formatPaise(t.amountPaise),
                        style: AppTypography.titleMedium),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, size: 18),
                      padding: EdgeInsets.zero,
                      onSelected: (a) => a == 'edit'
                          ? _edit(context, ref, t)
                          : _deleteEntry(context, ref, t),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit entry')),
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

  /// Amount, date and note dialog for adding or editing an entry.
  Future<({int paise, DateTime date, String note})?> _ask(
    BuildContext context, {
    required String title,
    int? paise,
    DateTime? date,
    String note = '',
  }) async {
    final amount = TextEditingController(
        text: paise == null
            ? ''
            : (paise / 100).toStringAsFixed(paise % 100 == 0 ? 0 : 2));
    final notes = TextEditingController(text: note);
    var picked = date ?? DateTime.now();
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
                decoration: const InputDecoration(
                    labelText: 'Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today_rounded, size: 16),
                label: Text(DateFormatter.formatDate(picked)),
                onPressed: () async {
                  final d = await showDatePicker(
                      context: c,
                      initialDate: picked,
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => picked = d);
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
    final text = notes.text;
    // Not disposed here: the dialog is still animating closed and would rebuild
    // its fields with a dead controller. They have no listeners, so GC frees them.
    if (ok != true || value == null || value <= 0) return null;
    return (
      paise: FinancialPrecision.rupeesToPaise(value),
      date: DateTime(picked.year, picked.month, picked.day),
      note: text,
    );
  }

  Future<void> _run(
      BuildContext context, Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _add(BuildContext context, WidgetRef ref, FinancialItem item,
      String type) async {
    final r = await _ask(context, title: _entryLabel(type));
    if (r == null || !context.mounted) return;
    await _run(
        context,
        () => ref.read(transactionsDaoProvider).recordSavingsEntry(
            itemId: item.id,
            type: type,
            amountPaise: r.paise,
            date: r.date,
            notes: r.note));
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, Transaction entry) async {
    final r = await _ask(context,
        title: 'Edit ${_entryLabel(entry.transactionType).toLowerCase()}',
        paise: entry.amountPaise,
        date: entry.transactionDate,
        note: entry.notes ?? '');
    if (r == null || !context.mounted) return;
    await _run(
        context,
        () => ref.read(transactionsDaoProvider).updateSavingsEntry(
            transactionId: entry.id,
            amountPaise: r.paise,
            date: r.date,
            notes: r.note));
  }

  Future<bool> _confirm(
          BuildContext context, String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteEntry(
      BuildContext context, WidgetRef ref, Transaction entry) async {
    if (!await _confirm(
        context, 'Delete entry?', 'The balance is recalculated without it.')) {
      return;
    }
    await ref.read(transactionsDaoProvider).deleteSavingsEntry(entry.id);
  }

  Future<void> _deleteAccount(
      BuildContext context, WidgetRef ref, FinancialItem item) async {
    if (!await _confirm(context, 'Delete account?',
        'This deletes "${item.name}" and all of its entries.')) {
      return;
    }
    await ref.read(financialItemsDaoProvider).deleteHoldingCascade(item.id);
    if (context.mounted) Navigator.of(context).pop();
  }
}
