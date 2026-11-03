import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/nav/models/nav_models.dart';
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
  MutualFundSearchResult? _selectedSwitchScheme;
  double? _switchSchemeNav;
  DateTime? _switchSchemeNavDate;
  String? _switchSchemeFundHouse;
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

  void _showTransactionHelp(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            final helpItems = [
              (
                title: 'One-time Investment / Purchase',
                desc:
                    'Lump-sum purchase of units using cash capital. Increases holding units and invested capital.',
                icon: Icons.add_shopping_cart_rounded,
                color: AppColors.brandPrimary,
              ),
              (
                title: 'SIP Investment',
                desc:
                    'Recurring automated installment credited towards your investment schedule period.',
                icon: Icons.alarm_on_rounded,
                color: AppColors.brandPrimary,
              ),
              (
                title: 'IDCW Reinvestment',
                desc:
                    'Dividend declared by the mutual fund scheme is used to purchase additional units. Increases units held with no cash payout.',
                icon: Icons.autorenew_rounded,
                color: AppColors.brandPrimary,
              ),
              (
                title: 'IDCW Payout',
                desc:
                    'Dividend paid directly as cash into your bank account. Recorded as an income inflow while your units held remain unchanged.',
                icon: Icons.payments_outlined,
                color: AppColors.asset,
              ),
              (
                title: 'Redemption',
                desc:
                    'Selling mutual fund units for cash back to your bank account. Reduces units held and generates cash inflow.',
                icon: Icons.money_off_csred_rounded,
                color: AppColors.asset,
              ),
              (
                title: 'SWP Withdrawal',
                desc:
                    'Systematic periodic withdrawal of cash or units from your holding into your bank account according to your schedule.',
                icon: Icons.outbox_rounded,
                color: AppColors.asset,
              ),
              (
                title: 'Switch Out',
                desc:
                    'Transferring units and capital out of this fund into another target fund scheme. Reduces units held here.',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.liability,
              ),
              (
                title: 'Switch In',
                desc:
                    'Transferring units and capital into this fund from another source fund scheme. Increases units held here.',
                icon: Icons.swap_horiz_rounded,
                color: AppColors.brandPrimary,
              ),
            ];

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction Type Explanations',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: helpItems.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, idx) {
                      final item = helpItems[idx];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBackground.withValues(alpha: 0.6)
                              : AppColors.lightBackground,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child:
                                  Icon(item.icon, size: 20, color: item.color),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.desc,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openSchemePicker() async {
    final picked = await showDialog<MutualFundSearchResult>(
      context: context,
      builder: (_) => const _SchemePickerSearchDialog(),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedSwitchScheme = picked;
        _switchSchemeFundHouse = picked.fundHouse;
      });

      // Fetch latest NAV for selected scheme
      try {
        final syncService = ref.read(navSyncServiceProvider);
        final details =
            await syncService.getOrFetchSchemeDetails(picked.schemeCode);
        if (details != null && details.latestNav != null && mounted) {
          setState(() {
            _switchSchemeNav = FinancialPrecision.microPaiseToNav(
                details.latestNav!.navMicroPaise);
            _switchSchemeNavDate = details.latestNav!.date;
            if (details.fundHouse != null) {
              _switchSchemeFundHouse = details.fundHouse;
            }
          });
        }
      } catch (_) {
        final db = ref.read(databaseProvider);
        final s = await db.mutualFundDao.getSchemeByCode(picked.schemeCode);
        if (s != null && s.latestNavMicroPaise != null && mounted) {
          setState(() {
            _switchSchemeNav =
                FinancialPrecision.microPaiseToNav(s.latestNavMicroPaise!);
            _switchSchemeNavDate = s.latestNavDate;
            if (s.fundHouse != null) {
              _switchSchemeFundHouse = s.fundHouse;
            }
          });
        }
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedType == 'switch_in' || _selectedType == 'switch_out') {
      if (_selectedSwitchScheme == null && _selectedLinkedHoldingId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedType == 'switch_out'
                  ? 'Please select the destination scheme to switch into.'
                  : 'Please select the source scheme to switch out from.',
            ),
            backgroundColor: AppColors.liability,
          ),
        );
        return;
      }
    }

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
      if (_selectedType == 'switch_in' || _selectedType == 'switch_out') {
        int targetHoldingId;
        String targetSchemeName = '';

        if (_selectedSwitchScheme != null) {
          targetSchemeName = _selectedSwitchScheme!.schemeName;
          final existing = await (db.select(db.financialItems)
                ..where((tbl) =>
                    tbl.profileId.equals(widget.holding.profileId) &
                    tbl.externalCode
                        .equals(_selectedSwitchScheme!.schemeCode.toString())))
              .get();

          if (existing.isNotEmpty) {
            targetHoldingId = existing.first.id;
          } else {
            // Auto-create new asset holding record with 0 initial contribution
            targetHoldingId = await db.financialItemsDao.insertItem(
              FinancialItemsCompanion(
                profileId: drift.Value(widget.holding.profileId),
                categoryId: drift.Value(widget.holding.categoryId),
                name: drift.Value(_selectedSwitchScheme!.schemeName),
                itemType: const drift.Value('asset'),
                subType: const drift.Value('mutual_fund'),
                externalCode:
                    drift.Value(_selectedSwitchScheme!.schemeCode.toString()),
                notes: drift.Value(_switchSchemeFundHouse ??
                    _selectedSwitchScheme!.fundHouse ??
                    'Direct Mutual Fund'),
                initialValuePaise: const drift.Value(0),
                currentValuationPaise: const drift.Value(0),
                unitCountMicroUnits: const drift.Value(0),
                startDate: drift.Value(_transactionDate),
                status: const drift.Value('active'),
              ),
            );
          }
        } else {
          targetHoldingId = _selectedLinkedHoldingId!;
          final h = await db.financialItemsDao.getItemById(targetHoldingId);
          targetSchemeName = h?.name ?? 'Other Scheme';
        }

        final sourceId =
            _selectedType == 'switch_out' ? widget.holding.id : targetHoldingId;
        final destId =
            _selectedType == 'switch_in' ? widget.holding.id : targetHoldingId;
        final sourceName = _selectedType == 'switch_out'
            ? widget.holding.name
            : targetSchemeName;
        final destName = _selectedType == 'switch_in'
            ? widget.holding.name
            : targetSchemeName;

        int destNavMicro = navMicroPaise;
        if (_switchSchemeNav != null && _switchSchemeNav! > 0) {
          destNavMicro = FinancialPrecision.navToMicroPaise(_switchSchemeNav!);
        } else {
          final destHolding = await db.financialItemsDao.getItemById(destId);
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
        }

        final sNav =
            _selectedType == 'switch_out' ? navMicroPaise : destNavMicro;
        final dNav =
            _selectedType == 'switch_in' ? navMicroPaise : destNavMicro;

        final netTransferPaise = (grossAmountPaise - chargesPaise)
            .clamp(0, double.maxFinite.toInt());
        final destUnitsMicro = FinancialPrecision.calculateUnitsPurchased(
          amountPaise: netTransferPaise,
          navMicroPaise: dNav,
        );
        final sourceUnitsMicro = _selectedType == 'switch_out'
            ? unitsMicro
            : FinancialPrecision.calculateUnitsPurchased(
                amountPaise: grossAmountPaise,
                navMicroPaise: sNav,
              );

        final sNotes = notes != null
            ? '$notes • Switched out to $destName'
            : 'Switched out to $destName';
        final dNotes = notes != null
            ? '$notes • Switched in from $sourceName'
            : 'Switched in from $sourceName';

        await txDao.recordSwitchBetweenHoldings(
          profileId: widget.holding.profileId,
          sourceItemId: sourceId,
          destItemId: destId,
          categoryId: widget.holding.categoryId,
          transactionDate: _transactionDate,
          switchAmountPaise: grossAmountPaise,
          chargesPaise: chargesPaise,
          sourceUnitsMicroUnits: sourceUnitsMicro,
          sourceNavMicroPaise: sNav,
          destUnitsMicroUnits: destUnitsMicro,
          destNavMicroPaise: dNav,
          sourceNotes: sNotes,
          destNotes: dNotes,
        );

        ref.invalidate(activeProfileAssetsProvider);
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

                    // Transaction Type Selector with Contextual Help
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction Type',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.help_outline_rounded,
                              size: 16, color: AppColors.brandPrimary),
                          label: const Text(
                            'Explain Types',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              _showTransactionHelp(context, isDark),
                        ),
                      ],
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

                    // Linked Scheme Selector if Switch
                    if (_selectedType == 'switch_in' ||
                        _selectedType == 'switch_out') ...[
                      Text(
                        _selectedType == 'switch_in'
                            ? 'Source Scheme (Switching Out From)'
                            : 'Destination Scheme (Switching In To)',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      if (_selectedSwitchScheme == null) ...[
                        OutlinedButton.icon(
                          icon: const Icon(Icons.search_rounded),
                          label: Text(
                            _selectedType == 'switch_in'
                                ? 'Search & Select Source Scheme'
                                : 'Search & Select Destination Scheme',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: _openSchemePicker,
                        ),
                      ] else ...[
                        allHoldingsAsync.when(
                          data: (holdings) {
                            final isExisting = holdings.any((h) =>
                                h.externalCode ==
                                _selectedSwitchScheme!.schemeCode.toString());

                            return FinCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _selectedSwitchScheme!.schemeName,
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 14),
                                        label: const Text('Change'),
                                        onPressed: _openSchemePicker,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _switchSchemeFundHouse ??
                                        _selectedSwitchScheme!.fundHouse ??
                                        'Direct Mutual Fund',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (_switchSchemeNav != null &&
                                          _switchSchemeNav! > 0)
                                        Text(
                                          'Latest NAV: ₹${_switchSchemeNav!.toStringAsFixed(4)}${_switchSchemeNavDate != null ? " (${DateFormatter.formatDate(_switchSchemeNavDate!)})" : ""}',
                                          style:
                                              AppTypography.labelSmall.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.brandPrimary,
                                          ),
                                        ),
                                      StatusBadge(
                                        label: isExisting
                                            ? 'PORTFOLIO HOLDING'
                                            : 'NEW HOLDING TO BE CREATED',
                                        type: isExisting
                                            ? BadgeType.asset
                                            : BadgeType.neutral,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
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

class _SchemePickerSearchDialog extends ConsumerStatefulWidget {
  const _SchemePickerSearchDialog();

  @override
  ConsumerState<_SchemePickerSearchDialog> createState() =>
      _SchemePickerSearchDialogState();
}

class _SchemePickerSearchDialogState
    extends ConsumerState<_SchemePickerSearchDialog> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultsAsync = _query.length >= 3
        ? ref.watch(schemeSearchResultsProvider(_query))
        : null;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search mutual fund scheme...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (val) => setState(() => _query = val.trim()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _query.length < 3
                  ? Center(
                      child: Text(
                        'Type at least 3 characters to search...',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    )
                  : resultsAsync?.when(
                        data: (results) {
                          if (results.isEmpty) {
                            return Center(
                              child: Text(
                                'No schemes found matching "$_query"',
                                style: AppTypography.bodySmall,
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: results.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (ctx, idx) {
                              final item = results[idx];
                              return ListTile(
                                title: Text(
                                  item.schemeName,
                                  style: AppTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  item.fundHouse ?? 'Direct Mutual Fund',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                trailing: const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14),
                                onTap: () => Navigator.pop(context, item),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(
                          child: Text(
                            'Error searching schemes: $e',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.liability),
                          ),
                        ),
                      ) ??
                      const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
