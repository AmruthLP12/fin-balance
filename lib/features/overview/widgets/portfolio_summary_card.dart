import 'package:flutter/material.dart';
import '../../../core/calculations/financial_calculator.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../database/app_database.dart';

/// One-glance totals for every active asset of the profile: invested, current, P&L, return, XIRR.
class PortfolioSummaryCard extends StatelessWidget {
  final List<FinancialItem> activeAssets;
  final List<Transaction> transactions;

  const PortfolioSummaryCard({
    super.key,
    required this.activeAssets,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    if (activeAssets.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final invested =
        activeAssets.fold<int>(0, (s, a) => s + a.initialValuePaise);
    final current =
        activeAssets.fold<int>(0, (s, a) => s + a.currentValuationPaise);
    final pnl = FinancialCalculator.calculateProfitLossPaise(
        investedPaise: invested, currentValuationPaise: current);
    final returnPct = FinancialCalculator.calculateAbsoluteReturn(
        investedPaise: invested, currentValuationPaise: current);
    final ids = activeAssets.map((a) => a.id).toSet();
    final xirr = FinancialCalculator.calculatePortfolioXirr(
      transactions: transactions
          .where((t) =>
              t.financialItemId != null && ids.contains(t.financialItemId))
          .toList(),
      totalValuationPaise: current,
    );

    final color = pnl >= 0 ? AppColors.asset : AppColors.liability;
    final sign = pnl >= 0 ? '+' : '-';

    Widget stat(String label, String value, {Color? valueColor}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTypography.labelSmall.copyWith(color: muted)),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: AppTypography.amountMedium.copyWith(
                        color: valueColor, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: FinCard(
        child: Column(
          children: [
            Row(children: [
              stat('Invested', CurrencyFormatter.formatPaise(invested)),
              stat('Current value', CurrencyFormatter.formatPaise(current)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              stat('Profit / Loss',
                  '$sign${CurrencyFormatter.formatPaise(pnl.abs())}',
                  valueColor: color),
              stat('Return', '$sign${returnPct.abs().toStringAsFixed(2)}%',
                  valueColor: color),
              stat('XIRR', xirr == null ? '—' : '${xirr.toStringAsFixed(2)}%',
                  valueColor: xirr == null
                      ? null
                      : (xirr >= 0 ? AppColors.asset : AppColors.liability)),
            ]),
          ],
        ),
      ),
    );
  }
}
