import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/scheduling/recurring_date_calculator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/precision/financial_precision.dart';

/// Dialog for adding a new ongoing SIP Plan or recording a bulk historical SIP range.
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

class _AddSipDialogState extends ConsumerState<AddSipDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ongoingFormKey = GlobalKey<FormState>();
  final _bulkFormKey = GlobalKey<FormState>();

  // Ongoing form controllers
  late TextEditingController _ongoingNameController;
  late TextEditingController _ongoingAmountController;
  late TextEditingController _ongoingDayController;
  DateTime _ongoingStartDate = DateTime.now();
  DateTime? _ongoingEndDate;
  int? _ongoingSchemeCode;
  String? _ongoingSchemeName;

  // Bulk historical form controllers
  late TextEditingController _bulkNameController;
  late TextEditingController _bulkAmountController;
  late TextEditingController _bulkDayController;
  DateTime _bulkFromDate = DateTime.utc(DateTime.now().year, 1, 1);
  DateTime _bulkToDate = DateTime.now();
  bool _markAsConfirmed = true;
  int? _bulkSchemeCode;
  String? _bulkSchemeName;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _ongoingSchemeCode = widget.preselectedSchemeCode;
    _ongoingSchemeName = widget.preselectedSchemeName;
    _bulkSchemeCode = widget.preselectedSchemeCode;
    _bulkSchemeName = widget.preselectedSchemeName;

    _ongoingNameController = TextEditingController(
      text: widget.preselectedSchemeName != null
          ? 'SIP - ${widget.preselectedSchemeName}'
          : 'Monthly SIP',
    );
    _ongoingAmountController = TextEditingController(text: '1000');
    _ongoingDayController = TextEditingController(text: '5');

    _bulkNameController = TextEditingController(
      text: widget.preselectedSchemeName != null
          ? 'Historical SIP - ${widget.preselectedSchemeName}'
          : 'Historical SIP',
    );
    _bulkAmountController = TextEditingController(text: '1000');
    _bulkDayController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ongoingNameController.dispose();
    _ongoingAmountController.dispose();
    _ongoingDayController.dispose();
    _bulkNameController.dispose();
    _bulkAmountController.dispose();
    _bulkDayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favSchemesAsync = ref.watch(favoriteSchemesProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.md,
                top: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add SIP Investment',
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
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Ongoing Recurring SIP'),
                Tab(text: 'Bulk Historical Entry'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Ongoing SIP
                  _buildOngoingTab(isDark, favSchemesAsync, assetsAsync),

                  // Tab 2: Bulk Historical Entry
                  _buildBulkTab(isDark, favSchemesAsync, assetsAsync),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOngoingTab(
    bool isDark,
    AsyncValue<dynamic> favSchemesAsync,
    AsyncValue<dynamic> assetsAsync,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _ongoingFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSchemeSelector(
              isDark: isDark,
              currentCode: _ongoingSchemeCode,
              currentName: _ongoingSchemeName,
              onSelected: (code, name) {
                setState(() {
                  _ongoingSchemeCode = code;
                  _ongoingSchemeName = name;
                  _ongoingNameController.text = 'SIP - $name';
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _ongoingNameController,
              decoration: const InputDecoration(
                labelText: 'SIP Name',
                hintText: 'e.g. Parag Parikh Flexi Cap Monthly',
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Please enter SIP name'
                  : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _ongoingAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Investment Amount (₹)',
                prefixText: '₹ ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter valid amount > 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _ongoingDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deduction Day of Month (1 - 31)',
                helperText:
                    'Month-end clamping active (31st safely clamps to 28/29 Feb, 30 Apr)',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter day';
                final d = int.tryParse(v.trim());
                if (d == null || d < 1 || d > 31) return 'Day must be 1-31';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Start Date'),
              subtitle: Text(DateFormatter.formatDate(_ongoingStartDate)),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _ongoingStartDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2035),
                );
                if (d != null) setState(() => _ongoingStartDate = d);
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _saveOngoingSip,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create Ongoing SIP'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkTab(
    bool isDark,
    AsyncValue<dynamic> favSchemesAsync,
    AsyncValue<dynamic> assetsAsync,
  ) {
    final deductionDay = int.tryParse(_bulkDayController.text.trim()) ?? 5;
    final occurrences = RecurringDateCalculator.generateMonthlyOccurrences(
      fromDate: _bulkFromDate,
      toDate: _bulkToDate,
      configuredDay: deductionDay,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _bulkFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.brandPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Bulk Historical Entry creates a completed historical SIP period and auto-generates all intermediate monthly installments between From and To dates.',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
            ),
            _buildSchemeSelector(
              isDark: isDark,
              currentCode: _bulkSchemeCode,
              currentName: _bulkSchemeName,
              onSelected: (code, name) {
                setState(() {
                  _bulkSchemeCode = code;
                  _bulkSchemeName = name;
                  _bulkNameController.text = 'Historical SIP - $name';
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bulkNameController,
              decoration: const InputDecoration(
                labelText: 'SIP Name',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bulkAmountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Monthly Investment Amount (₹)',
                prefixText: '₹ ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter amount';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Enter valid amount > 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bulkDayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Deduction Day of Month (1 - 31)',
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter day';
                final d = int.tryParse(v.trim());
                if (d == null || d < 1 || d > 31) return 'Day must be 1-31';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('From Date'),
                    subtitle: Text(DateFormatter.formatDate(_bulkFromDate)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _bulkFromDate,
                        firstDate: DateTime(2000),
                        lastDate: _bulkToDate,
                      );
                      if (d != null) setState(() => _bulkFromDate = d);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('To Date'),
                    subtitle: Text(DateFormatter.formatDate(_bulkToDate)),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _bulkToDate,
                        firstDate: _bulkFromDate,
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setState(() => _bulkToDate = d);
                    },
                  ),
                ),
              ],
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mark as Confirmed Actual Investments'),
              subtitle: const Text(
                'Creates actual ledger transactions. Uncheck for simulated tracking.',
              ),
              value: _markAsConfirmed,
              onChanged: (v) => setState(() => _markAsConfirmed = v ?? true),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '⚡ Preview: ${occurrences.length} installments will be generated without day drift.',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.asset,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _isSaving ? null : _saveBulkHistoricalSip,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Record ${occurrences.length} Historical Installments'),
            ),
          ],
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

  Future<void> _saveOngoingSip() async {
    if (!_ongoingFormKey.currentState!.validate()) return;
    if (_ongoingSchemeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mutual Fund scheme')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profileId = ref.read(activeProfileIdProvider);
      final sipsDao = ref.read(sipsDaoProvider);
      final amountDouble = double.parse(_ongoingAmountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountDouble);
      final deductionDay = int.parse(_ongoingDayController.text.trim());

      await sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: _ongoingSchemeCode!,
        name: _ongoingNameController.text.trim(),
        startDate: _ongoingStartDate,
        endDate: _ongoingEndDate,
        amountPaise: amountPaise,
        deductionDay: deductionDay,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ongoing SIP created successfully!'),
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

  Future<void> _saveBulkHistoricalSip() async {
    if (!_bulkFormKey.currentState!.validate()) return;
    if (_bulkSchemeCode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Mutual Fund scheme')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final profileId = ref.read(activeProfileIdProvider);
      final sipsDao = ref.read(sipsDaoProvider);
      final amountDouble = double.parse(_bulkAmountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountDouble);
      final deductionDay = int.parse(_bulkDayController.text.trim());

      await sipsDao.recordBulkHistoricalSip(
        profileId: profileId,
        schemeCode: _bulkSchemeCode!,
        name: _bulkNameController.text.trim(),
        fromDate: _bulkFromDate,
        toDate: _bulkToDate,
        amountPaise: amountPaise,
        deductionDay: deductionDay,
        markAsConfirmed: _markAsConfirmed,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Historical SIP & installments recorded!'),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record historical SIP: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
