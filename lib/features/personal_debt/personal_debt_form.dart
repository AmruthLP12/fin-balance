import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/formatting/date_formatter.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../database/precision/financial_precision.dart';

/// Simple form for money you lent to someone or borrowed from someone:
/// who, how much, when, and an optional interest rate. No EMI, no tenure.
class PersonalDebtForm extends ConsumerStatefulWidget {
  final bool lent;
  const PersonalDebtForm({super.key, required this.lent});

  static Future<void> show(BuildContext context, {required bool lent}) =>
      Navigator.of(context).push<void>(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => PersonalDebtForm(lent: lent)));

  @override
  ConsumerState<PersonalDebtForm> createState() => _PersonalDebtFormState();
}

class _PersonalDebtFormState extends ConsumerState<PersonalDebtForm> {
  final _key = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _amount = TextEditingController();
  final _rate = TextEditingController();
  final _notes = TextEditingController();
  String _period = 'monthly';
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _person.dispose();
    _amount.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final rate = double.tryParse(_rate.text.trim());
      await ref.read(transactionsDaoProvider).openPersonalDebt(
            profileId: ref.read(activeProfileIdProvider),
            lent: widget.lent,
            person: _person.text.trim(),
            amountPaise: FinancialPrecision.rupeesToPaise(
                double.parse(_amount.text.trim())),
            date: DateTime(_date.year, _date.month, _date.day),
            rateBasisPoints:
                rate == null || rate <= 0 ? null : (rate * 100).round(),
            ratePeriod: _period,
            notes: _notes.text,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not save: $e')));
      }
    }
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
        title: Text(lent ? 'Lend Money' : 'Borrowed Money'),
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
            TextFormField(
              controller: _person,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                  labelText: lent ? 'Lent to (name)' : 'Borrowed from (name)',
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
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rate,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                        labelText: 'Interest (optional)',
                        suffixText: '%',
                        border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                DropdownButton<String>(
                  value: _period,
                  items: const [
                    DropdownMenuItem(
                        value: 'monthly', child: Text('per month')),
                    DropdownMenuItem(value: 'yearly', child: Text('per year')),
                  ],
                  onChanged: (v) => setState(() => _period = v ?? _period),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                lent
                    ? 'Leave interest empty for a plain record. With interest, it is worked out on the amount still outstanding. There is no end date: record interest and part payments whenever they happen.'
                    : 'Leave interest empty for a plain record. With interest, it is worked out on the amount still outstanding. There is no end date: record interest and part payments whenever you pay.',
                style: Theme.of(context).textTheme.bodySmall),
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
