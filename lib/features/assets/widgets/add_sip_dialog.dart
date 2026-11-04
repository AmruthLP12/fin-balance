import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/scheduling/investment_schedule_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/precision/financial_precision.dart';

/// Creates a SIP for the active profile. The start date is the first deduction date,
/// so a past start date records the earlier installments valued at the historical NAV
/// for each date, and later installments stay planned. This is the same flow as
/// "Add to profile" and replaces the old ongoing / bulk-historical split.
class AddSipDialog extends ConsumerStatefulWidget {
  final int? preselectedSchemeCode;
  final String? preselectedSchemeName;

  const AddSipDialog({
    super.key,
    this.preselectedSchemeCode,
    this.preselectedSchemeName,
  });

  @override
  ConsumerState<AddSipDialog> createState() => _AddSipDialogState();
}

class _AddSipDialogState extends ConsumerState<AddSipDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _installmentsController;

  int? _schemeCode;
  String? _schemeName;
  DateTime _startDate = DateTime.now();
  ScheduleFrequency _frequency = ScheduleFrequency.monthly;
  bool _markPastAsConfirmed = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _schemeCode = widget.preselectedSchemeCode;
    _schemeName = widget.preselectedSchemeName;
    _amountController = TextEditingController();
    _installmentsController = TextEditingController(text: '12');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  ScheduleSummary? get _preview {
    final count = int.tryParse(_installmentsController.text.trim());
    if (count == null || count < 1) return null;
    return InvestmentScheduleService.calculateSchedule(
      startDate: _startDate,
      installmentCount: count,
      frequency: _frequency,
      amountPerInstallmentPaise: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preview = _preview;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add SIP',
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildSchemeSelector(
                  isDark: isDark,
                  currentCode: _schemeCode,
                  currentName: _schemeName,
                  onSelected: (code, name) => setState(() {
                    _schemeCode = code;
                    _schemeName = name;
                  }),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount per installment',
                    prefixText: '₹ ',
                  ),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').trim());
                    return n == null || n <= 0 ? 'Enter an amount > 0' : null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<ScheduleFrequency>(
                  initialValue: _frequency,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                  items: [
                    for (final f in ScheduleFrequency.values)
                      if (f != ScheduleFrequency.oneTime)
                        DropdownMenuItem(value: f, child: Text(f.label)),
                  ],
                  onChanged: (f) => setState(() => _frequency = f ?? _frequency),
                ),
                const SizedBox(height: AppSpacing.md),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(
                    '${DateFormatter.formatDate(_startDate)} · first deduction',
                  ),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _startDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2035),
                    );
                    if (d != null) setState(() => _startDate = d);
                  },
                ),
                TextFormField(
                  controller: _installmentsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Number of installments',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    return n == null || n < 1 ? 'Enter at least 1' : null;
                  },
                ),
                if (preview != null && preview.pastInstallments > 0)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Record past installments as invested'),
                    subtitle: const Text(
                      'Units come from the historical NAV on each date.',
                    ),
                    value: _markPastAsConfirmed,
                    onChanged: (v) => setState(() => _markPastAsConfirmed = v),
                  ),
                if (preview != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '${preview.pastInstallments} past · ${preview.futureInstallments} upcoming',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.asset,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create SIP'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSchemeSelector({
    required bool isDark,
    required int? currentCode,
    required String? currentName,
    required void Function(int code, String name) onSelected,
  }) {
    if (currentCode != null && currentName != null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurfaceElevated
              : AppColors.lightSurfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.pie_chart_rounded, color: AppColors.asset),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentName,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Scheme Code: $currentCode',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _pickScheme(onSelected),
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      icon: const Icon(Icons.search_rounded),
      label: const Text('Select Mutual Fund Scheme'),
      onPressed: () => _pickScheme(onSelected),
    );
  }

  void _pickScheme(void Function(int code, String name) onSelected) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final favorites = ref.watch(favoriteSchemesProvider).value ?? [];
            final assets = ref.watch(activeProfileAssetsProvider).value ?? [];

            final fundAssets =
                assets.where((a) => a.subType == 'mutual_fund').toList();

            return SafeArea(
              child: ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  const Text('Select Scheme', style: AppTypography.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
                  if (favorites.isEmpty && fundAssets.isEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'No favourite schemes or portfolio holdings yet. Bookmark or search for schemes in Assets tab.',
                      ),
                    ),
                  ],
                  if (favorites.isNotEmpty) ...[
                    const Text('From Bookmarked Favourites',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: AppSpacing.xs),
                    ...favorites.map((f) => ListTile(
                          title: Text(f.schemeName),
                          subtitle: Text('Code: ${f.schemeCode}'),
                          onTap: () {
                            onSelected(f.schemeCode, f.schemeName);
                            Navigator.pop(context);
                          },
                        )),
                  ],
                  if (fundAssets.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const Text('From Existing Portfolio Holdings',
                        style: AppTypography.labelSmall),
                    const SizedBox(height: AppSpacing.xs),
                    ...fundAssets.map((a) {
                      final code = int.tryParse(a.externalCode ?? '0') ?? 0;
                      return ListTile(
                        title: Text(a.name),
                        subtitle: Text('Code: $code'),
                        onTap: () {
                          onSelected(code, a.name);
                          Navigator.pop(context);
                        },
                      );
                    }),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _schemeCode;
    if (code == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mutual Fund scheme')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      // Pull NAV history first so past installments can be valued; offline is fine,
      // anything without a NAV is kept as "pending valuation".
      try {
        await ref.read(navSyncServiceProvider).getOrFetchSchemeDetails(
              code,
              forceRefresh: true,
              includeHistoricalNav: true,
            );
      } catch (_) {}

      final result = await ref.read(sipsDaoProvider).createInvestmentSchedule(
            profileId: ref.read(activeProfileIdProvider),
            schemeCode: code,
            schemeName: _schemeName ?? 'Scheme $code',
            amountPerInstallmentPaise: FinancialPrecision.rupeesToPaise(
                double.parse(_amountController.text.trim())),
            startDate: _startDate,
            installmentCount: int.parse(_installmentsController.text.trim()),
            frequency: _frequency,
            markPastAsConfirmed: _markPastAsConfirmed,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'SIP created: ${result.pastInstallments} past, ${result.futureInstallments} upcoming'
              '${result.pendingValuationInstallments > 0 ? ' (${result.pendingValuationInstallments} awaiting NAV)' : ''}.',
            ),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create SIP: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
