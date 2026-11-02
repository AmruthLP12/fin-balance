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
import '../../../data/nav/models/nav_models.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen mobile-optimized dialog/page for adding a mutual fund investment schedule.
///
/// Features:
/// - Persistent top bar with title, back/close button, and primary Save action.
/// - Edge-to-edge layout on mobile with zero unnecessary modal margins.
/// - Responsive single-column layout on narrow screens, balanced max-width on wider screens.
/// - Strict field order: Scheme -> Amount -> Start Date -> Frequency -> Installments -> Profile -> Notes.
/// - Redesigned, non-overlapping calculation card with collapsible installment preview.
class AddToProfileDialog extends ConsumerStatefulWidget {
  final MutualFundSchemeDetail scheme;
  final int? preselectedProfileId;

  const AddToProfileDialog({
    super.key,
    required this.scheme,
    this.preselectedProfileId,
  });

  /// Static helper to display the schedule form adaptively.
  static Future<void> show(
    BuildContext context, {
    required MutualFundSchemeDetail scheme,
    int? preselectedProfileId,
  }) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AddToProfileDialog(
          scheme: scheme,
          preselectedProfileId: preselectedProfileId,
        ),
      ),
    );
  }

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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Investment Schedule'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveSchedule,
              icon: _isSaving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save'),
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    children: [
                      // 1. Mutual Fund Scheme Header Card
                      _buildSchemeCard(isDark),
                      const SizedBox(height: AppSpacing.md),

                      // 2. Amount per installment
                      Text(
                        'Amount per installment',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 500',
                          helperText:
                              'Amount invested on each scheduled occurrence',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter installment amount';
                          }
                          final amt = double.tryParse(val.trim());
                          if (amt == null || amt <= 0) {
                            return 'Amount must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 3. Start Date & 4. Frequency
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildStartDatePicker(isDark)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildFrequencyPicker()),
                          ],
                        )
                      else ...[
                        _buildStartDatePicker(isDark),
                        const SizedBox(height: AppSpacing.md),
                        _buildFrequencyPicker(),
                      ],
                      const SizedBox(height: AppSpacing.md),

                      // 5. Number of Installments
                      Text(
                        'Number of Installments',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _installmentsController,
                        enabled: _frequency != ScheduleFrequency.oneTime,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: '12',
                          helperText: _frequency == ScheduleFrequency.oneTime
                              ? 'Locked to 1 for one-time contribution'
                              : 'Total occurrences for this schedule plan',
                        ),
                        onChanged: (_) => setState(() {}),
                        validator: (val) {
                          if (_frequency == ScheduleFrequency.oneTime) {
                            return null;
                          }
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter number of installments';
                          }
                          final count = int.tryParse(val.trim());
                          if (count == null || count < 1) {
                            return 'Must be at least 1';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 6. Financial Profile Selector
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
                            helperText: 'Select profile owning this investment',
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
                        error: (_, __) => const Text('Error loading profiles'),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 7. Optional description / notes
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Description / Notes (Optional)',
                          border: OutlineInputBorder(),
                          hintText:
                              'e.g. Monthly tax saver via AMC direct portal',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // 8. Confirmed vs Estimated Toggle (if past installments exist)
                      if (schedule.pastInstallments > 0) ...[
                        FinCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Confirm past installments as actual investments',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              _markPastAsConfirmed
                                  ? 'Past installments will be added to holding units and ledger using historical NAVs.'
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
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 9. Redesigned Schedule Calculation Card
                      _buildScheduleCalculationCard(schedule, isDark),
                      const SizedBox(height: AppSpacing.md),

                      // 10. Collapsible Installment Preview
                      _buildCollapsiblePreview(schedule, isDark),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSchemeCard(bool isDark) {
    return FinCard(
      backgroundColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.scheme.schemeName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const StatusBadge(
                label: 'MUTUAL FUND',
                type: BadgeType.asset,
              ),
            ],
          ),
          if (widget.scheme.fundHouse != null &&
              widget.scheme.fundHouse!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              widget.scheme.fundHouse!,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
          const Divider(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest Available NAV',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  widget.scheme.latestNav != null
                      ? '₹${FinancialPrecision.microPaiseToNav(widget.scheme.latestNav!.navMicroPaise).toStringAsFixed(4)} (${DateFormatter.formatDate(widget.scheme.latestNav!.date)})'
                      : 'Awaiting NAV fetch',
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandPrimaryLight,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStartDatePicker(bool isDark) {
    return Column(
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
              setState(() =>
                  _startDate = DateTime(picked.year, picked.month, picked.day));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormatter.formatDate(_startDate),
                  style: AppTypography.bodyMedium,
                ),
                const Icon(Icons.calendar_today_rounded, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencyPicker() {
    return Column(
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
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
    );
  }

  Widget _buildScheduleCalculationCard(ScheduleSummary schedule, bool isDark) {
    return FinCard(
      backgroundColor: isDark
          ? AppColors.darkSurfaceElevated
          : AppColors.lightSurfaceElevated,
      borderColor: AppColors.brandPrimaryLight.withAlpha(80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Flexible(
                  child: Text(
                    'Ends ${DateFormatter.formatDate(schedule.occurrences.last.scheduledDate)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.brandPrimaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Primary counts & amounts
          _calculationRow(
            label: 'Total Installments',
            value: '${schedule.totalInstallments}',
            subValue: CurrencyFormatter.formatPaise(
                schedule.totalScheduledAmountPaise),
            isDark: isDark,
          ),
          const Divider(height: AppSpacing.md),
          _calculationRow(
            label: 'Past Installments (Actual)',
            value: '${schedule.pastInstallments}',
            subValue: CurrencyFormatter.formatPaise(
                schedule.pastScheduledAmountPaise),
            valueColor: AppColors.asset,
            isDark: isDark,
          ),
          const Divider(height: AppSpacing.md),
          _calculationRow(
            label: 'Future Installments (Planned)',
            value: '${schedule.futureInstallments}',
            subValue: CurrencyFormatter.formatPaise(
                schedule.futureScheduledAmountPaise),
            valueColor: AppColors.scheduled,
            isDark: isDark,
          ),
          const Divider(height: AppSpacing.md),

          // Valuation status info
          Row(
            children: [
              Icon(
                schedule.pastInstallments > 0
                    ? Icons.history_edu_rounded
                    : Icons.schedule_rounded,
                size: 16,
                color: AppColors.brandPrimaryLight,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  schedule.pastInstallments > 0
                      ? 'Historical NAV will be applied to each past installment individually.'
                      : 'All installments are future planned occurrences.',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _calculationRow({
    required String label,
    required String value,
    required String subValue,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              '($subValue)',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ??
                    (isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCollapsiblePreview(ScheduleSummary schedule, bool isDark) {
    if (schedule.occurrences.isEmpty) return const SizedBox.shrink();

    return FinCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            'Schedule Installment Preview (${schedule.occurrences.length})',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Inspect individual scheduled dates and valuation status',
            style: AppTypography.labelSmall.copyWith(
              color:
                  isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          children: [
            const Divider(height: 1),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                itemCount: schedule.occurrences.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final occ = schedule.occurrences[index];
                  final isPast = occ.isPast;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '#${occ.installmentNumber}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              DateFormatter.formatDate(occ.scheduledDate),
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: isPast ? 'PAST ACTUAL' : 'PLANNED',
                          type: isPast ? BadgeType.asset : BadgeType.scheduled,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
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
