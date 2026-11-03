import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/calculations/financial_calculator.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';

/// Compact, elegant investment holding card designed to display essential performance
/// figures (Scheme Name, Invested, Current Value, IRR / P&L) without unnecessary clutter.
class HoldingCard extends ConsumerWidget {
  final FinancialItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const HoldingCard({
    super.key,
    required this.item,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final investedPaise = item.initialValuePaise;
    final currentValuationPaise = item.currentValuationPaise;
    final profitLossPaise = FinancialCalculator.calculateProfitLossPaise(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );
    final isProfit = profitLossPaise >= 0;

    final absoluteReturn = FinancialCalculator.calculateAbsoluteReturn(
      investedPaise: investedPaise,
      currentValuationPaise: currentValuationPaise,
    );

    // Watch transactions for accurate dated XIRR
    final transactionsAsync = ref.watch(transactionsByItemProvider(
      (profileId: item.profileId, itemId: item.id),
    ));
    final transactions = transactionsAsync.value ?? [];

    final schemeCode =
        item.externalCode != null ? int.tryParse(item.externalCode!) : null;
    final schemeAsync = schemeCode != null
        ? ref.watch(schemeByCodeProvider(schemeCode))
        : const AsyncValue<MutualFundScheme?>.data(null);
    final scheme = schemeAsync.value;

    final xirr = FinancialCalculator.calculateHoldingXirr(
      transactions: transactions,
      currentValuationPaise: currentValuationPaise,
      valuationDate: scheme?.latestNavDate,
    );

    final subtitle = scheme?.fundHouse ?? _formatSubType(item.subType);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        backgroundColor:
            isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Scheme Name & Return Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                StatusBadge(
                  label:
                      '${isProfit ? '+' : ''}${absoluteReturn.toStringAsFixed(1)}%',
                  type: isProfit ? BadgeType.asset : BadgeType.liability,
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 18),
                    tooltip: 'Holding options',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onSelected: (val) {
                      if (val == 'delete' && onDelete != null) {
                        onDelete!();
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded,
                                color: AppColors.liability, size: 18),
                            SizedBox(width: 8),
                            Text('Remove Holding',
                                style: TextStyle(color: AppColors.liability)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Compact Metrics Row: Invested | Current Value | IRR / P&L
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCompactMetric(
                  label: 'INVESTED',
                  value: CurrencyFormatter.formatPaise(investedPaise),
                  isDark: isDark,
                ),
                _buildCompactMetric(
                  label: 'CURRENT VALUE',
                  value: CurrencyFormatter.formatPaise(currentValuationPaise),
                  valueColor: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  isDark: isDark,
                ),
                _buildCompactMetric(
                  label: xirr != null ? 'IRR' : 'PROFIT / LOSS',
                  value: xirr != null
                      ? '${xirr.toStringAsFixed(1)}%'
                      : '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(profitLossPaise)}',
                  valueColor: isProfit ? AppColors.asset : AppColors.liability,
                  isDark: isDark,
                  crossAxisAlignment: CrossAxisAlignment.end,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactMetric({
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ??
                (isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary),
          ),
        ),
      ],
    );
  }

  String _formatSubType(String subType) {
    switch (subType) {
      case 'mutual_fund':
        return 'Mutual Fund';
      case 'stock':
        return 'Stock';
      case 'fixed_deposit':
        return 'Fixed Deposit';
      case 'gold':
        return 'Gold';
      case 'ppf':
        return 'PPF';
      case 'epf':
        return 'EPF';
      case 'gpf':
        return 'GPF';
      case 'nps':
        return 'NPS';
      case 'bond':
        return 'Bond';
      case 'cash':
        return 'Cash & Bank';
      default:
        return 'Asset';
    }
  }
}
