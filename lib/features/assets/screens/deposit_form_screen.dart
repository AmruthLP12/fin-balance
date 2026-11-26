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
import '../../../data/assets/deposit_calculator.dart';
import '../../../data/assets/recurring_deposit_service.dart';

class DepositFormScreen extends ConsumerStatefulWidget {
  final bool recurring;
  final FinancialItem? holding;

  const DepositFormScreen({
    super.key,
    required this.recurring,
    this.holding,
  });

  /// Opens the form for one kind of deposit directly.
  static Future<void> show(BuildContext context, {required bool recurring}) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DepositFormScreen(recurring: recurring),
      ));

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
  bool _loadingSchedule = false;
  String? _scheduleLoadError;

  bool get _recurring => widget.recurring;
  int get _tenureMonths {
    final value = int.tryParse(_tenure.text.trim()) ?? 0;
    if (value <= 0) return 1;
    return math.min(value * (_tenureUnit == 'years' ? 12 : 1), 1200);
  }

  DateTime get _maturityDate => _addMonthsClamped(_startDate, _tenureMonths);

  @override
  void initState() {
    super.initState();
    final holding = widget.holding;
    if (holding == null) return;

    _startDate = holding.startDate ?? DateTime.now();
    _rate.text = holding.interestRateBasisPoints == null
        ? ''
        : (holding.interestRateBasisPoints! / 100).toString();
    _bank.text = holding.bankName ?? '';
    _accountHolder.text = holding.accountHolder ?? '';
    _compoundingMonths = holding.depositCompoundingMonths ?? 3;
    _cumulative = holding.depositCumulative ?? true;
    _taxSaving = holding.depositTaxSaving ?? false;
    final tenureMonths = holding.tenureMonths;
    if (tenureMonths != null && tenureMonths > 0) {
      if (tenureMonths % 12 == 0) {
        _tenure.text = '${tenureMonths ~/ 12}';
      } else {
        _tenureUnit = 'months';
        _tenure.text = '$tenureMonths';
      }
    }

    if (_recurring) {
      _loadingSchedule = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchedule());
    } else {
      _amount.text = _rupeesText(holding.initialValuePaise);
    }
  }

  Future<void> _loadSchedule() async {
    try {
      final holding = widget.holding!;
      final schedules = await ref
          .read(recurringTransactionsDaoProvider)
          .getSchedulesByItem(holding.profileId, holding.id);
      final schedule = schedules
          .where((entry) => entry.recurringType == recurringDepositType)
          .firstOrNull;
      if (schedule == null) {
        throw StateError('The recurring deposit schedule is unavailable.');
      }
      if (mounted) {
        setState(() {
          _amount.text = _rupeesText(schedule.amountPaise);
          _loadingSchedule = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _scheduleLoadError = error.toString();
          _loadingSchedule = false;
        });
      }
    }
  }

  String _rupeesText(int paise) =>
      (paise / 100).toStringAsFixed(paise % 100 == 0 ? 0 : 2);

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
    if (_loadingSchedule) return;
    if (_scheduleLoadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Could not load deposit schedule: $_scheduleLoadError')),
      );
      return;
    }
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
      final old = widget.holding;
      final int categoryId;
      if (old != null) {
        categoryId = old.categoryId;
      } else {
        final categories =
            await db.categoriesDao.getCategoriesByClassification('asset');
        final depositCategory = categories
            .where((category) => category.name == 'Fixed & Recurring Deposits')
            .firstOrNull;
        if (depositCategory == null) {
          throw StateError('The deposits category is not available.');
        }
        categoryId = depositCategory.id;
      }

      final kind = _recurring ? 'Recurring Deposit' : 'Fixed Deposit';
      final bank = _bank.text.trim();
      final name = bank.isEmpty ? kind : '$bank $kind';
      await db.transaction(() async {
        if (old != null) {
          await _updateExistingDeposit(
            db: db,
            old: old,
            categoryId: categoryId,
            name: name,
            amountPaise: amountPaise,
            rate: rate,
            startDate: startDate,
            maturityDate: maturityDate,
            bank: bank,
          );
          return;
        }

        final itemId = await db.into(db.financialItems).insert(
              FinancialItemsCompanion(
                profileId: drift.Value(ref.read(activeProfileIdProvider)),
                name: drift.Value(name),
                itemType: const drift.Value('asset'),
                subType: drift.Value(
                    _recurring ? 'recurring_deposit' : 'fixed_deposit'),
                categoryId: drift.Value(categoryId),
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
              categoryId: drift.Value(categoryId),
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
              categoryId: drift.Value(categoryId),
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
                categoryId: drift.Value(categoryId),
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
        Navigator.of(context).pop(true);
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

  Future<void> _updateExistingDeposit({
    required AppDatabase db,
    required FinancialItem old,
    required int categoryId,
    required String name,
    required int amountPaise,
    required double rate,
    required DateTime startDate,
    required DateTime maturityDate,
    required String bank,
  }) async {
    final schedules = await db.recurringTransactionsDao
        .getSchedulesByItem(old.profileId, old.id);
    final holder = _accountHolder.text.trim();
    await db.financialItemsDao.updateItem(old.copyWith(
      name: name,
      initialValuePaise: _recurring ? old.initialValuePaise : amountPaise,
      currentValuationPaise:
          _recurring ? old.currentValuationPaise : amountPaise,
      interestRateBasisPoints: drift.Value((rate * 100).round()),
      startDate: drift.Value(startDate),
      maturityDate: drift.Value(maturityDate),
      tenureMonths: drift.Value(_tenureMonths),
      bankName: drift.Value(bank.isEmpty ? null : bank),
      accountHolder: drift.Value(holder.isEmpty ? null : holder),
      depositCompoundingMonths: drift.Value(_compoundingMonths),
      depositCumulative: drift.Value(_cumulative),
      depositTaxSaving: drift.Value(_taxSaving),
      updatedAt: DateTime.now().toUtc(),
    ));

    if (_recurring) {
      await _updateRecurringSchedule(
        db: db,
        old: old,
        categoryId: categoryId,
        name: name,
        amountPaise: amountPaise,
        startDate: startDate,
        maturityDate: maturityDate,
        schedules: schedules,
      );
      return;
    }

    final opening =
        (await db.transactionsDao.getTransactionsByItem(old.profileId, old.id))
            .where((transaction) =>
                transaction.transactionType == 'investment_purchase' &&
                transaction.source == 'manual' &&
                (transaction.notes ?? '').startsWith('FD deposit · '))
            .firstOrNull;
    if (opening == null) {
      await db.transactionsDao.insertTransaction(TransactionsCompanion(
        profileId: drift.Value(old.profileId),
        transactionType: const drift.Value('investment_purchase'),
        categoryId: drift.Value(categoryId),
        financialItemId: drift.Value(old.id),
        transactionDate: drift.Value(startDate),
        amountPaise: drift.Value(amountPaise),
        netAmountPaise: drift.Value(amountPaise),
        source: const drift.Value('manual'),
        notes: drift.Value('FD deposit · $name'),
      ));
    } else {
      await db.transactionsDao.updateTransaction(opening.copyWith(
        transactionDate: startDate,
        amountPaise: amountPaise,
        netAmountPaise: drift.Value(amountPaise),
        notes: drift.Value('FD deposit · $name'),
        updatedAt: DateTime.now().toUtc(),
      ));
    }
    await _updateInterestSchedule(
      db: db,
      old: old,
      categoryId: categoryId,
      name: name,
      rate: rate,
      startDate: startDate,
      maturityDate: maturityDate,
      schedules: schedules,
    );
  }

  Future<void> _updateRecurringSchedule({
    required AppDatabase db,
    required FinancialItem old,
    required int categoryId,
    required String name,
    required int amountPaise,
    required DateTime startDate,
    required DateTime maturityDate,
    required List<RecurringTransaction> schedules,
  }) async {
    final existing = schedules
        .where((schedule) => schedule.recurringType == recurringDepositType)
        .firstOrNull;
    final lastProcessed = existing?.lastProcessedDate;
    final nextDue = lastProcessed == null || lastProcessed.isBefore(startDate)
        ? startDate
        : nextDepositScheduledDate(lastProcessed, startDate.day, 1);
    final completed = !nextDue.isBefore(maturityDate);
    final common = RecurringTransactionsCompanion(
      profileId: drift.Value(old.profileId),
      name: drift.Value(name),
      recurringType: const drift.Value(recurringDepositType),
      financialItemId: drift.Value(old.id),
      categoryId: drift.Value(categoryId),
      amountPaise: drift.Value(amountPaise),
      frequency: const drift.Value('monthly'),
      scheduledDay: drift.Value(startDate.day),
      startDate: drift.Value(startDate),
      endDate: drift.Value(maturityDate),
      nextDueDate: drift.Value(completed ? null : nextDue),
      status: drift.Value(completed ? 'completed' : 'active'),
      notes: drift.Value('RD installment for $name'),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    );
    if (existing == null) {
      await db.recurringTransactionsDao.insertSchedule(common);
    } else {
      await db.recurringTransactionsDao.updateSchedule(
        existing.copyWith(
          name: name,
          amountPaise: amountPaise,
          frequency: 'monthly',
          scheduledDay: startDate.day,
          startDate: startDate,
          endDate: drift.Value(maturityDate),
          nextDueDate: drift.Value(completed ? null : nextDue),
          status: completed ? 'completed' : 'active',
          notes: drift.Value('RD installment for $name'),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  Future<void> _updateInterestSchedule({
    required AppDatabase db,
    required FinancialItem old,
    required int categoryId,
    required String name,
    required double rate,
    required DateTime startDate,
    required DateTime maturityDate,
    required List<RecurringTransaction> schedules,
  }) async {
    final interestSchedules = schedules
        .where((schedule) => schedule.recurringType == fixedDepositInterestType)
        .toList();
    if (_cumulative || rate <= 0) {
      for (final schedule in interestSchedules) {
        await db.recurringTransactionsDao.deleteSchedule(schedule.id);
      }
      return;
    }

    final existing = interestSchedules.firstOrNull;
    final previousLastProcessed = existing?.lastProcessedDate;
    final lastProcessed = previousLastProcessed != null &&
            !previousLastProcessed.isBefore(startDate)
        ? previousLastProcessed
        : null;
    var nextDue = lastProcessed == null
        ? _addMonthsClamped(startDate, _compoundingMonths)
        : nextDepositScheduledDate(
            lastProcessed, startDate.day, _compoundingMonths);
    if (nextDue.isAfter(maturityDate) &&
        (lastProcessed == null || lastProcessed.isBefore(maturityDate))) {
      nextDue = maturityDate;
    }
    final completed =
        lastProcessed != null && !maturityDate.isAfter(lastProcessed);
    final common = RecurringTransactionsCompanion(
      profileId: drift.Value(old.profileId),
      name: drift.Value(name),
      recurringType: const drift.Value(fixedDepositInterestType),
      financialItemId: drift.Value(old.id),
      categoryId: drift.Value(categoryId),
      amountPaise: const drift.Value(0),
      frequency: drift.Value(_frequencyForMonths(_compoundingMonths)),
      scheduledDay: drift.Value(startDate.day),
      startDate: drift.Value(startDate),
      endDate: drift.Value(maturityDate),
      nextDueDate: drift.Value(completed ? null : nextDue),
      status: drift.Value(completed ? 'completed' : 'active'),
      notes: drift.Value('FD interest for $name'),
      updatedAt: drift.Value(DateTime.now().toUtc()),
    );
    if (existing == null) {
      await db.recurringTransactionsDao.insertSchedule(common);
    } else {
      await db.recurringTransactionsDao.updateSchedule(
        existing.copyWith(
          name: name,
          frequency: _frequencyForMonths(_compoundingMonths),
          scheduledDay: startDate.day,
          startDate: startDate,
          endDate: drift.Value(maturityDate),
          nextDueDate: drift.Value(completed ? null : nextDue),
          lastProcessedDate: drift.Value(lastProcessed),
          status: completed ? 'completed' : 'active',
          notes: drift.Value('FD interest for $name'),
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  String _frequencyForMonths(int months) => switch (months) {
        1 => 'monthly',
        3 => 'quarterly',
        6 => 'half_yearly',
        _ => 'yearly',
      };

  @override
  Widget build(BuildContext context) {
    final estimate = estimateDeposit(
      installmentRupees: double.tryParse(_amount.text.trim()) ?? 0,
      rateBasisPoints:
          ((double.tryParse(_rate.text.trim()) ?? 0) * 100).round(),
      tenureMonths: _tenureMonths,
      compoundingMonths: _compoundingMonths,
      recurring: _recurring,
      cumulative: _cumulative,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
            '${widget.holding == null ? 'Add' : 'Edit'} ${_recurring ? 'Recurring' : 'Fixed'} Deposit'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton(
              onPressed: _saving || _loadingSchedule ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (_scheduleLoadError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  'Could not load this recurring deposit: $_scheduleLoadError',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Maturity date: ${DateFormatter.formatDate(_maturityDate)}',
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                'Estimated interest: ${CurrencyFormatter.formatPaise(estimate.interestPaise)} · '
                'Maturity amount: ${CurrencyFormatter.formatPaise(estimate.maturityPaise)}',
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
                      DropdownMenuItem(value: 'years', child: Text('Years')),
                      DropdownMenuItem(value: 'months', child: Text('Months')),
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
          ],
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
