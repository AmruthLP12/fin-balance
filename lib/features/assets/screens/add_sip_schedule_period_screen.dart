import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/scheduling/investment_schedule_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Dedicated full-screen page to Add a New SIP Schedule Period under an existing holding.
///
/// If an active schedule exists, allows setting its closing date and smoothly transitioning
/// to the new schedule period with revised amount, frequency, and installments.
/// If no SIP plan exists yet for this holding, creates the initial master SIP attached to the holding.
class AddSipSchedulePeriodScreen extends ConsumerStatefulWidget {
  final FinancialItem holding;
  final SipPlan? existingSip;

  const AddSipSchedulePeriodScreen({
    super.key,
    required this.holding,
    this.existingSip,
  });

  static Future<bool?> push(
    BuildContext context, {
    required FinancialItem holding,
    SipPlan? existingSip,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSipSchedulePeriodScreen(
          holding: holding,
          existingSip: existingSip,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddSipSchedulePeriodScreen> createState() =>
      _AddSipSchedulePeriodScreenState();
}

class _AddSipSchedulePeriodScreenState
    extends ConsumerState<AddSipSchedulePeriodScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _installmentsController;
  late TextEditingController _notesController;

  late DateTime _startDate;
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  int _deductionDay = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _deductionDay = now.day.clamp(1, 28);

    _amountController = TextEditingController(text: '1000');
    _installmentsController = TextEditingController(text: '12');
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final amountRupees = double.parse(_amountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final installmentsCount =
          int.tryParse(_installmentsController.text.trim()) ?? 12;

      DateTime? endDate;
      if (installmentsCount > 0) {
        if (_frequency == ScheduleFrequency.monthly) {
          endDate = DateTime(
            _startDate.year,
            _startDate.month + installmentsCount,
            _startDate.day,
          );
        } else if (_frequency == ScheduleFrequency.quarterly) {
          endDate = DateTime(
            _startDate.year,
            _startDate.month + (installmentsCount * 3),
            _startDate.day,
          );
        }
      }

      final sipsDao = ref.read(sipsDaoProvider);
      final schemeCode = int.tryParse(widget.holding.externalCode ?? '') ?? 0;

      if (widget.existingSip != null) {
        // Add new schedule period to existing master SIP
        await sipsDao.addSchedulePeriod(
          sipPlanId: widget.existingSip!.id,
          effectiveFrom: _startDate,
          effectiveTo: endDate,
          amountPaise: amountPaise,
          deductionDay: _deductionDay,
          frequency: _frequency == ScheduleFrequency.quarterly
              ? 'quarterly'
              : 'monthly',
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          generateFutureInstallments: true,
        );
      } else {
        // Create initial master SIP linked to holding
        await sipsDao.createSipWithPeriod(
          profileId: widget.holding.profileId,
          schemeCode: schemeCode,
          name: '${widget.holding.name} (SIP)',
          startDate: _startDate,
          endDate: endDate,
          amountPaise: amountPaise,
          deductionDay: _deductionDay,
          frequency: _frequency == ScheduleFrequency.quarterly
              ? 'quarterly'
              : 'monthly',
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          financialItemId: widget.holding.id,
          generateInstallments: true,
          isSimulated: true,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('New SIP schedule created successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving SIP schedule: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add SIP Schedule Period'),
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
                    FinCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.holding.name,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.existingSip != null
                                ? 'Adding a new schedule period under SIP "${widget.existingSip!.name}". The previous period will end before the new start date.'
                                : 'Initiating a new recurring SIP schedule linked to this holding.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Effective Start Date
                    Text(
                      'Schedule Start / Effective Date',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: _selectStartDate,
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
                              DateFormatter.formatDate(_startDate),
                              style: AppTypography.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Installment Amount
                    Text(
                      'Installment Amount (₹)',
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

                    // Frequency
                    Text(
                      'Frequency',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<ScheduleFrequency>(
                      segments: const [
                        ButtonSegment(
                          value: ScheduleFrequency.monthly,
                          label: Text('Monthly'),
                        ),
                        ButtonSegment(
                          value: ScheduleFrequency.quarterly,
                          label: Text('Quarterly'),
                        ),
                      ],
                      selected: {_frequency},
                      onSelectionChanged: (set) {
                        setState(() => _frequency = set.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Deduction Day
                    Text(
                      'Deduction Day of Month (1 - 28)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<int>(
                      initialValue: _deductionDay,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items: List.generate(
                        28,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text('${i + 1} of every month'),
                        ),
                      ),
                      onChanged: (val) {
                        if (val != null) setState(() => _deductionDay = val);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Number of Installments
                    Text(
                      'Number of Installments',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _installmentsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 12, 24, 60',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter number of installments';
                        }
                        final n = int.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return 'Must be at least 1';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Notes
                    Text(
                      'Schedule Remarks / Reason (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Started new monthly contribution',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Schedule Period'),
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
