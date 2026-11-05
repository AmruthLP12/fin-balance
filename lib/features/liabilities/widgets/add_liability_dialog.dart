import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import '../../../core/constants/asset_categories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen mobile-optimized dialog for recording a new liability or debt commitment.
class AddLiabilityDialog extends ConsumerStatefulWidget {
  final int? preselectedProfileId;

  const AddLiabilityDialog({super.key, this.preselectedProfileId});

  static Future<void> show(BuildContext context, {int? preselectedProfileId}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) =>
            AddLiabilityDialog(preselectedProfileId: preselectedProfileId),
      ),
    );
  }

  @override
  ConsumerState<AddLiabilityDialog> createState() => _AddLiabilityDialogState();
}

class _AddLiabilityDialogState extends ConsumerState<AddLiabilityDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _outstandingController;
  late TextEditingController _principalController;
  late TextEditingController _interestRateController;
  late TextEditingController _notesController;

  String _subType = 'home_loan';
  late DateTime _startDate;
  int? _selectedProfileId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _outstandingController = TextEditingController();
    _principalController = TextEditingController();
    _interestRateController = TextEditingController(text: '8.5');
    _notesController = TextEditingController();

    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _selectedProfileId = widget.preselectedProfileId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _outstandingController.dispose();
    _principalController.dispose();
    _interestRateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profilesAsync = ref.watch(allProfilesProvider);
    final activeProfileId = ref.watch(activeProfileIdProvider);

    _selectedProfileId ??= activeProfileId;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        title: const Text('Add Liability'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveLiability,
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
                backgroundColor: AppColors.liability,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                children: [
                  // 1. Name
                  Text(
                    'Liability / Loan Name',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. HDFC Home Loan, SBI Auto Loan',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter liability name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 2. Type
                  Text(
                    'Liability Type',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _subType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    ),
                    items: liabilityTypeOptions
                        .map((e) => DropdownMenuItem(
                              value: e.$1,
                              child:
                                  Text(e.$2, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _subType = val);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 3. Owning Profile
                  Text(
                    'Owning Profile',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  profilesAsync.when(
                    data: (profiles) => DropdownButtonFormField<int>(
                      initialValue: _selectedProfileId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                      ),
                      items: profiles
                          .map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text('${p.name} (${p.relationship})',
                                    overflow: TextOverflow.ellipsis),
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

                  // 3. Outstanding Balance
                  Text(
                    'Current Outstanding Balance (INR)',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _outstandingController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. 2500000',
                      helperText:
                          'Current principal debt remaining to be repaid',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter outstanding balance';
                      }
                      final n = double.tryParse(val.trim());
                      if (n == null || n < 0) {
                        return 'Amount must be positive';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 4. Principal Amount & Interest Rate
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sanctioned Amount (₹)',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _principalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                hintText: 'Optional',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interest Rate (% p.a.)',
                              style: AppTypography.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            TextFormField(
                              controller: _interestRateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                suffixText: '%',
                                border: OutlineInputBorder(),
                                hintText: '8.5',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // 5. Start Date
                  Text(
                    'Origination / Start Date',
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
                        setState(() => _startDate =
                            DateTime(picked.year, picked.month, picked.day));
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
                  const SizedBox(height: AppSpacing.md),

                  // 6. Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes & Lender Details (Optional)',
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Fixed rate loan, Account #123456',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLiability() async {
    if (!_formKey.currentState!.validate()) return;
    final profileId = _selectedProfileId;
    if (profileId == null) return;

    final name = _nameController.text.trim();
    final outstandingRupees =
        double.tryParse(_outstandingController.text.trim()) ?? 0.0;
    final outstandingPaise =
        FinancialPrecision.rupeesToPaise(outstandingRupees);

    final principalRupees =
        double.tryParse(_principalController.text.trim()) ?? outstandingRupees;
    final principalPaise = FinancialPrecision.rupeesToPaise(principalRupees);

    final ratePct = double.tryParse(_interestRateController.text.trim()) ?? 0.0;
    final rateBps = (ratePct * 100).round();

    final notes = _notesController.text.trim();

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final categories =
          await db.categoriesDao.getCategoriesByClassification('liability');
      final categoryId = categories.isNotEmpty ? categories.first.id : 2;

      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: drift.Value(name),
          itemType: const drift.Value('liability'),
          subType: drift.Value(_subType),
          categoryId: drift.Value(categoryId),
          initialValuePaise: drift.Value(principalPaise),
          currentValuationPaise: drift.Value(outstandingPaise),
          interestRateBasisPoints: drift.Value(rateBps),
          startDate: drift.Value(_startDate),
          notes: notes.isNotEmpty
              ? drift.Value(notes)
              : const drift.Value.absent(),
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added liability "$name" to profile balance sheet!'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save liability: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
