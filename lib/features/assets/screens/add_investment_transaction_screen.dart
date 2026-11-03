import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Full-screen form for adding an authoritative investment transaction:
/// Purchase, SIP, IDCW Reinvestment, IDCW Payout, Redemption, SWP, Switch In, Switch Out.
class AddInvestmentTransactionScreen extends ConsumerStatefulWidget {
  final FinancialItem holding;
  final List<SipPlan> sips;

  const AddInvestmentTransactionScreen({
    super.key,
    required this.holding,
    this.sips = const [],
  });

  static Future<bool?> push(
    BuildContext context, {
    required FinancialItem holding,
    List<SipPlan> sips = const [],
  }) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddInvestmentTransactionScreen(
          holding: holding,
          sips: sips,
        ),
      ),
    );
  }

  @override
  ConsumerState<AddInvestmentTransactionScreen> createState() =>
      _AddInvestmentTransactionScreenState();
}

class _AddInvestmentTransactionScreenState
    extends ConsumerState<AddInvestmentTransactionScreen> {
  final _formKey = GlobalKey<FormState>();

  String _selectedType = 'investment_purchase';
  late DateTime _transactionDate;

  late TextEditingController _amountController;
  late TextEditingController _navController;
  late TextEditingController _unitsController;
  late TextEditingController _chargesController;
  late TextEditingController _notesController;

  int? _selectedSipId;
  int? _selectedLinkedHoldingId;
  bool _isSaving = false;
  bool _isSyncing = false;

  final Map<String, String> _typeLabels = {
    'investment_purchase': 'One-time Investment / Purchase',
    'sip_investment': 'SIP Investment',
    'dividend_reinvestment': 'Dividend — Units (IDCW Reinvestment)',
    'dividend_payout': 'Dividend — Amount (IDCW Payout)',
    'redemption': 'Redemption',
    'swp_withdrawal': 'SWP Withdrawal',
    'switch_in': 'Switch In',
    'switch_out': 'Switch Out',
  };

  @override
  void initState() {
    super.initState();
    _transactionDate = DateTime.now();
    _amountController = TextEditingController(text: '1000');
    _navController = TextEditingController(text: '100.0000');
    _unitsController = TextEditingController(text: '10.0000');
    _chargesController = TextEditingController(text: '0.00');
    _notesController = TextEditingController();

    if (widget.sips.isNotEmpty) {
      _selectedSipId = widget.sips.first.id;
    }

    _loadInitialNav();
  }

  Future<void> _loadInitialNav() async {
    final schemeCode = int.tryParse(widget.holding.externalCode ?? '');
    if (schemeCode != null && schemeCode > 0) {
      final db = ref.read(databaseProvider);
      final scheme = await db.mutualFundDao.getSchemeByCode(schemeCode);
      if (scheme != null &&
          scheme.latestNavMicroPaise != null &&
          scheme.latestNavMicroPaise! > 0 &&
          mounted) {
        final nav =
            FinancialPrecision.microPaiseToNav(scheme.latestNavMicroPaise!);
        setState(() {
          _navController.text = nav.toStringAsFixed(4);
          _syncUnitsFromAmount();
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _navController.dispose();
    _unitsController.dispose();
    _chargesController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncUnitsFromAmount() {
    if (_isSyncing) return;
    _isSyncing = true;
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final nav = double.tryParse(_navController.text.trim()) ?? 0.0;
    if (nav > 0 && amt >= 0) {
      final units = amt / nav;
      _unitsController.text = units.toStringAsFixed(4);
    }
    _isSyncing = false;
  }

  void _syncAmountFromUnits() {
    if (_isSyncing) return;
    _isSyncing = true;
    final units = double.tryParse(_unitsController.text.trim()) ?? 0.0;
    final nav = double.tryParse(_navController.text.trim()) ?? 0.0;
    if (nav > 0 && units >= 0) {
      final amt = units * nav;
      _amountController.text = amt.toStringAsFixed(2);
    }
    _isSyncing = false;
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && mounted) {
      setState(() => _transactionDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final db = ref.read(databaseProvider);
      final txDao = ref.read(transactionsDaoProvider);

      final grossAmountRupees = double.parse(_amountController.text.trim());
      final grossAmountPaise =
          FinancialPrecision.rupeesToPaise(grossAmountRupees);

      final chargesRupees =
          double.tryParse(_chargesController.text.trim()) ?? 0.0;
      final chargesPaise = FinancialPrecision.rupeesToPaise(chargesRupees);

      final navDouble = double.tryParse(_navController.text.trim()) ?? 0.0;
      final navMicroPaise = FinancialPrecision.navToMicroPaise(navDouble);

      final unitsDouble = double.tryParse(_unitsController.text.trim()) ?? 0.0;
      final unitsMicro = FinancialPrecision.unitsToMicroUnits(unitsDouble);

      final notes = _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null;

      // Handle Switch between holdings
      if ((_selectedType == 'switch_in' || _selectedType == 'switch_out') &&
          _selectedLinkedHoldingId != null) {
        final sourceId = _selectedType == 'switch_out'
            ? widget.holding.id
            : _selectedLinkedHoldingId!;
        final destId = _selectedType == 'switch_in'
            ? widget.holding.id
            : _selectedLinkedHoldingId!;

        final destHolding = await db.financialItemsDao.getItemById(destId);
        int destNavMicro = navMicroPaise;
        if (destHolding != null) {
          final sCode = int.tryParse(destHolding.externalCode ?? '');
          if (sCode != null) {
            final s = await db.mutualFundDao.getSchemeByCode(sCode);
            if (s != null &&
                s.latestNavMicroPaise != null &&
                s.latestNavMicroPaise! > 0) {
              destNavMicro = s.latestNavMicroPaise!;
            }
          }
        }

        final netTransferPaise = (grossAmountPaise - chargesPaise)
            .clamp(0, double.maxFinite.toInt());
        final destUnitsMicro = FinancialPrecision.calculateUnitsPurchased(
          amountPaise: netTransferPaise,
          navMicroPaise: destNavMicro,
        );

        await txDao.recordSwitchBetweenHoldings(
          profileId: widget.holding.profileId,
          sourceItemId: sourceId,
          destItemId: destId,
          categoryId: widget.holding.categoryId,
          transactionDate: _transactionDate,
          switchAmountPaise: grossAmountPaise,
          chargesPaise: chargesPaise,
          sourceUnitsMicroUnits: unitsMicro,
          sourceNavMicroPaise: navMicroPaise,
          destUnitsMicroUnits: destUnitsMicro,
          destNavMicroPaise: destNavMicro,
          notes: notes,
        );
      } else {
        // Standard single investment transaction
        await txDao.recordInvestmentTransaction(
          profileId: widget.holding.profileId,
          financialItemId: widget.holding.id,
          categoryId: widget.holding.categoryId,
          transactionType: _selectedType,
          transactionDate: _transactionDate,
          amountPaise: grossAmountPaise,
          chargesPaise: chargesPaise,
          unitsMicroUnits: unitsMicro,
          unitPriceMicroPaise: navMicroPaise,
          sipPlanId: _selectedType == 'sip_investment' ? _selectedSipId : null,
          notes: notes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction recorded successfully.')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
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

    final isRedemptionLike = _selectedType == 'redemption' ||
        _selectedType == 'swp_withdrawal' ||
        _selectedType == 'switch_out';

    final isDividendPayout = _selectedType == 'dividend_payout';
    final isDividendReinvest = _selectedType == 'dividend_reinvestment';

    final allHoldingsAsync = ref.watch(activeProfileAssetsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Investment Transaction'),
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
                    // Holding info banner
                    FinCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.holding.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Current Units: ${availableUnits.toStringAsFixed(4)} • Value: ${CurrencyFormatter.formatPaise(widget.holding.currentValuationPaise)}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Transaction Type Selector
                    Text(
                      'Transaction Type',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      isExpanded: true,
                      items: _typeLabels.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Linked SIP selector if SIP type
                    if (_selectedType == 'sip_investment' &&
                        widget.sips.isNotEmpty) ...[
                      Text(
                        'Linked SIP Schedule Period',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      DropdownButtonFormField<int>(
                        initialValue: _selectedSipId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items: widget.sips.map((sip) {
                          return DropdownMenuItem(
                            value: sip.id,
                            child: Text('${sip.name} (${sip.status})'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSipId = val),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Linked Holding Selector if Switch
                    if (_selectedType == 'switch_in' ||
                        _selectedType == 'switch_out') ...[
                      Text(
                        _selectedType == 'switch_in'
                            ? 'Source Holding (Switching Out From)'
                            : 'Destination Holding (Switching In To)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      allHoldingsAsync.when(
                        data: (holdings) {
                          final otherHoldings = holdings
                              .where((h) => h.id != widget.holding.id)
                              .toList();
                          return DropdownButtonFormField<int?>(
                            initialValue: _selectedLinkedHoldingId,
                            decoration: const InputDecoration(
                              hintText:
                                  'Select other holding (or None/External)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('External Fund / Not Tracked'),
                              ),
                              ...otherHoldings
                                  .map((h) => DropdownMenuItem<int?>(
                                        value: h.id,
                                        child: Text(h.name),
                                      )),
                            ],
                            onChanged: (val) =>
                                setState(() => _selectedLinkedHoldingId = val),
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Transaction Date
                    Text(
                      'Transaction Date',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                              DateFormatter.formatDate(_transactionDate),
                              style: AppTypography.bodyMedium,
                            ),
                            const Icon(Icons.calendar_today_rounded, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Amount Field
                    Text(
                      isDividendPayout
                          ? 'Dividend Amount (₹)'
                          : (isDividendReinvest
                              ? 'Reinvested Dividend Value (₹)'
                              : (isRedemptionLike
                                  ? 'Gross Redemption Amount (₹)'
                                  : 'Investment Amount (₹)')),
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
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _syncUnitsFromAmount(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final n = double.tryParse(value.trim());
                        if (n == null || n < 0) return 'Must be a valid amount';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // NAV Field (hidden only if dividend payout where NAV does not matter)
                    if (!isDividendPayout) ...[
                      Text(
                        'Applicable NAV (₹)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _navController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _syncUnitsFromAmount(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter NAV';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Must be positive NAV';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Units Field
                      Text(
                        isRedemptionLike
                            ? 'Units Being Redeemed'
                            : 'Units Allotted / Received',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      TextFormField(
                        controller: _unitsController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          helperText: isRedemptionLike
                              ? 'Available: ${availableUnits.toStringAsFixed(4)} units'
                              : null,
                        ),
                        onChanged: (_) => _syncAmountFromUnits(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter units';
                          }
                          final n = double.tryParse(value.trim());
                          if (n == null || n <= 0) {
                            return 'Must be greater than 0';
                          }
                          if (isRedemptionLike && n > availableUnits + 0.0001) {
                            return 'Cannot redeem more than available (${availableUnits.toStringAsFixed(4)} units)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Mandatory Section 6: Charges Field (Optional, default 0)
                    Text(
                      'Transaction Charges / Fees (₹)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _chargesController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        hintText: '0.00',
                        border: const OutlineInputBorder(),
                        helperText: isRedemptionLike
                            ? 'Charges are deducted from gross proceeds.'
                            : 'Charges increase effective cash outflow.',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final n = double.tryParse(value.trim());
                        if (n == null || n < 0) return 'Must be non-negative';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Notes / Remarks
                    Text(
                      'Notes / Remarks (Optional)',
                      style: AppTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'e.g. STT paid, quarterly rebalance, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Record Transaction'),
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
