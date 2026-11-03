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
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Dedicated full-screen page to Add a New SWP (Systematic Withdrawal Plan) Schedule Period under an existing holding.
class AddSwpSchedulePeriodScreen extends ConsumerStatefulWidget {
  final FinancialItem holding;
  final SwpPlan? existingSwp;

  const AddSwpSchedulePeriodScreen({
    super.key,
    required this.holding,
    this.existingSwp,
  });

  static Future<bool?> push(
    BuildContext context, {
    required FinancialItem holding,
    SwpPlan? existingSwp,
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSwpSchedulePeriodScreen(
          holding: holding,
          existingSwp: existingSwp,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddSwpSchedulePeriodScreen> createState() =>
      _AddSwpSchedulePeriodScreenState();
}

class _AddSwpSchedulePeriodScreenState
    extends ConsumerState<AddSwpSchedulePeriodScreen> {
  final _formKey = GlobalKey<FormState>();

  String _withdrawalMode = 'amount'; // 'amount' or 'units'
  late TextEditingController _amountController;
  late TextEditingController _unitsController;
  late TextEditingController _installmentsController;
  late TextEditingController _notesController;

  late DateTime _startDate;
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);

    _amountController = TextEditingController(text: '1000');
    _unitsController = TextEditingController(text: '10.0000');
    _installmentsController = TextEditingController(text: '12');
    _notesController = TextEditingController();

    if (widget.existingSwp != null) {
      _withdrawalMode = widget.existingSwp!.withdrawalMode;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
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
      final isAmount = _withdrawalMode == 'amount';
      int? amountPaise;
      int? unitsMicro;

      if (isAmount) {
        final amtRupees = double.parse(_amountController.text.trim());
        amountPaise = FinancialPrecision.rupeesToPaise(amtRupees);
      } else {
        final units = double.parse(_unitsController.text.trim());
        unitsMicro = FinancialPrecision.unitsToMicroUnits(units);
      }

      final installmentsCount = _frequency == ScheduleFrequency.oneTime
          ? 1
          : (int.tryParse(_installmentsController.text.trim()) ?? 12);

      final swpsDao = ref.read(swpsDaoProvider);
      final schemeCode = int.tryParse(widget.holding.externalCode ?? '') ?? 0;
      final deductionDay = _startDate.day.clamp(1, 31);

      if (widget.existingSwp != null) {
        await swpsDao.addSchedulePeriod(
          swpPlanId: widget.existingSwp!.id,
          effectiveFrom: _startDate,
          withdrawalMode: _withdrawalMode,
          amountPaise: amountPaise,
          unitsMicroUnits: unitsMicro,
          deductionDay: deductionDay,
          frequency: _frequency.name,
          installmentCount: installmentsCount,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          generateFutureInstallments: true,
        );
      } else {
        await swpsDao.createSwpWithPeriod(
          profileId: widget.holding.profileId,
          schemeCode: schemeCode,
          name: '${widget.holding.name} (SWP)',
          withdrawalMode: _withdrawalMode,
          startDate: _startDate,
          amountPaise: amountPaise,
          unitsMicroUnits: unitsMicro,
          deductionDay: deductionDay,
          frequency: _frequency.name,
          installmentCount: installmentsCount,
          financialItemId: widget.holding.id,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          generateInstallments: true,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('SWP schedule period saved successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving SWP schedule: $e'),
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
    final availableUnits = FinancialPrecision.microUnitsToUnits(
        widget.holding.unitCountMicroUnits);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingSwp != null
            ? 'Add SWP Schedule Period'
            : 'Set Up SWP Schedule'),
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
                            'Units available in holding: ${availableUnits.toStringAsFixed(4)} (${CurrencyFormatter.formatPaise(widget.holding.currentValuationPaise)} valuation)',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Note: Planning future SWP withdrawals does not reduce units held. Units will only be deducted when actual withdrawals are confirmed.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.brandPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Withdrawal Mode Selector
                    Text(
                      'Withdrawal Mode',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'amount',
                          label: Text('Fixed Amount (₹)'),
                          icon: Icon(Icons.currency_rupee_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'units',
                          label: Text('Fixed Units'),
                          icon: Icon(Icons.pie_chart_outline_rounded, size: 16),
                        ),
                      ],
                      selected: {_withdrawalMode},
                      onSelectionChanged: (set) {
                        setState(() => _withdrawalMode = set.first);
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Amount or Units input field
                    if (_withdrawalMode == 'amount') ...[
                      Text(
                        'Withdrawal Amount per Installment (₹)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          hintText: 'e.g. 5000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter withdrawal amount';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      Text(
                        'Withdrawal Units per Installment',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _unitsController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 25.5000',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter units to withdraw';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),

                    // Start / Effective Date
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

                    // First Scheduled Deduction / Withdrawal banner
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
                              'First Scheduled Withdrawal: ${DateFormatter.formatDate(_startDate)}',
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

                    // Frequency Dropdown (8 standardized options)
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

                    // Number of Installments (Mandatory configuration)
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
                          return 'Enter number of installments';
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
                      'Remarks (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Monthly living expenses withdrawal',
                        border: OutlineInputBorder(),
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

