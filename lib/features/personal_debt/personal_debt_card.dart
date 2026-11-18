import 'package:flutter/material.dart';
import '../../core/formatting/currency_formatter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/fin_card.dart';
import '../../database/app_database.dart';
import 'personal_debt_details_screen.dart';

/// Row for money lent to / borrowed from a person. Tap for details.
class PersonalDebtCard extends StatelessWidget {
  final FinancialItem item;
  const PersonalDebtCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final lent = item.itemType == 'asset';
    final color = lent ? AppColors.asset : AppColors.liability;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final monthly = personalMonthlyInterest(item);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FinCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => PersonalDebtDetailsScreen(itemId: item.id))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                      [
                        lent ? 'Lent' : 'Borrowed',
                        personalRateLabel(item),
                        if (monthly != null && item.status == 'active')
                          '≈ ${CurrencyFormatter.formatPaise(monthly)}/month',
                      ].join(' · '),
                      style: AppTypography.labelSmall.copyWith(color: muted)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(CurrencyFormatter.formatPaise(item.currentValuationPaise),
                    style: AppTypography.titleMedium
                        .copyWith(color: color, fontWeight: FontWeight.bold)),
                Text(item.status == 'active' ? 'remaining' : 'settled',
                    style: AppTypography.labelSmall.copyWith(color: muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
