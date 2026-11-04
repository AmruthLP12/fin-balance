import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../database/app_database.dart';

/// Every active asset and liability of the profile with its current amount; rows are tappable.
class HoldingsListCard extends StatelessWidget {
  final List<FinancialItem> assets;
  final List<FinancialItem> liabilities;
  final ValueChanged<FinancialItem> onTap;

  const HoldingsListCard({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.onTap,
  });

  static String _typeLabel(String subType) => switch (subType) {
        'mutual_fund' => 'Mutual Fund',
        'stock' => 'Stock / ETF',
        'fixed_deposit' => 'Fixed Deposit',
        'gold' => 'Gold',
        _ => subType.replaceAll('_', ' '),
      };

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty && liabilities.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    Widget section(String title, List<FinancialItem> items, Color color) {
      final total = items.fold<int>(0, (s, i) => s + i.currentValuationPaise);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            badge: Text(CurrencyFormatter.formatPaise(total),
                style: AppTypography.labelMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(items[i].name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(_typeLabel(items[i].subType),
                        style: AppTypography.labelSmall.copyWith(color: muted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            CurrencyFormatter.formatPaise(
                                items[i].currentValuationPaise),
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: muted),
                      ],
                    ),
                    onTap: () => onTap(items[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assets.isNotEmpty) section('Assets', assets, AppColors.asset),
        if (assets.isNotEmpty && liabilities.isNotEmpty)
          const SizedBox(height: 16),
        if (liabilities.isNotEmpty)
          section('Liabilities', liabilities, AppColors.liability),
      ],
    );
  }
}
