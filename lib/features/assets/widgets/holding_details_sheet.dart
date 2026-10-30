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
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';
import 'add_to_profile_dialog.dart';
import 'edit_holding_dialog.dart';

/// Modal bottom sheet displaying detailed holding statistics, valuation, transaction history,
/// and live NAV sync for a specific mutual fund asset holding.
class HoldingDetailsSheet extends ConsumerStatefulWidget {
  final FinancialItem holding;

  const HoldingDetailsSheet({super.key, required this.holding});

  @override
  ConsumerState<HoldingDetailsSheet> createState() =>
      _HoldingDetailsSheetState();
}

class _HoldingDetailsSheetState extends ConsumerState<HoldingDetailsSheet> {
  bool _isSyncingNav = false;

  int? get _schemeCode => widget.holding.externalCode != null
      ? int.tryParse(widget.holding.externalCode!)
      : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Watch live holding data
    final itemsAsync = ref.watch(activeProfileAssetsProvider);
    final currentItem = itemsAsync.value?.firstWhere(
          (i) => i.id == widget.holding.id,
          orElse: () => widget.holding,
        ) ??
        widget.holding;

    // Watch cached scheme data
    final schemeAsync = _schemeCode != null
        ? ref.watch(schemeByCodeProvider(_schemeCode!))
        : const AsyncValue<MutualFundScheme?>.data(null);
    final scheme = schemeAsync.value;

    // Transactions for this holding
    final transactionsAsync = ref.watch(transactionsByItemProvider(
      (profileId: currentItem.profileId, itemId: currentItem.id),
    ));

    // Valuation calculations
    final investedPaise = currentItem.initialValuePaise;
    final currentValuationPaise = currentItem.currentValuationPaise;
    final gainPaise = currentValuationPaise - investedPaise;
    final returnPercent =
        investedPaise > 0 ? (gainPaise / investedPaise) * 100.0 : 0.0;
    final isPositive = gainPaise >= 0;
    final units =
        FinancialPrecision.microUnitsToUnits(currentItem.unitCountMicroUnits);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: AppSpacing.screenPadding,
                  children: [
                    // Scheme Name & Subtitle
                    Text(
                      currentItem.name,
                      style: AppTypography.headlineMedium
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    if (scheme?.fundHouse != null)
                      Text(
                        scheme!.fundHouse!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    const SizedBox(height: AppSpacing.sm),

                    // Badges
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        const StatusBadge(
                          label: 'Mutual Fund',
                          type: BadgeType.asset,
                        ),
                        if (scheme?.planType != null)
                          StatusBadge(
                            label: scheme!.planType!,
                            type: BadgeType.brand,
                          ),
                        if (scheme?.optionType != null)
                          StatusBadge(
                            label: scheme!.optionType!,
                            type: BadgeType.neutral,
                          ),
                        if (scheme?.schemeCategory != null)
                          StatusBadge(
                            label: scheme!.schemeCategory!,
                            type: BadgeType.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Valuation Hero Card
                    FinCard(
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'CURRENT VALUATION (ESTIMATED)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_schemeCode != null)
                                IconButton(
                                  icon: _isSyncingNav
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.refresh_rounded,
                                          size: 20),
                                  tooltip: 'Sync Latest NAV',
                                  onPressed:
                                      _isSyncingNav ? null : _syncHoldingNav,
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            CurrencyFormatter.formatPaise(
                                currentValuationPaise),
                            style: AppTypography.heroAmount.copyWith(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),

                          // Returns & Invested
                          Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.xs,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isPositive
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 16,
                                    color: isPositive
                                        ? AppColors.asset
                                        : AppColors.liability,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${isPositive ? '+' : ''}${CurrencyFormatter.formatPaise(gainPaise)} (${returnPercent.toStringAsFixed(2)}%)',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: isPositive
                                          ? AppColors.asset
                                          : AppColors.liability,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Invested: ${CurrencyFormatter.formatPaise(investedPaise)}',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: AppSpacing.lg),

                          // Units & NAV Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Units Held',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                    ),
                                  ),
                                  Text(
                                    units.toStringAsFixed(3),
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              if (scheme?.latestNavMicroPaise != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Latest NAV (${scheme?.latestNavDate != null ? DateFormatter.formatDate(scheme!.latestNavDate!) : "Live"})',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                      ),
                                    ),
                                    Text(
                                      '₹${FinancialPrecision.microPaiseToNav(scheme!.latestNavMicroPaise!).toStringAsFixed(4)}',
                                      style: AppTypography.titleMedium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.edit_rounded, size: 18),
                            label: const Text('Edit Holding'),
                            onPressed: () =>
                                _openEditHoldingDialog(currentItem),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add Purchase'),
                            onPressed: () =>
                                _openAddPurchaseDialog(currentItem),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Transactions History Section
                    Text(
                      'Transaction History',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    transactionsAsync.when(
                      data: (txs) {
                        if (txs.isEmpty) {
                          return FinCard(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'No individual transactions recorded for this holding.',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                            ),
                          );
                        }

                        return FinCard(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: txs.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final tx = txs[index];
                              final isPurchase =
                                  tx.transactionType == 'investment_purchase';
                              final txUnits = tx.unitsMicroUnits != null
                                  ? FinancialPrecision.microUnitsToUnits(
                                      tx.unitsMicroUnits!)
                                  : null;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          DateFormatter.formatDate(
                                              tx.transactionDate),
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          isPurchase
                                              ? 'Purchase'
                                              : 'Redemption',
                                          style:
                                              AppTypography.bodySmall.copyWith(
                                            color: isPurchase
                                                ? AppColors.asset
                                                : AppColors.liability,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (txUnits != null)
                                          Text(
                                            '${txUnits.toStringAsFixed(3)} units',
                                            style: AppTypography.bodySmall,
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          CurrencyFormatter.formatPaise(
                                              tx.amountPaise),
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (tx.unitPriceMicroPaise != null)
                                          Text(
                                            'NAV: ₹${FinancialPrecision.microPaiseToNav(tx.unitPriceMicroPaise!).toStringAsFixed(4)}',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: isDark
                                                  ? AppColors.darkTextMuted
                                                  : AppColors.lightTextMuted,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, _) =>
                          Text('Error loading transactions: $err'),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Danger zone: Delete holding
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.liability,
                        side: BorderSide(
                          color: AppColors.liability.withValues(alpha: 0.5),
                        ),
                      ),
                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                      label: const Text('Delete / Remove Holding'),
                      onPressed: () {
                        _confirmDelete(currentItem);
                      },
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _syncHoldingNav() async {
    final code = _schemeCode;
    if (code == null) return;

    setState(() => _isSyncingNav = true);
    try {
      final syncService = ref.read(navSyncServiceProvider);
      final res = await syncService.syncSchemeNav(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.success
                ? 'Updated NAV for ${res.schemeName} (${res.provider ?? "MFapi"})'
                : 'NAV sync notice: ${res.errorMessage ?? "Offline"}'),
            backgroundColor: res.success ? AppColors.asset : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync NAV: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingNav = false);
    }
  }

  void _openEditHoldingDialog(FinancialItem holding) {
    showDialog<void>(
      context: context,
      builder: (_) => EditHoldingDialog(holding: holding),
    );
  }

  Future<void> _openAddPurchaseDialog(FinancialItem holding) async {
    final code = _schemeCode;
    if (code == null) return;

    final syncService = ref.read(navSyncServiceProvider);
    final detail = await syncService.getOrFetchSchemeDetails(code);
    if (detail != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => AddToProfileDialog(
          scheme: detail,
          preselectedProfileId: holding.profileId,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load scheme metadata for new purchase.'),
        ),
      );
    }
  }

  Future<void> _confirmDelete(FinancialItem holding) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holding?'),
        content: Text(
          'Are you sure you want to remove "${holding.name}" from this profile? All associated investment records will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final itemsDao = ref.read(financialItemsDaoProvider);
      await itemsDao.deleteItem(holding.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${holding.name}" holding.'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    }
  }
}
