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
import '../../../data/nav/models/nav_models.dart';
import '../../../database/precision/financial_precision.dart';

/// Modal dialog allowing user to add a mutual fund scheme into an active profile's
/// asset portfolio via an automated investment schedule.
class AddToProfileDialog extends ConsumerStatefulWidget {
  final MutualFundSchemeDetail scheme;
  final int? preselectedProfileId;

  const AddToProfileDialog({
    super.key,
    required this.scheme,
    this.preselectedProfileId,
  });

  @override
  ConsumerState<AddToProfileDialog> createState() => _AddToProfileDialogState();
}

class _AddToProfileDialogState extends ConsumerState<AddToProfileDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _installmentsController;
  late TextEditingController _notesController;

  late DateTime _startDate;
  late ScheduleFrequency _frequency;
  bool _markPastAsConfirmed = true;
  int? _selectedProfileId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: '500');
    _installmentsController = TextEditingController(text: '12');
    _notesController = TextEditingController();

    // Default start date is today (device local date)
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _frequency = ScheduleFrequency.monthly;
    _selectedProfileId = widget.preselectedProfileId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  ScheduleSummary _calculateLiveSchedule() {
    final amountRupees = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
    final count = int.tryParse(_installmentsController.text.trim()) ??
        (_frequency == ScheduleFrequency.oneTime ? 1 : 12);

    return InvestmentScheduleService.generateSchedule(
      startDate: _startDate,
      totalInstallments: count > 0 ? count : 1,
      frequency: _frequency,
      amountPerInstallmentPaise: amountPaise > 0 ? amountPaise : 0,
      asOfDate: DateTime.now(),
    );
  }

  void _onFrequencyChanged(ScheduleFrequency? newFreq) {
    if (newFreq == null) return;
    setState(() {
      _frequency = newFreq;
      if (newFreq == ScheduleFrequency.oneTime) {
        _installmentsController.text = '1';
      } else if (_installmentsController.text == '1') {
        _installmentsController.text = '12';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    _selectedProfileId ??= activeProfileId;
    final schedule = _calculateLiveSchedule();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Investment Schedule',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Mutual Fund Scheme Header Card
                        FinCard(
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.scheme.schemeName,
                                style: AppTypography.titleMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.scheme.fundHouse != null &&
                                  widget.scheme.fundHouse!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.scheme.fundHouse!,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                              const Divider(height: AppSpacing.md),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Latest NAV',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  Text(
                                    widget.scheme.latestNav != null
                                        ? '₹${FinancialPrecision.microPaiseToNav(widget.scheme.latestNav!.navMicroPaise).toStringAsFixed(4)} (${DateFormatter.formatDate(widget.scheme.latestNav!.date)})'
                                        : 'Awaiting NAV fetch',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brandPrimaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 2. Financial Profile
                        Text(
                          'Financial Profile',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        profilesAsync.when(
                          data: (profiles) => DropdownButtonFormField<int>(
                            initialValue: _selectedProfileId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                            ),
                            items: profiles
                                .map((p) => DropdownMenuItem(
                                      value: p.id,
                                      child:
                                          Text('${p.name} (${p.relationship})'),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedProfileId = val);
                              }
                            },
                          ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) =>
                              const Text('Error loading profiles'),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 3. Investment Amount & Frequency
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount per installment',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                            decimal: true),
                                    decoration: const InputDecoration(
                                      prefixText: '₹ ',
                                      border: OutlineInputBorder(),
                                      hintText: '500',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) {
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter amount';
                                      }
                                      final amt = double.tryParse(val.trim());
                                      if (amt == null || amt <= 0) {
                                        return 'Must be > 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Frequency',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  DropdownButtonFormField<ScheduleFrequency>(
                                    initialValue: _frequency,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 12),
                                    ),
                                    items: ScheduleFrequency.values
                                        .map((f) => DropdownMenuItem(
                                              value: f,
                                              child: Text(f.label),
                                            ))
                                        .toList(),
                                    onChanged: _onFrequencyChanged,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 4. Start Date & Number of Installments
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Start Date',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate,
                                        firstDate: DateTime(1990),
                                        lastDate: DateTime(2040),
                                      );
                                      if (picked != null) {
                                        setState(() => _startDate = DateTime(
                                            picked.year,
                                            picked.month,
                                            picked.day));
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 14),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: isDark
                                              ? AppColors.darkBorder
                                              : AppColors.lightBorder,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormatter.formatDate(
                                                _startDate),
                                            style: AppTypography.bodyMedium,
                                          ),
                                          const Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Installments',
                                    style: AppTypography.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextFormField(
                                    controller: _installmentsController,
                                    enabled:
                                        _frequency != ScheduleFrequency.oneTime,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      border: const OutlineInputBorder(),
                                      hintText: '12',
                                      helperText: _frequency ==
                                              ScheduleFrequency.oneTime
                                          ? 'Locked for one-time'
                                          : null,
                                    ),
                                    onChanged: (_) => setState(() {}),
                                    validator: (val) {
                                      if (_frequency ==
                                          ScheduleFrequency.oneTime) {
                                        return null;
                                      }
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Enter count';
                                      }
                                      final count = int.tryParse(val.trim());
                                      if (count == null || count < 1) {
                                        return 'Must be >= 1';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // 5. Automatic Calculation Summary Card
                        FinCard(
                          backgroundColor: isDark
                              ? AppColors.darkSurfaceElevated
                              : AppColors.lightSurfaceElevated,
                          borderColor:
                              AppColors.brandPrimaryLight.withAlpha(80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SCHEDULE CALCULATION',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  if (schedule.occurrences.isNotEmpty)
                                    Text(
                                      'Ends ${DateFormatter.formatDate(schedule.occurrences.last.scheduledDate)}',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.brandPrimaryLight,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Row(
                                children: [
                                  // Past Installments
                                  Expanded(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: AppColors.asset.withAlpha(25),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
                                        border: Border.all(
                                          color: AppColors.asset.withAlpha(60),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'PAST (ACTUAL)',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.asset,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.formatPaise(
                                                schedule
                                                    .pastInvestedAmountPaise),
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.asset,
                                            ),
                                          ),
                                          Text(
                                            '${schedule.pastInstallments} installment${schedule.pastInstallments == 1 ? '' : 's'}',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                      .lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  // Future Installments
                                  Expanded(
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.scheduled.withAlpha(25),
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
                                        border: Border.all(
                                          color:
                                              AppColors.scheduled.withAlpha(60),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'FUTURE (PLANNED)',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: AppColors.scheduled,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 9,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            CurrencyFormatter.formatPaise(
                                                schedule
                                                    .futureScheduledAmountPaise),
                                            style: AppTypography.titleMedium
                                                .copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.scheduled,
                                            ),
                                          ),
                                          Text(
                                            '${schedule.futureInstallments} installment${schedule.futureInstallments == 1 ? '' : 's'}',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextSecondary
                                                  : AppColors
                                                      .lightTextSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Total scheduled: ${CurrencyFormatter.formatPaise(schedule.totalScheduledAmountPaise)} across ${schedule.totalInstallments} installments. Only past installments are included in your portfolio valuation.',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // 6. Confirmed Status Toggle
                        if (schedule.pastInstallments > 0)
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Confirm past installments as actual investments',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _markPastAsConfirmed
                                  ? 'Past installments will be added to holding units and transaction history using historical NAVs.'
                                  : 'Past installments will remain estimated simulation records.',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                            value: _markPastAsConfirmed,
                            onChanged: (val) =>
                                setState(() => _markPastAsConfirmed = val),
                          ),

                        // 7. Notes
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: 'Description / Notes (Optional)',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. Monthly tax saver SIP via Zerodha',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.md),
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilledButton(
                      onPressed: _isSaving ? null : _saveSchedule,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Schedule'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = _selectedProfileId;
    if (profileId == null) return;

    final amountRupees = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
    final count = int.tryParse(_installmentsController.text.trim()) ??
        (_frequency == ScheduleFrequency.oneTime ? 1 : 12);

    setState(() => _isSaving = true);

    try {
      final sipsDao = ref.read(sipsDaoProvider);
      final result = await sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: widget.scheme.schemeCode,
        schemeName: widget.scheme.schemeName,
        startDate: _startDate,
        totalInstallments: count,
        frequency: _frequency,
        amountPerInstallmentPaise: amountPaise,
        markPastAsConfirmed: _markPastAsConfirmed,
        latestNavMicroPaise: widget.scheme.latestNav?.navMicroPaise,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Schedule created: ${result.totalInstallments} installments (${result.pastInstallments} past, ${result.futureInstallments} planned future).',
            ),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save investment schedule: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
