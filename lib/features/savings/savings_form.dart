import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/assets/deposit_calculator.dart' show addMonthsClamped;
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
      final deductionPaise = _deduct
          ? FinancialPrecision.rupeesToPaise(
              double.parse(_deduction.text.trim()))
          : null;
      final item = widget.item;
      if (item == null) {
        final opening = double.tryParse(_opening.text.trim()) ?? 0;
        await dao.openSavingsAccount(
          profileId: ref.read(activeProfileIdProvider),
          subType: widget.subType,
          name: _name.text.trim(),
          openedOn: DateTime(_openedOn.year, _openedOn.month, _openedOn.day),
          openingPaise: FinancialPrecision.rupeesToPaise(opening),
          bank: bank,
          maturityDate: _maturity,
          notes: _notes.text,
          deductionPaise: deductionPaise,
          nextDeduction: _nextDeduction,
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
            nextDate: _nextDeduction);
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
                validator: (v) => (v ?? '').trim().isEmpty ||
                        (double.tryParse(v!.trim()) ?? -1) >= 0
                    ? null
                    : 'Enter a valid amount',
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
                    'Next deduction ${DateFormatter.formatDate(_nextDeduction)}'),
                onPressed: () async {
                  final today = DateTime.now();
                  final d = await _pick(
                      _nextDeduction.isBefore(today) ? today : _nextDeduction,
                      first: DateTime(today.year, today.month, today.day));
                  if (d != null) setState(() => _nextDeduction = d);
                },
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
