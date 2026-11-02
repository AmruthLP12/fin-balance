import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Dialog to add a new schedule period to an existing SIP, enabling flexible step-up, step-down,
/// and deduction day changes over time without manual installment recreation.
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
  late TextEditingController _dayController;
  late TextEditingController _notesController;
  DateTime _effectiveFrom = DateTime.utc(
    DateTime.now().year,
    DateTime.now().month + 1,
    1,
  );
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _dayController = TextEditingController(text: '5');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _dayController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 480),
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
                      Text(
                        'Change SIP Schedule',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
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
                    'Step-up amount or change deduction day seamlessly. FinBalance archives the current period and starts the new period on the effective date.',
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
                              'Current: ${CurrencyFormatter.formatPaise(current.amountPaise)} / mo on day ${current.deductionDay}',
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
                    title: const Text('Effective From Date'),
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
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) {
                        setState(() => _effectiveFrom = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // New Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'New Monthly Investment (₹)',
                      hintText: 'e.g. 5000',
                      prefixText: '₹ ',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter monthly amount';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n <= 0) {
                        return 'Enter a valid amount greater than 0';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // New Deduction Day Input (1-31)
                  TextFormField(
                    controller: _dayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'New Deduction Day of Month (1 - 31)',
                      hintText: 'e.g. 5 or 31',
                      helperText:
                          'Clamped safely on shorter months (e.g. 31st becomes 28th/29th Feb) without drift.',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter day of month';
                      }
                      final day = int.tryParse(val.trim());
                      if (day == null || day < 1 || day > 31) {
                        return 'Day must be between 1 and 31';
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
                      hintText: 'e.g. Annual Step-up +10%, Salary increment',
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
                        onPressed: _isSaving ? null : _saveNewPeriod,
                        child: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Apply New Schedule'),
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

  Future<void> _saveNewPeriod() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final amountDouble = double.parse(_amountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountDouble);
      final deductionDay = int.parse(_dayController.text.trim());
      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      final sipsDao = ref.read(sipsDaoProvider);
      await sipsDao.addSchedulePeriod(
        sipPlanId: widget.sip.id,
        effectiveFrom: _effectiveFrom,
        amountPaise: amountPaise,
        deductionDay: deductionDay,
        notes: notes,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New SIP schedule period activated!'),
            backgroundColor: AppColors.asset,
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
