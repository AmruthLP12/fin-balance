import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen dedicated page for editing an existing mutual fund holding's metadata,
/// initial invested cost, units, purchase NAV, date, and user remarks.
class EditHoldingScreen extends ConsumerStatefulWidget {
  final FinancialItem holding;

  const EditHoldingScreen({super.key, required this.holding});

  static Future<bool?> push(BuildContext context, FinancialItem holding) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditHoldingScreen(holding: holding),
      ),
    );
  }

  @override
  ConsumerState<EditHoldingScreen> createState() => _EditHoldingScreenState();
}

class _EditHoldingScreenState extends ConsumerState<EditHoldingScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _amountController;
  late TextEditingController _unitsController;
  late TextEditingController _purchaseNavController;
  late TextEditingController _notesController;
  late DateTime _purchaseDate;

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

    double impliedNav = 100.0;
    if (initialUnits > 0 && initialRupees > 0) {
      impliedNav = initialRupees / initialUnits;
    }
    _purchaseNavController =
        TextEditingController(text: impliedNav.toStringAsFixed(4));
    _notesController = TextEditingController(text: widget.holding.notes ?? '');
    _purchaseDate = widget.holding.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _unitsController.dispose();
    _purchaseNavController.dispose();
    _notesController.dispose();
    super.dispose();
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
      _unitsController.text = units.toStringAsFixed(4);
    }
    _isSyncingFields = false;
  }

  void _updateAmountFromUnits() {
    if (_isSyncingFields) return;
    _isSyncingFields = true;
    final units = double.tryParse(_unitsController.text) ?? 0.0;
    final purchaseNav = double.tryParse(_purchaseNavController.text) ?? 0.0;

    if (purchaseNav > 0) {
      final amount = units * purchaseNav;
      _amountController.text = amount.toStringAsFixed(2);
    }
    _isSyncingFields = false;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() => _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final amountRupees = double.parse(_amountController.text.trim());
      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final unitsDouble = double.parse(_unitsController.text.trim());
      final unitsMicro = FinancialPrecision.unitsToMicroUnits(unitsDouble);
      final notes = _notesController.text.trim();

      // Recalculate latest valuation using scheme's latest NAV
      final db = ref.read(databaseProvider);
      final schemeCode = int.tryParse(widget.holding.externalCode ?? '');
      int latestNavMicro = 100000000;
      if (schemeCode != null) {
        final scheme = await db.mutualFundDao.getSchemeByCode(schemeCode);
        if (scheme != null &&
            scheme.latestNavMicroPaise != null &&
            scheme.latestNavMicroPaise! > 0) {
          latestNavMicro = scheme.latestNavMicroPaise!;
        }
      }

      final newValuation = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro,
        navMicroPaise: latestNavMicro,
      );

      final updatedHolding = widget.holding.copyWith(
        initialValuePaise: amountPaise,
        unitCountMicroUnits: unitsMicro,
        currentValuationPaise: newValuation,
        startDate: drift.Value(_purchaseDate),
        notes: drift.Value(notes.isNotEmpty ? notes : null),
        updatedAt: DateTime.now().toUtc(),
      );

      await db.financialItemsDao.updateItem(updatedHolding);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Holding updated successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving holding: $e'),
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
        title: const Text('Edit Holding'),
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
                          strokeWidth: 2, color: Colors.white),
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
                    // Scheme info card
                    FinCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.holding.name,
                            style: AppTypography.titleMedium
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (widget.holding.externalCode != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Scheme Code: ${widget.holding.externalCode}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Explanation Notice
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.brandPrimary.withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        border: Border.all(
                            color:
                                AppColors.brandPrimary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 18, color: AppColors.brandPrimary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Updating units or initial cost directly adjusts your holding balance and returns. Existing transaction records are strictly preserved.',
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

                    // Investment Date Field
                    Text(
                      'Purchase / Start Date',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    InkWell(
                      onTap: _selectDate,
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
                              DateFormatter.formatDate(_purchaseDate),
                              style: AppTypography.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Purchase NAV Field
                    Text(
                      'Purchase NAV (₹)',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _purchaseNavController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 105.4200',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateUnitsFromAmount(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter purchase NAV';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n <= 0) {
                          return 'Must be a positive NAV';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Total Invested Amount Field
                    Text(
                      'Total Invested Cost (₹)',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 5000.00',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateUnitsFromAmount(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter invested amount';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n < 0) return 'Must be a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Total Units Field
                    Text(
                      'Total Units Held',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _unitsController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'e.g. 47.4290',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _updateAmountFromUnits(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter units held';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n < 0) {
                          return 'Must be a non-negative number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Personal Remarks / Notes
                    Text(
                      'Personal Remarks / Notes',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText:
                            'Optional personal context, investment goal, or holding notes...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Save Button in body for convenience
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save Changes'),
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
