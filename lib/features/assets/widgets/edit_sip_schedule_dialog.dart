import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/scheduling/investment_schedule_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Dialog to update an existing investment schedule.
/// Modifies frequency, amount per installment, and remaining installments from an effective date,
/// while strictly preserving past confirmed transactions, units, and historical NAVs.
class EditSipScheduleDialog extends ConsumerStatefulWidget {
  final SipPlan sip;

  const EditSipScheduleDialog({super.key, required this.sip});

  @override
  ConsumerState<EditSipScheduleDialog> createState() =>
      _EditSipScheduleDialogState();
}

class _EditSipScheduleDialogState extends ConsumerState<EditSipScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _remainingInstallmentsController;
  late TextEditingController _notesController;

  late DateTime _effectiveFrom;
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default effective date is tomorrow
    _effectiveFrom = DateTime(now.year, now.month, now.day + 1);

    _amountController = TextEditingController(text: '1000');
    _remainingInstallmentsController = TextEditingController(text: '12');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remainingInstallmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final periodsAsync = ref.watch(sipPeriodsProvider(widget.sip.id));

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Modify Investment Schedule',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Update future installments starting from the chosen effective date. All past confirmed investments, units, and transactions are strictly preserved.',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Current Schedule Info Banner
                  periodsAsync.when(
                    data: (periods) {
                      if (periods.isEmpty) return const SizedBox.shrink();
                      final current = periods.last;
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Current: ${CurrencyFormatter.formatPaise(current.amountPaise)} (${current.frequency})',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Since ${DateFormatter.formatDate(current.effectiveFrom)}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Effective From Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Effective Date'),
                    subtitle: Text(
                      DateFormatter.formatDate(_effectiveFrom),
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.brandPrimaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _effectiveFrom,
                        firstDate: widget.sip.startDate,
                        lastDate: DateTime(2040),
                      );
                      if (picked != null) {
                        setState(() => _effectiveFrom =
                            DateTime(picked.year, picked.month, picked.day));
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // New Frequency
                  DropdownButtonFormField<ScheduleFrequency>(
                    initialValue: _frequency,
                    decoration: const InputDecoration(
                      labelText: 'New Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: ScheduleFrequency.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            ))
                        .toList(),
                    onChanged: (newFreq) {
                      if (newFreq != null) {
                        setState(() => _frequency = newFreq);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // New Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'New Amount per Installment (₹)',
                      hintText: 'e.g. 5000',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter installment amount';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'Enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Remaining Installments Input
                  TextFormField(
                    controller: _remainingInstallmentsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Remaining Installments Count',
                      hintText: 'e.g. 12',
                      border: OutlineInputBorder(),
                      helperText:
                          'Number of new installments to project starting from effective date.',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter remaining installments';
                      }
                      final count = int.tryParse(val.trim());
                      if (count == null || count < 1) {
                        return 'Must be at least 1';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Notes / Reason
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Adjustment (Optional)',
                      hintText: 'e.g. Step-up investment, Salary increment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveScheduleUpdate,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Schedule'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveScheduleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final amountDouble = double.parse(_amountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountDouble);
      final remainingCount =
          int.parse(_remainingInstallmentsController.text.trim());
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      final sipsDao = ref.read(sipsDaoProvider);
      final success = await sipsDao.updateInvestmentSchedule(
        sipPlanId: widget.sip.id,
        effectiveDate: _effectiveFrom,
        newAmountPaise: amountPaise,
        newFrequency: _frequency,
        remainingInstallments: remainingCount,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Investment schedule successfully updated!'
                : 'Failed to update schedule.'),
            backgroundColor: success ? AppColors.asset : AppColors.liability,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update schedule: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
