import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/notifications/personal_debt_reminder_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Simple form for money you lent to someone or borrowed from someone:
/// who, how much, when, and an optional interest rate. No EMI, no tenure.
class PersonalDebtForm extends ConsumerStatefulWidget {
  final bool lent;

  /// Set to edit an existing record instead of adding one.
  final FinancialItem? item;
  const PersonalDebtForm({super.key, required this.lent, this.item});

  static Future<void> show(BuildContext context,
          {required bool lent, FinancialItem? item}) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PersonalDebtForm(lent: lent, item: item)));

  @override
  ConsumerState<PersonalDebtForm> createState() => _PersonalDebtFormState();
}

class _PersonalDebtFormState extends ConsumerState<PersonalDebtForm> {
  final _key = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _dueAmount = TextEditingController();
  final _notes = TextEditingController();
  String _period = 'monthly';
  bool _interest = false;
  DateTime _date = DateTime.now();
  DateTime? _endDate;
  DateTime? _interestDueDate;
  bool _saving = false;

  /// 'lent' (money someone owes you) or 'other' (a plain asset record).
  String _kind = 'lent';
  bool get _other => widget.lent && _kind == 'other';

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i == null) return;
    if (i.subType == 'other_asset') _kind = 'other';
    _person.text = i.name;
    _amount.text = (i.initialValuePaise / 100).toString();
    _notes.text = i.notes ?? '';
    _date = i.startDate ?? DateTime.now();
    _endDate = i.maturityDate;
    _interestDueDate = i.interestDueDate;
    if (i.interestDueAmountPaise != null) {
      _dueAmount.text = (i.interestDueAmountPaise! / 100)
          .toStringAsFixed(i.interestDueAmountPaise! % 100 == 0 ? 0 : 2);
    }
    final bps = i.interestRateBasisPoints;
    if (bps != null && bps > 0) {
      _interest = true;
      _rate.text = (bps / 100).toString();
      _period = i.interestRateType == 'yearly' ? 'yearly' : 'monthly';
    }
  }

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _rate.dispose();
    _dueAmount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rate = _interest ? double.tryParse(_rate.text.trim()) : null;
      final amountPaise =
          FinancialPrecision.rupeesToPaise(double.parse(_amount.text.trim()));
      final old = widget.item;
      if (_other) {
        await _saveOtherAsset(amountPaise);
        if (mounted) Navigator.of(context).pop();
        return;
      }
      if (old != null) {
        // Changing the amount moves what is outstanding by the same difference.
        final outstanding =
            (old.currentValuationPaise + amountPaise - old.initialValuePaise)
                .clamp(0, 1 << 62);
        await ref.read(databaseProvider).financialItemsDao.updateItem(
              old.copyWith(
                name: _person.text.trim(),
                lenderName: drift.Value(_person.text.trim()),
                initialValuePaise: amountPaise,
                currentValuationPaise: outstanding,
                interestRateBasisPoints: drift.Value(
                    rate == null || rate <= 0 ? null : (rate * 100).round()),
                interestRateType: drift.Value(_period),
                startDate:
                    drift.Value(DateTime(_date.year, _date.month, _date.day)),
                maturityDate: drift.Value(_endDate),
                interestDueDate: drift.Value(_interestDueDate),
                interestDueAmountPaise: drift.Value(_interest
                    ? (double.tryParse(_dueAmount.text.trim()) == null
                        ? null
                        : FinancialPrecision.rupeesToPaise(
                            double.parse(_dueAmount.text.trim())))
                    : null),
                notes: drift.Value(
                    _notes.text.trim().isEmpty ? null : _notes.text.trim()),
                updatedAt: DateTime.now().toUtc(),
              ),
            );
        final transactions =
            await ref.read(transactionsDaoProvider).getTransactionsByItem(
                  old.profileId,
                  old.id,
                );
        final opening = transactions.where((t) =>
            t.transactionType == 'lend_given' ||
            t.transactionType == 'borrowing_received');
        if (opening.isNotEmpty) {
          final tx = opening.first;
          await ref.read(transactionsDaoProvider).updateTransaction(
                tx.copyWith(
                  transactionDate: DateTime(_date.year, _date.month, _date.day),
                  amountPaise: amountPaise,
                  netAmountPaise: drift.Value(amountPaise),
                  notes: drift.Value(widget.lent
                      ? 'Lent to ${_person.text.trim()}'
                      : 'Borrowed from ${_person.text.trim()}'),
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
        } else {
          await ref.read(transactionsDaoProvider).insertTransaction(
                TransactionsCompanion(
                  profileId: drift.Value(old.profileId),
                  financialItemId: drift.Value(old.id),
                  transactionType: drift.Value(
                      widget.lent ? 'lend_given' : 'borrowing_received'),
                  categoryId: drift.Value(old.categoryId),
                  transactionDate:
                      drift.Value(DateTime(_date.year, _date.month, _date.day)),
                  amountPaise: drift.Value(amountPaise),
                  netAmountPaise: drift.Value(amountPaise),
                  notes: drift.Value(widget.lent
                      ? 'Lent to ${_person.text.trim()}'
                      : 'Borrowed from ${_person.text.trim()}'),
                ),
              );
        }
        if (_interest &&
            _interestDueDate != null &&
            _dueAmount.text.trim().isNotEmpty) {
          final dueAmount = FinancialPrecision.rupeesToPaise(
              double.parse(_dueAmount.text.trim()));
          await PersonalDebtReminderService.schedule(
            itemId: old.id,
            person: _person.text.trim(),
            lent: widget.lent,
            dueDate: _interestDueDate!,
            amountPaise: dueAmount,
          );
        } else {
          await PersonalDebtReminderService.cancel(old.id);
        }
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final itemId = await ref.read(transactionsDaoProvider).openPersonalDebt(
            profileId: ref.read(activeProfileIdProvider),
            lent: widget.lent,
            person: _person.text.trim(),
            amountPaise: amountPaise,
            endDate: _endDate,
            date: DateTime(_date.year, _date.month, _date.day),
            rateBasisPoints:
                rate == null || rate <= 0 ? null : (rate * 100).round(),
            ratePeriod: _period,
            interestDueDate:
                _interest && _interestDueDate != null ? _interestDueDate : null,
            interestDueAmountPaise:
                _interest && _dueAmount.text.trim().isNotEmpty
                    ? FinancialPrecision.rupeesToPaise(
                        double.parse(_dueAmount.text.trim()))
                    : null,
            notes: _notes.text,
          );
      if (_interest &&
          _interestDueDate != null &&
          _dueAmount.text.trim().isNotEmpty) {
        await PersonalDebtReminderService.schedule(
          itemId: itemId,
          person: _person.text.trim(),
          lent: widget.lent,
          dueDate: _interestDueDate!,
          amountPaise: FinancialPrecision.rupeesToPaise(
              double.parse(_dueAmount.text.trim())),
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  Future<void> _saveOtherAsset(int amountPaise) async {
    final dao = ref.read(databaseProvider).financialItemsDao;
    final date = DateTime(_date.year, _date.month, _date.day);
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    final old = widget.item;
    if (old != null) {
      await dao.updateItem(old.copyWith(
        name: _person.text.trim(),
        initialValuePaise: amountPaise,
        currentValuationPaise: amountPaise,
        startDate: drift.Value(date),
        notes: drift.Value(notes),
        updatedAt: DateTime.now().toUtc(),
      ));
      return;
    }
    final db = ref.read(databaseProvider);
    final cats = await db.categoriesDao.getCategoriesByClassification('asset');
    final cat = cats.where((c) => c.name == 'Other Assets');
    await dao.insertItem(FinancialItemsCompanion(
      profileId: drift.Value(ref.read(activeProfileIdProvider)),
      name: drift.Value(_person.text.trim()),
      itemType: const drift.Value('asset'),
      subType: const drift.Value('other_asset'),
      categoryId: drift.Value(cat.isNotEmpty
          ? cat.first.id
          : (cats.isNotEmpty ? cats.first.id : 1)),
      initialValuePaise: drift.Value(amountPaise),
      currentValuationPaise: drift.Value(amountPaise),
      startDate: drift.Value(date),
      notes: notes == null ? const drift.Value.absent() : drift.Value(notes),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lent = widget.lent;
    final color = lent ? AppColors.asset : AppColors.liability;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _saving ? null : () => Navigator.of(context).pop()),
        title: Text(widget.item != null
            ? 'Edit'
            : (!lent
                ? 'Borrowed Money'
                : (_other ? 'Add Asset' : 'Lend Money'))),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: color),
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (lent && widget.item == null) ...[
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'lent', label: Text('Lent to Others')),
                  ButtonSegment(value: 'other', label: Text('Other Assets')),
                ],
                selected: {_kind},
                onSelectionChanged: (v) => setState(() => _kind = v.first),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: _other
                      ? 'Asset name'
                      : (lent ? 'Lent to (name)' : 'Borrowed from (name)'),
                  border: const OutlineInputBorder()),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder()),
              validator: (v) {
                final n = double.tryParse((v ?? '').trim());
                return n == null || n <= 0 ? 'Enter an amount' : null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(1990),
                    lastDate: DateTime(2100));
                if (d != null) setState(() => _date = d);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Date', border: OutlineInputBorder()),
                child: Text(DateFormatter.formatDate(_date)),
              ),
            ),
            if (!_other) ...[
              const SizedBox(height: AppSpacing.md),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? _date,
                      firstDate: DateTime(1990),
                      lastDate: DateTime(2100));
                  if (d != null) setState(() => _endDate = d);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: lent
                        ? 'Expected back by (optional)'
                        : 'To be repaid by (optional)',
                    border: const OutlineInputBorder(),
                    suffixIcon: _endDate == null
                        ? const Icon(Icons.calendar_today_rounded, size: 18)
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _endDate = null)),
                  ),
                  child: Text(_endDate == null
                      ? 'No end date'
                      : DateFormatter.formatDate(_endDate!)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Text('Interest'),
              const SizedBox(height: 6),
              SegmentedButton<String>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 'none', label: Text('None')),
                  ButtonSegment(value: 'monthly', label: Text('% per month')),
                  ButtonSegment(value: 'yearly', label: Text('% per year')),
                ],
                selected: {_interest ? _period : 'none'},
                onSelectionChanged: (v) => setState(() {
                  _interest = v.first != 'none';
                  if (_interest) _period = v.first;
                }),
              ),
              if (_interest) ...[
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _rate,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                      labelText:
                          'Rate (% ${_period == 'monthly' ? 'per month' : 'per year'})',
                      suffixText: '%',
                      border: const OutlineInputBorder()),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    return n == null || n <= 0 ? 'Enter the rate in %' : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: _interestDueDate ?? _date,
                        firstDate: DateTime(1990),
                        lastDate: DateTime(2100));
                    if (d != null) setState(() => _interestDueDate = d);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Interest to be paid on (optional)',
                      border: const OutlineInputBorder(),
                      suffixIcon: _interestDueDate == null
                          ? const Icon(Icons.calendar_today_rounded, size: 18)
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              onPressed: () =>
                                  setState(() => _interestDueDate = null)),
                    ),
                    child: Text(_interestDueDate == null
                        ? 'No reminder date'
                        : DateFormatter.formatDate(_interestDueDate!)),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _dueAmount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Interest amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder()),
                  validator: (v) {
                    if (!_interest) return null;
                    if (_interestDueDate == null) return null;
                    final n = double.tryParse((v ?? '').trim());
                    return n == null || n <= 0
                        ? 'Enter the interest amount'
                        : null;
                  },
                ),
              ],
              const SizedBox(height: 4),
              Text(
                  'Interest is worked out on the amount still outstanding. The end date is only a reminder for you; the record stays open until it is settled.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
    );
  }
}
