import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import '../../../data/assets/recurring_deposit_service.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  final bool recurring;

  const DepositFormScreen({super.key, required this.recurring});

  static Future<void> showTypePicker(BuildContext context) async {
    final recurring = await showModalBottomSheet<bool>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.savings_outlined),
              title: const Text('Fixed Deposit (FD)'),
              onTap: () => Navigator.pop(sheetContext, false),
            ),
            ListTile(
              leading: const Icon(Icons.event_repeat_rounded),
              title: const Text('Recurring Deposit (RD)'),
              onTap: () => Navigator.pop(sheetContext, true),
            ),
          ],
        ),
      ),
    );
    if (recurring != null && context.mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => DepositFormScreen(recurring: recurring),
        ),
      );
    }
  }

  @override
  ConsumerState<DepositFormScreen> createState() => _DepositFormScreenState();
}

class _DepositFormScreenState extends ConsumerState<DepositFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _tenure = TextEditingController(text: '5');
  final _bank = TextEditingController();
  final _accountHolder = TextEditingController();

  DateTime _startDate = DateTime.now();
  String _tenureUnit = 'years';
  int _compoundingMonths = 3;
  bool _cumulative = true;
  bool _taxSaving = false;
  bool _saving = false;

  bool get _recurring => widget.recurring;
  int get _tenureMonths {
    final value = int.tryParse(_tenure.text.trim()) ?? 0;
    if (value <= 0) return 1;
    return math.min(value * (_tenureUnit == 'years' ? 12 : 1), 1200);
  }

  DateTime get _maturityDate => _addMonthsClamped(_startDate, _tenureMonths);

  @override
  void dispose() {
    _amount.dispose();
    _rate.dispose();
    _tenure.dispose();
    _bank.dispose();
    _accountHolder.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final amountPaise =
          FinancialPrecision.rupeesToPaise(double.parse(_amount.text.trim()));
      final rate = double.tryParse(_rate.text.trim()) ?? 0;
      final startDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day);
      final maturityDate = _addMonthsClamped(startDate, _tenureMonths);
      final categories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final depositCategory = categories
          .where((category) => category.name == 'Fixed & Recurring Deposits')
          .firstOrNull;
      if (depositCategory == null) {
        throw StateError('The deposits category is not available.');
      }

      final kind = _recurring ? 'Recurring Deposit' : 'Fixed Deposit';
      final bank = _bank.text.trim();
      final name = bank.isEmpty ? kind : '$bank $kind';
      await db.transaction(() async {
        final itemId = await db.into(db.financialItems).insert(
              FinancialItemsCompanion(
                profileId: drift.Value(ref.read(activeProfileIdProvider)),
                name: drift.Value(name),
                itemType: const drift.Value('asset'),
                subType: drift.Value(
                    _recurring ? 'recurring_deposit' : 'fixed_deposit'),
                categoryId: drift.Value(depositCategory.id),
                initialValuePaise: drift.Value(_recurring ? 0 : amountPaise),
                currentValuationPaise:
                    drift.Value(_recurring ? 0 : amountPaise),
                interestRateBasisPoints: drift.Value((rate * 100).round()),
                startDate: drift.Value(startDate),
                maturityDate: drift.Value(maturityDate),
                tenureMonths: drift.Value(_tenureMonths),
                bankName: drift.Value(bank.isEmpty ? null : bank),
                accountHolder: drift.Value(
                  _accountHolder.text.trim().isEmpty
                      ? null
                      : _accountHolder.text.trim(),
                ),
                depositCompoundingMonths: drift.Value(_compoundingMonths),
                depositCumulative: drift.Value(_cumulative),
                depositTaxSaving: drift.Value(_taxSaving),
              ),
            );

        if (_recurring) {
          await db.recurringTransactionsDao.insertSchedule(
            RecurringTransactionsCompanion(
              profileId: drift.Value(ref.read(activeProfileIdProvider)),
              name: drift.Value(name),
              recurringType: const drift.Value(recurringDepositType),
              financialItemId: drift.Value(itemId),
              categoryId: drift.Value(depositCategory.id),
              amountPaise: drift.Value(amountPaise),
              frequency: const drift.Value('monthly'),
              scheduledDay: drift.Value(startDate.day),
              startDate: drift.Value(startDate),
              endDate: drift.Value(maturityDate),
              nextDueDate: drift.Value(startDate),
              notes: drift.Value('RD installment for $name'),
            ),
          );
        } else {
          await db.transactionsDao.insertTransaction(
            TransactionsCompanion(
              profileId: drift.Value(ref.read(activeProfileIdProvider)),
              transactionType: const drift.Value('investment_purchase'),
              categoryId: drift.Value(depositCategory.id),
              financialItemId: drift.Value(itemId),
              transactionDate: drift.Value(startDate),
              amountPaise: drift.Value(amountPaise),
              netAmountPaise: drift.Value(amountPaise),
              source: const drift.Value('manual'),
              notes: drift.Value('FD deposit · $name'),
            ),
          );
          if (!_cumulative && rate > 0) {
            final nextInterestDate =
                _addMonthsClamped(startDate, _compoundingMonths);
            await db.recurringTransactionsDao.insertSchedule(
              RecurringTransactionsCompanion(
                profileId: drift.Value(ref.read(activeProfileIdProvider)),
                name: drift.Value(name),
                recurringType: const drift.Value(fixedDepositInterestType),
                financialItemId: drift.Value(itemId),
                categoryId: drift.Value(depositCategory.id),
                amountPaise: const drift.Value(0),
                frequency: drift.Value(switch (_compoundingMonths) {
                  1 => 'monthly',
                  3 => 'quarterly',
                  6 => 'half_yearly',
                  _ => 'yearly',
                }),
                scheduledDay: drift.Value(startDate.day),
                startDate: drift.Value(startDate),
                endDate: drift.Value(maturityDate),
                nextDueDate: drift.Value(
                  nextInterestDate.isAfter(maturityDate)
                      ? maturityDate
                      : nextInterestDate,
                ),
                notes: drift.Value('FD interest for $name'),
              ),
            );
          }
        }
      });

      String? postingError;
      if (_recurring || (!_cumulative && rate > 0)) {
        try {
          await applyDueDepositTransactions(db);
        } catch (e) {
          postingError = e.toString();
        }
      }
      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        if (postingError != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                  'Deposit saved, but due transactions could not be posted: $postingError'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not save deposit: $e')));
      }
    }
  }

  int _estimatedMaturityPaise() {
    final principal = double.tryParse(_amount.text.trim()) ?? 0;
    final annualRate = (double.tryParse(_rate.text.trim()) ?? 0) / 100;
    if (principal <= 0 || _tenureMonths <= 0) return 0;
    final periodsPerYear = 12 / _compoundingMonths;
    final periodRate = annualRate / periodsPerYear;
    final double estimate;
    if (_recurring) {
      estimate = List<int>.generate(_tenureMonths, (i) => i).fold<double>(
        0,
        (sum, i) =>
            sum +
            principal *
                math.pow(
                  1 + periodRate,
                  (_tenureMonths - i) / _compoundingMonths,
                ),
      );
    } else if (_cumulative) {
      estimate = principal *
          math.pow(
            1 + periodRate,
            _tenureMonths / _compoundingMonths,
          );
    } else {
      estimate = principal * (1 + annualRate * _tenureMonths / 12);
    }
    final paise = estimate * 100;
    if (!paise.isFinite || paise >= (1 << 62)) return 1 << 62;
    return paise.round();
  }

  int _contributedPaise() {
    final principal = double.tryParse(_amount.text.trim()) ?? 0;
    final paise = principal * 100 * (_recurring ? _tenureMonths : 1);
    if (!paise.isFinite || paise >= (1 << 62)) return 1 << 62;
    return paise.round();
  }

  @override
  Widget build(BuildContext context) {
    final amountPaise = _estimatedMaturityPaise();
    final contributedPaise = _contributedPaise();
    final interestPaise = (amountPaise - contributedPaise).clamp(0, 1 << 62);
    final maturityValuePaise =
        !_recurring && !_cumulative ? contributedPaise : amountPaise;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text('Add ${_recurring ? 'Recurring' : 'Fixed'} Deposit'),
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded),
            tooltip: 'Save deposit',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.edit_calendar_rounded),
                      ),
                      child: Text(DateFormatter.formatDate(_startDate)),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'Matures on: ${DateFormatter.formatDate(_maturityDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _amount,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: _recurring ? 'Monthly installment' : 'Amount',
                      prefixText: '₹ ',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      final n = double.tryParse((value ?? '').trim());
                      final maxRupees =
                          (1 << 62) / (100 * (_recurring ? _tenureMonths : 1));
                      if (n == null || !n.isFinite || n <= 0) {
                        return 'Enter an amount above zero';
                      }
                      return n > maxRupees
                          ? 'Amount is too large for this tenure'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rate,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Rate of Interest (% p.a.)',
                            suffixText: '%',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final n = double.tryParse((value ?? '').trim());
                            return n == null || !n.isFinite || n < 0 || n > 100
                                ? 'Enter a rate from 0 to 100'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: _compoundingMonths,
                          decoration: const InputDecoration(
                            labelText: 'Compounding period',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('Monthly')),
                            DropdownMenuItem(value: 3, child: Text('3 Months')),
                            DropdownMenuItem(value: 6, child: Text('6 Months')),
                            DropdownMenuItem(value: 12, child: Text('Yearly')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _compoundingMonths = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text(
                      'Estimated interest: ${CurrencyFormatter.formatPaise(interestPaise)} · '
                      'Maturity value: ${CurrencyFormatter.formatPaise(maturityValuePaise)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!_recurring)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Cumulative Deposit'),
                      value: _cumulative,
                      onChanged: (value) =>
                          setState(() => _cumulative = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _tenure,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Tenure',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            final n = int.tryParse((value ?? '').trim());
                            return n == null ||
                                    n <= 0 ||
                                    n * (_tenureUnit == 'years' ? 12 : 1) > 1200
                                ? 'Enter a tenure from 1 to 1200 months'
                                : null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _tenureUnit,
                          decoration: const InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'years', child: Text('Years')),
                            DropdownMenuItem(
                                value: 'months', child: Text('Months')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _tenureUnit = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (!_recurring)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Tax saving u/s 80C'),
                      value: _taxSaving,
                      onChanged: (value) =>
                          setState(() => _taxSaving = value ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _bank,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Bank',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _accountHolder,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Account holder',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.check_rounded),
                    label: Text(_saving ? 'Saving...' : 'Save Deposit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

DateTime _addMonthsClamped(DateTime date, int months) {
  final totalMonths = date.year * 12 + date.month - 1 + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, math.min(date.day, lastDay));
}
