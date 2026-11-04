import 'package:flutter/material.dart';
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

  static const _labels = {
    'mutual_fund': 'Mutual Funds',
    'stock': 'Stocks & ETFs',
    'fixed_deposit': 'Fixed Deposits',
    'recurring_deposit': 'Recurring Deposits',
    'gold': 'Gold',
    'home_loan': 'Home Loan',
    'vehicle_loan': 'Vehicle / Auto Loan',
    'personal_loan': 'Personal Loan',
    'education_loan': 'Education Loan',
    'credit_card': 'Credit Card Due',
    'other_liability': 'Other Borrowing',
  };

  static String _label(String subType) =>
      _labels[subType] ??
      subType
          .split('_')
          .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
          .join(' ');

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty && liabilities.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    Widget section(String title, List<FinancialItem> items, Color color,
        bool isLiability) {
      final groups = <String, List<FinancialItem>>{};
      for (final i in items) {
        groups.putIfAbsent(i.subType, () => []).add(i);
      }
      int total(List<FinancialItem> l) =>
          l.fold(0, (s, i) => s + i.currentValuationPaise);
      final entries = groups.entries.toList()
        ..sort((a, b) => total(b.value).compareTo(total(a.value)));

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
                    title: Text(_label(entries[i].key),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium
                            .copyWith(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                        '${entries[i].value.length} ${entries[i].value.length == 1 ? 'item' : 'items'}',
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
        if (assets.isNotEmpty)
          section('Assets', assets, AppColors.asset, false),
        if (assets.isNotEmpty && liabilities.isNotEmpty)
          const SizedBox(height: 16),
        if (liabilities.isNotEmpty)
          section('Liabilities', liabilities, AppColors.liability, true),
      ],
    );
  }
}
