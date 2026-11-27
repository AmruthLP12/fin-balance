import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/assets/deposit_calculator.dart' show addMonthsClamped;
import '../../data/assets/recurring_deposit_service.dart';
import '../../database/app_database.dart';
import '../../database/precision/financial_precision.dart';

/// Add or edit a PPF / SSS account. Deposits, voluntary deposits and interest
/// are entered afterwards on the account's details screen.
class SavingsFormScreen extends ConsumerStatefulWidget {
  final String subType; // 'ppf' or 'sss'
  final FinancialItem? item;
  const SavingsFormScreen({super.key, required this.subType, this.item});

  static Future<void> show(BuildContext context,
          {required String subType, FinancialItem? item}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => SavingsFormScreen(subType: subType, item: item)));

  @override
  ConsumerState<SavingsFormScreen> createState() => _SavingsFormScreenState();
}

class _SavingsFormScreenState extends ConsumerState<SavingsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _opening = TextEditingController();
  final _deduction = TextEditingController();
  final _notes = TextEditingController();
  DateTime _openedOn = DateTime.now();
  DateTime? _maturity;
  bool _maturityTouched = false;
  bool _deduct = false;
  bool _sameAsOpening = false;
  DateTime _nextDeduction = addMonthsClamped(DateTime.now(), 1);
  bool _saving = false;

  bool get _editing => widget.item != null;
  String get _label => widget.subType.toUpperCase();
  // PPF runs 15 years, Sukanya Samriddhi 21 years from opening.
  int get _years => widget.subType == 'ppf' ? 15 : 21;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    if (item == null) {
      _name.text = _label;
      _maturity = addMonthsClamped(_openedOn, _years * 12);
      return;
    }
    _name.text = item.name;
    _bank.text = item.bankName ?? '';
    _notes.text = item.notes ?? '';
    _openedOn = item.startDate ?? DateTime.now();
    _maturity = item.maturityDate;
    _maturityTouched = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDeduction(item));
  }

  Future<void> _loadDeduction(FinancialItem item) async {
    final schedules = await ref
        .read(recurringTransactionsDaoProvider)
        .getSchedulesByItem(item.profileId, item.id);
    final s = schedules
        .where(
            (e) => e.recurringType == 'savings_deposit' && e.status == 'active')
        .firstOrNull;
    if (s == null || !mounted) return;
    setState(() {
      _deduct = true;
      _deduction.text = (s.amountPaise / 100)
          .toStringAsFixed(s.amountPaise % 100 == 0 ? 0 : 2);
      _nextDeduction = s.nextDueDate ?? _nextDeduction;
    });
  }

  @override
  void dispose() {
    for (final c in [_name, _bank, _opening, _deduction, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial, {DateTime? first}) =>
      showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: first ?? DateTime(1990),
          lastDate: DateTime(2100));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final dao = ref.read(transactionsDaoProvider);
      final bank = _bank.text.trim();
      final opening = double.tryParse(_opening.text.trim()) ?? 0;
      final opened = DateTime(_openedOn.year, _openedOn.month, _openedOn.day);
      // "Same as opening": the opening deposit is the first one, so deductions
      // start a month later on the same day with the same amount.
      final same = _deduct && _sameAsOpening && !_editing;
      final deductionPaise = !_deduct
          ? null
          : FinancialPrecision.rupeesToPaise(
              same ? opening : double.parse(_deduction.text.trim()));
      final firstDeduction =
          same ? addMonthsClamped(opened, 1) : _nextDeduction;
      final deductionDay = same ? opened.day : _nextDeduction.day;
      final item = widget.item;
      if (item == null) {
        await dao.openSavingsAccount(
          profileId: ref.read(activeProfileIdProvider),
          subType: widget.subType,
          name: _name.text.trim(),
          openedOn: opened,
          openingPaise: FinancialPrecision.rupeesToPaise(opening),
          bank: bank,
          maturityDate: _maturity,
          notes: _notes.text,
          deductionPaise: deductionPaise,
          nextDeduction: firstDeduction,
          deductionDay: deductionDay,
        );
      } else {
        await ref.read(financialItemsDaoProvider).updateItem(item.copyWith(
              name: _name.text.trim(),
              bankName: drift.Value(bank.isEmpty ? null : bank),
              startDate: drift.Value(_openedOn),
              maturityDate: drift.Value(_maturity),
              notes: drift.Value(
                  _notes.text.trim().isEmpty ? null : _notes.text.trim()),
              updatedAt: DateTime.now().toUtc(),
            ));
        await dao.setSavingsDeduction(
            itemId: item.id,
            amountPaise: deductionPaise,
            nextDate: firstDeduction,
            day: deductionDay);
      }
      // A first deduction in the past is posted for every month up to today.
      await applyDueDepositTransactions(ref.read(databaseProvider));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
  }

  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').trim());
    return n == null || n <= 0 ? 'Enter an amount above zero' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: _saving ? null : () => Navigator.of(context).pop()),
        title: Text('${_editing ? 'Edit' : 'Add'} $_label account'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Account name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v ?? '').trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _bank,
              decoration: const InputDecoration(
                  labelText: 'Bank / post office (optional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_rounded, size: 16),
              label: Text('Opened on ${DateFormatter.formatDate(_openedOn)}'),
              onPressed: () async {
                final d = await _pick(_openedOn);
                if (d == null) return;
                setState(() {
                  _openedOn = d;
                  if (!_maturityTouched) {
                    _maturity = addMonthsClamped(d, _years * 12);
                  }
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            if (!_editing) ...[
              TextFormField(
                controller: _opening,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Amount deposited on that date (optional)',
                    prefixText: '₹ ',
                    border: OutlineInputBorder()),
                validator: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  if (_deduct && _sameAsOpening) {
                    return n == null || n <= 0
                        ? 'Enter the amount to repeat every month'
                        : null;
                  }
                  return (v ?? '').trim().isEmpty || (n ?? -1) >= 0
                      ? null
                      : 'Enter a valid amount';
                },
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_rounded, size: 16),
                    label: Text(_maturity == null
                        ? 'Matures on (optional)'
                        : 'Matures ${DateFormatter.formatDate(_maturity!)}'),
                    onPressed: () async {
                      final d = await _pick(_maturity ?? _openedOn);
                      if (d != null) {
                        setState(() {
                          _maturity = d;
                          _maturityTouched = true;
                        });
                      }
                    },
                  ),
                ),
                if (_maturity != null)
                  IconButton(
                    tooltip: 'Clear maturity date',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      _maturity = null;
                      _maturityTouched = true;
                    }),
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Regular monthly deduction'),
              subtitle: const Text(
                  'Added to the account automatically on that day every month.'),
              value: _deduct,
              onChanged: (v) => setState(() => _deduct = v),
            ),
            if (_deduct) ...[
              if (!_editing)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title:
                      const Text('Same amount and day as the opening deposit'),
                  value: _sameAsOpening,
                  onChanged: (v) => setState(() => _sameAsOpening = v ?? false),
                ),
              if (!_sameAsOpening || _editing) ...[
                TextFormField(
                  controller: _deduction,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Amount deducted each month',
                      prefixText: '₹ ',
                      border: OutlineInputBorder()),
                  validator: _positive,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_repeat_rounded, size: 16),
                  label: Text(
                      '${_editing ? 'Next' : 'First'} deduction ${DateFormatter.formatDate(_nextDeduction)}'),
                  onPressed: () async {
                    final d = await _pick(_nextDeduction);
                    if (d != null) setState(() => _nextDeduction = d);
                  },
                ),
              ],
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                    'Any date works. Deductions from that date up to today are added automatically, then one each month.',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Note (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
