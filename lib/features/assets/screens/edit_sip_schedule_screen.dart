import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/scheduling/investment_schedule_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen dedicated page for editing / revising an existing SIP investment schedule.
/// Preserves confirmed historical transactions, past units, and historical NAVs while
/// setting new installment amount, frequency, and remaining installments from an effective date.
class EditSipScheduleScreen extends ConsumerStatefulWidget {
  final SipPlan sip;

  const EditSipScheduleScreen({super.key, required this.sip});

  static Future<bool?> push(BuildContext context, SipPlan sip) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditSipScheduleScreen(sip: sip),
      ),
    );
  }

  @override
  ConsumerState<EditSipScheduleScreen> createState() =>
      _EditSipScheduleScreenState();
}

class _EditSipScheduleScreenState extends ConsumerState<EditSipScheduleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _installmentsController;
  late TextEditingController _notesController;

  late DateTime _effectiveFrom;
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _effectiveFrom = DateTime(now.year, now.month, now.day);

    _amountController = TextEditingController(text: '1000');
    _installmentsController = TextEditingController(text: '12');
    _notesController = TextEditingController(text: widget.sip.notes ?? '');

    _loadExistingPeriod();
  }

  Future<void> _loadExistingPeriod() async {
    final sipsDao = ref.read(sipsDaoProvider);
    final periods = await sipsDao.getSchedulePeriods(widget.sip.id);
    if (periods.isNotEmpty && mounted) {
      final activePeriod = periods.last;
      setState(() {
        _amountController.text =
            FinancialPrecision.paiseToRupees(activePeriod.amountPaise)
                .toStringAsFixed(0);
        _frequency = ScheduleFrequency.fromString(activePeriod.frequency);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectEffectiveDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _effectiveFrom,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && mounted) {
      setState(() => _effectiveFrom = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final amountRupees = double.parse(_amountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final installmentsCount = _frequency == ScheduleFrequency.oneTime
          ? 1
          : (int.tryParse(_installmentsController.text.trim()) ?? 12);

      final sipsDao = ref.read(sipsDaoProvider);
      final deductionDay = _effectiveFrom.day.clamp(1, 31);

      await sipsDao.addSchedulePeriod(
        sipPlanId: widget.sip.id,
        effectiveFrom: _effectiveFrom,
        amountPaise: amountPaise,
        deductionDay: deductionDay,
        frequency: _frequency.name,
        installmentCount: installmentsCount,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        generateFutureInstallments: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('SIP schedule period updated successfully.'),
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating schedule: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final periodsAsync = ref.watch(sipPeriodsProvider(widget.sip.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit SIP Schedule'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Plan header card
                    FinCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.sip.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: widget.sip.status.toUpperCase(),
                                type:
                                    widget.sip.status.toLowerCase() == 'active'
                                        ? BadgeType.asset
                                        : BadgeType.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scheme Code: ${widget.sip.schemeCode} • First Initiated: ${DateFormatter.formatDate(widget.sip.startDate)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Existing Periods summary card
                    periodsAsync.when(
                      data: (periods) {
                        if (periods.isEmpty) return const SizedBox.shrink();
                        return FinCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule History (${periods.length} period(s))',
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              ...periods.map((p) {
                                final isSuperseded = p.status == 'superseded';
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${DateFormatter.formatDate(p.effectiveFrom)}${p.effectiveTo != null ? ' - ${DateFormatter.formatDate(p.effectiveTo!)}' : ' - Ongoing'}',
                                        style: AppTypography.bodySmall,
                                      ),
                                      Text(
                                        '${CurrencyFormatter.formatPaise(p.amountPaise)} / ${p.frequency}',
                                        style: AppTypography.bodySmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: isSuperseded
                                              ? (isDark
                                                  ? AppColors.darkTextMuted
                                                  : AppColors.lightTextMuted)
                                              : AppColors.asset,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Informational guarantee
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 20,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Historical confirmed installments and units remain unchanged. The new amount and settings take effect from the chosen effective date.',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Effective Date Selector
                    Text(
                      'Effective Start Date of Revised Schedule',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: _selectEffectiveDate,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormatter.formatDate(_effectiveFrom),
                              style: AppTypography.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // New Installment Amount
                    Text(
                      'Revised Amount per Installment (₹)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 1000',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter installment amount';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return 'Must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // First Scheduled Deduction (Derived from Effective Date)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded,
                              size: 20, color: AppColors.brandPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'First Scheduled Deduction: ${DateFormatter.formatDate(_effectiveFrom)}',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Frequency Selector (All 8 options)
                    Text(
                      'Frequency',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<ScheduleFrequency>(
                      initialValue: _frequency,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: ScheduleFrequency.values
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.label),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _frequency = val;
                            if (val == ScheduleFrequency.oneTime) {
                              _installmentsController.text = '1';
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Remaining Installments
                    Text(
                      'Number of Remaining Installments',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      enabled: _frequency != ScheduleFrequency.oneTime,
                      decoration: InputDecoration(
                        hintText: _frequency == ScheduleFrequency.oneTime
                            ? '1'
                            : 'e.g. 12, 24, 60',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (_frequency == ScheduleFrequency.oneTime) {
                          return null;
                        }
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter remaining installments';
                        }
                        final n = int.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return 'Must be at least 1 installment';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Notes
                    Text(
                      'Revision Notes / Reason (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Annual SIP step-up by ₹500',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Update Schedule Period'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
