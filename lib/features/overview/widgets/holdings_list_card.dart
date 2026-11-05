import 'package:flutter/material.dart';
import '../../../core/constants/asset_categories.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../database/app_database.dart';

/// Category-level breakdown (Mutual Funds, Stocks, Home Loan, ...) of the profile's
/// active assets and liabilities, with count and total per category; rows are tappable.
class HoldingsListCard extends StatelessWidget {
  final List<FinancialItem> assets;
  final List<FinancialItem> liabilities;
  final void Function(String subType, {required bool isLiability}) onTap;

  const HoldingsListCard({
    super.key,
    required this.assets,
    required this.liabilities,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    Widget section(String title, List<FinancialItem> items, Color color,
        bool isLiability, List<String> order) {
      final groups = <String, List<FinancialItem>>{};
      for (final i in items) {
        groups.putIfAbsent(i.subType, () => []).add(i);
      }
      int total(List<FinancialItem> l) =>
          l.fold(0, (s, i) => s + i.currentValuationPaise);
      // Every known category is listed (even when empty) so gaps are visible.
      final keys = [
        ...order,
        ...groups.keys.where((k) => !order.contains(k)),
      ];
      final entries = [for (final k in keys) MapEntry(k, groups[k] ?? [])];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            badge: Text(CurrencyFormatter.formatPaise(total(items)),
                style: AppTypography.labelMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          FinCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    dense: true,
                    title: Text(categoryLabel(entries[i].key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        entries[i].value.isEmpty
                            ? 'Nothing added yet'
                            : '${entries[i].value.length} ${entries[i].value.length == 1 ? 'item' : 'items'}',
                        style: AppTypography.labelSmall.copyWith(color: muted)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                            CurrencyFormatter.formatPaise(
                                total(entries[i].value)),
                            style: AppTypography.labelMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Icon(Icons.chevron_right_rounded,
                            size: 18, color: muted),
                      ],
                    ),
                    onTap: () =>
                        onTap(entries[i].key, isLiability: isLiability),
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
        section('Assets', assets, AppColors.asset, false,
            [for (final c in assetCategories) c.$1]),
        const SizedBox(height: 16),
        section('Liabilities', liabilities, AppColors.liability, true,
            [for (final c in liabilityCategories) c.$1]),
      ],
    );
  }
}
