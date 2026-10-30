import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/nav/models/nav_models.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Modal dialog allowing user to add a mutual fund scheme into an active profile's asset portfolio.
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
  late TextEditingController _amountController;
  late TextEditingController _unitsController;
  late TextEditingController _purchaseNavController;
  late TextEditingController _notesController;
  late DateTime _purchaseDate;
  int? _selectedProfileId;
  bool _isSaving = false;
  bool _isSyncingFields = false;

  @override
  void initState() {
    super.initState();
    final latestNavDouble = widget.scheme.latestNav != null
        ? FinancialPrecision.microPaiseToNav(
            widget.scheme.latestNav!.navMicroPaise)
        : 100.0;

    _amountController = TextEditingController(text: '10000');
    _purchaseNavController =
        TextEditingController(text: latestNavDouble.toStringAsFixed(4));
    _unitsController = TextEditingController();
    _notesController = TextEditingController();
    _purchaseDate = widget.scheme.latestNav?.date ?? DateTime.now();

    _selectedProfileId = widget.preselectedProfileId;
    _updateUnitsFromAmount();
  }

  void _updateUnitsFromAmount() {
    if (_isSyncingFields) return;
    _isSyncingFields = true;
    final amountRupees = double.tryParse(_amountController.text) ?? 0.0;
    final purchaseNav = double.tryParse(_purchaseNavController.text) ?? 0.0;

    if (purchaseNav > 0) {
      final navMicroPaise = FinancialPrecision.navToMicroPaise(purchaseNav);
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: FinancialPrecision.rupeesToPaise(amountRupees),
        navMicroPaise: navMicroPaise,
      );
      final units = FinancialPrecision.microUnitsToUnits(unitsMicro);
      _unitsController.text = units > 0 ? units.toStringAsFixed(4) : '';
    }
    _isSyncingFields = false;
  }

  void _updateAmountFromUnits() {
    if (_isSyncingFields) return;
    _isSyncingFields = true;
    final units = double.tryParse(_unitsController.text) ?? 0.0;
    final purchaseNav = double.tryParse(_purchaseNavController.text) ?? 0.0;

    if (purchaseNav > 0 && units > 0) {
      final amount = units * purchaseNav;
      _amountController.text = amount.toStringAsFixed(2);
    }
    _isSyncingFields = false;
  }

  void _onPurchaseNavChanged() {
    if (_isSyncingFields) return;
    final amountRupees = double.tryParse(_amountController.text) ?? 0.0;
    if (amountRupees > 0) {
      _updateUnitsFromAmount();
    } else {
      _updateAmountFromUnits();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    _purchaseNavController.dispose();
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

    return AlertDialog(
      title: const Text('Add to Portfolio Assets'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.scheme.schemeName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (widget.scheme.latestNav != null)
              Text(
                'Latest NAV: ${CurrencyFormatter.format(FinancialPrecision.microPaiseToNav(widget.scheme.latestNav!.navMicroPaise))} (${DateFormatter.formatDate(widget.scheme.latestNav!.date)})',
                style: AppTypography.labelMedium.copyWith(
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                ),
              ),
            const Divider(height: AppSpacing.lg),

            // Profile Selection
            Text(
              'Select Profile',
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
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: profiles
                    .map((p) => DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.name} (${p.relationship})'),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedProfileId = val);
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Error loading profiles'),
            ),
            const SizedBox(height: AppSpacing.md),

            // Investment Amount
            Text(
              'Investment Amount (INR)',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                hintText: 'e.g. 5000',
              ),
              onChanged: (_) => _updateUnitsFromAmount(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Purchase NAV
            Text(
              'Purchase NAV (INR)',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _purchaseNavController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(),
                hintText: 'e.g. 150.25',
              ),
              onChanged: (_) => _onPurchaseNavChanged(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Units Allotted
            Text(
              'Units Allotted',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _unitsController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                suffixText: 'units',
                border: OutlineInputBorder(),
                hintText: 'e.g. 45.123',
              ),
              onChanged: (_) => _updateAmountFromUnits(),
            ),
            const SizedBox(height: AppSpacing.md),

            // Purchase Date
            Text(
              'Purchase Date',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(1990),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) {
                  setState(() => _purchaseDate = picked);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormatter.formatDate(_purchaseDate),
                      style: AppTypography.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today_rounded, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Notes
            Text(
              'Notes (Optional)',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Initial lumpsum investment',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _saveAssetToProfile,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Asset'),
        ),
      ],
    );
  }

  Future<void> _saveAssetToProfile() async {
    final profileId = _selectedProfileId;
    if (profileId == null) return;

    setState(() => _isSaving = true);

    try {
      final categoriesDao = ref.read(categoriesDaoProvider);
      final itemsDao = ref.read(financialItemsDaoProvider);

      // 1. Get or default to asset category for Mutual Funds
      final assetCats =
          await categoriesDao.getCategoriesByClassification('asset');
      final mfCategory = assetCats.firstWhere(
        (c) => c.name.toLowerCase().contains('mutual fund'),
        orElse: () => assetCats.first,
      );

      final amountRupees = double.tryParse(_amountController.text) ?? 0.0;
      final units = double.tryParse(_unitsController.text) ?? 0.0;
      final purchaseNavRupees =
          double.tryParse(_purchaseNavController.text) ?? 0.0;

      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final unitsMicro = FinancialPrecision.unitsToMicroUnits(units);
      final purchaseNavMicro =
          FinancialPrecision.navToMicroPaise(purchaseNavRupees);

      // Latest market NAV (use scheme latestNav or purchaseNav as fallback)
      final latestNavMicro = widget.scheme.latestNav?.navMicroPaise ??
          (purchaseNavMicro > 0
              ? purchaseNavMicro
              : FinancialPrecision.navToMicroPaise(100.0));

      final valuationPaise = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro,
        navMicroPaise: latestNavMicro,
      );

      final userNotes = _notesController.text.trim();

      // 2. Check if this profile already holds this mutual fund scheme
      final existingItem = await itemsDao.getItemByExternalCode(
        profileId,
        widget.scheme.schemeCode.toString(),
      );

      int itemId;
      if (existingItem != null) {
        final newUnitsMicro = existingItem.unitCountMicroUnits + unitsMicro;
        final newInitialPaise = existingItem.initialValuePaise + amountPaise;
        final newValuationPaise = FinancialPrecision.calculateValuationPaise(
          unitCountMicroUnits: newUnitsMicro,
          navMicroPaise: latestNavMicro,
        );

        await itemsDao.updateItem(
          existingItem.copyWith(
            initialValuePaise: newInitialPaise,
            currentValuationPaise: newValuationPaise,
            unitCountMicroUnits: newUnitsMicro,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
        itemId = existingItem.id;
      } else {
        itemId = await itemsDao.insertItem(
          FinancialItemsCompanion(
            profileId: drift.Value(profileId),
            name: drift.Value(widget.scheme.schemeName),
            itemType: const drift.Value('asset'),
            subType: const drift.Value('mutual_fund'),
            categoryId: drift.Value(mfCategory.id),
            externalCode: drift.Value(widget.scheme.schemeCode.toString()),
            initialValuePaise: drift.Value(amountPaise),
            currentValuationPaise: drift.Value(valuationPaise),
            unitCountMicroUnits: drift.Value(unitsMicro),
            startDate: drift.Value(_purchaseDate),
            notes: userNotes.isNotEmpty
                ? drift.Value(userNotes)
                : const drift.Value.absent(),
          ),
        );
      }

      // 3. Record investment purchase transaction
      if (amountPaise > 0 || unitsMicro > 0) {
        final txDao = ref.read(transactionsDaoProvider);
        await txDao.insertTransaction(
          TransactionsCompanion(
            profileId: drift.Value(profileId),
            transactionType: const drift.Value('investment_purchase'),
            categoryId: drift.Value(mfCategory.id),
            financialItemId: drift.Value(itemId),
            transactionDate: drift.Value(_purchaseDate),
            amountPaise: drift.Value(amountPaise),
            unitsMicroUnits: drift.Value(unitsMicro),
            unitPriceMicroPaise: drift.Value(purchaseNavMicro),
            source: const drift.Value('manual'),
            notes: drift.Value(
              userNotes.isNotEmpty
                  ? userNotes
                  : (existingItem != null
                      ? 'Additional investment in ${widget.scheme.schemeName}'
                      : 'Initial holding in ${widget.scheme.schemeName}'),
            ),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Added "${widget.scheme.schemeName}" to profile portfolio!'),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding asset: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
