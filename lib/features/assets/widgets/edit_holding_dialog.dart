import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Modal dialog allowing user to edit an existing mutual fund holding's investment amount,
/// unit count, purchase NAV, purchase date, and notes.
class EditHoldingDialog extends ConsumerStatefulWidget {
  final FinancialItem holding;

  const EditHoldingDialog({super.key, required this.holding});

  @override
  ConsumerState<EditHoldingDialog> createState() => _EditHoldingDialogState();
}

class _EditHoldingDialogState extends ConsumerState<EditHoldingDialog> {
  late TextEditingController _amountController;
  late TextEditingController _unitsController;
  late TextEditingController _purchaseNavController;
  late TextEditingController _notesController;
  late DateTime _purchaseDate;

  Transaction? _primaryTx;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSyncingFields = false;

  @override
  void initState() {
    super.initState();
    final initialRupees = widget.holding.initialValuePaise / 100.0;
    final initialUnits = FinancialPrecision.microUnitsToUnits(
        widget.holding.unitCountMicroUnits);

    _amountController =
        TextEditingController(text: initialRupees.toStringAsFixed(2));
    _unitsController =
        TextEditingController(text: initialUnits.toStringAsFixed(4));
    _purchaseNavController = TextEditingController();
    _notesController = TextEditingController(text: widget.holding.notes ?? '');
    _purchaseDate = widget.holding.startDate ?? DateTime.now();

    _loadPrimaryTransaction(initialRupees, initialUnits);
  }

  Future<void> _loadPrimaryTransaction(
      double initialRupees, double initialUnits) async {
    final txDao = ref.read(transactionsDaoProvider);
    final primary = await txDao.getPrimaryTransactionForItem(
      widget.holding.profileId,
      widget.holding.id,
    );

    if (mounted) {
      setState(() {
        _primaryTx = primary;
        if (primary != null) {
          if (primary.unitPriceMicroPaise != null &&
              primary.unitPriceMicroPaise! > 0) {
            _purchaseNavController.text =
                FinancialPrecision.microPaiseToNav(primary.unitPriceMicroPaise!)
                    .toStringAsFixed(4);
          }
          _purchaseDate = primary.transactionDate;
          if ((primary.notes ?? '').isNotEmpty) {
            _notesController.text = primary.notes!;
          }
        }

        // If purchase NAV still empty, estimate from amount/units
        if (_purchaseNavController.text.isEmpty) {
          if (initialUnits > 0 && initialRupees > 0) {
            final impliedNav = initialRupees / initialUnits;
            _purchaseNavController.text = impliedNav.toStringAsFixed(4);
          } else {
            _purchaseNavController.text = '100.0000';
          }
        }

        _isLoading = false;
      });
    }
  }

  void _updateUnitsFromAmount() {
    if (_isSyncingFields) return;
    _isSyncingFields = true;
    final amountRupees = double.tryParse(_amountController.text) ?? 0.0;
    final purchaseNav = double.tryParse(_purchaseNavController.text) ?? 0.0;

    if (purchaseNav > 0) {
      final navMicro = FinancialPrecision.navToMicroPaise(purchaseNav);
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: FinancialPrecision.rupeesToPaise(amountRupees),
        navMicroPaise: navMicro,
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

    return AlertDialog(
      title: const Text('Edit Holding Details'),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.holding.name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),

                  // Invested Amount
                  Text(
                    'Total Invested Capital (INR)',
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
                    ),
                    onChanged: (_) => _updateUnitsFromAmount(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Purchase NAV
                  Text(
                    'Purchase / Average NAV (INR)',
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
                    ),
                    onChanged: (_) => _onPurchaseNavChanged(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Units Allotted
                  Text(
                    'Total Units Held',
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
                    ),
                    onChanged: (_) => _updateAmountFromUnits(),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Purchase Date
                  Text(
                    'Purchase / Record Date',
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
                    'Notes',
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. Corrected units from CAMS statement',
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
          onPressed: _isSaving || _isLoading ? null : _saveHoldingChanges,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save Changes'),
        ),
      ],
    );
  }

  Future<void> _saveHoldingChanges() async {
    setState(() => _isSaving = true);

    try {
      final itemsDao = ref.read(financialItemsDaoProvider);
      final txDao = ref.read(transactionsDaoProvider);
      final mfDao = ref.read(mutualFundDaoProvider);

      final amountRupees = double.tryParse(_amountController.text) ?? 0.0;
      final units = double.tryParse(_unitsController.text) ?? 0.0;
      final purchaseNavRupees =
          double.tryParse(_purchaseNavController.text) ?? 0.0;

      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final unitsMicro = FinancialPrecision.unitsToMicroUnits(units);
      final purchaseNavMicro =
          FinancialPrecision.navToMicroPaise(purchaseNavRupees);

      // Determine latest NAV to compute current market valuation
      int latestNavMicro = purchaseNavMicro;
      if (widget.holding.externalCode != null) {
        final code = int.tryParse(widget.holding.externalCode!);
        if (code != null) {
          final scheme = await mfDao.getSchemeByCode(code);
          if (scheme?.latestNavMicroPaise != null &&
              scheme!.latestNavMicroPaise! > 0) {
            latestNavMicro = scheme.latestNavMicroPaise!;
          }
        }
      }

      final newValuationPaise = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro,
        navMicroPaise: latestNavMicro,
      );

      final notes = _notesController.text.trim();

      // 1. Update the existing FinancialItem record (never duplicate)
      await itemsDao.updateItem(
        widget.holding.copyWith(
          initialValuePaise: amountPaise,
          currentValuationPaise: newValuationPaise,
          unitCountMicroUnits: unitsMicro,
          startDate: drift.Value(_purchaseDate),
          notes: drift.Value(notes.isNotEmpty ? notes : null),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      // 2. Update or insert the corresponding transaction
      if (_primaryTx != null) {
        await txDao.updateTransaction(
          _primaryTx!.copyWith(
            amountPaise: amountPaise,
            unitsMicroUnits: drift.Value(unitsMicro),
            unitPriceMicroPaise: drift.Value(purchaseNavMicro),
            transactionDate: _purchaseDate,
            notes: drift.Value(notes.isNotEmpty ? notes : null),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      } else {
        await txDao.insertTransaction(
          TransactionsCompanion(
            profileId: drift.Value(widget.holding.profileId),
            transactionType: const drift.Value('investment_purchase'),
            categoryId: drift.Value(widget.holding.categoryId),
            financialItemId: drift.Value(widget.holding.id),
            transactionDate: drift.Value(_purchaseDate),
            amountPaise: drift.Value(amountPaise),
            unitsMicroUnits: drift.Value(unitsMicro),
            unitPriceMicroPaise: drift.Value(purchaseNavMicro),
            source: const drift.Value('manual'),
            notes: drift.Value(notes.isNotEmpty ? notes : null),
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Updated "${widget.holding.name}" holding details successfully!'),
            backgroundColor: AppColors.asset,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update holding: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
