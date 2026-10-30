import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../../database/precision/financial_precision.dart';

/// Card widget rendering an individual asset / mutual fund holding.
class HoldingCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final investedPaise = item.initialValuePaise;
    final currentValuationPaise = item.currentValuationPaise;
    final returnPaise = currentValuationPaise - investedPaise;
    final isProfit = returnPaise >= 0;

    final returnPercent =
        investedPaise > 0 ? (returnPaise / investedPaise) * 100 : 0.0;

    final units = item.unitCountMicroUnits > 0
        ? FinancialPrecision.microUnitsToUnits(item.unitCountMicroUnits)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FinCard(
        backgroundColor:
            isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          StatusBadge(
                            label: _formatSubType(item.subType),
                            type: BadgeType.asset,
                          ),
                          if (item.externalCode != null) ...[
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              'Code: ${item.externalCode}',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, size: 20),
                    tooltip: 'Holding options',
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
                                color: AppColors.liability, size: 20),
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
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.sm),

            // Values Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT VALUE',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(currentValuationPaise),
                      style: AppTypography.cardAmount.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    if (units != null)
                      Text(
                        '${units.toStringAsFixed(3)} units',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'INVESTED / GAIN',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyFormatter.formatPaise(investedPaise),
                      style: AppTypography.cardAmount.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(returnPaise)} (${returnPercent >= 0 ? '+' : ''}${returnPercent.toStringAsFixed(2)}%)',
                      style: AppTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isProfit ? AppColors.asset : AppColors.liability,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSubType(String subType) {
    switch (subType) {
      case 'mutual_fund':
        return 'Mutual Fund';
      case 'stock':
        return 'Stock / ETF';
      case 'fixed_deposit':
        return 'Fixed Deposit';
      case 'gold':
        return 'Gold';
      case 'ppf':
        return 'PPF';
      case 'epf':
        return 'EPF';
      case 'nps':
        return 'NPS';
      default:
        return 'Asset';
    }
  }
}
