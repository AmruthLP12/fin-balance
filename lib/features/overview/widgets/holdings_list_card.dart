import 'package:flutter/material.dart';
import '../../../core/constants/asset_categories.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../database/app_database.dart';

/// Category breakdown of the profile's active assets and liabilities. Every category (and
/// every instrument inside a group such as Fixed Income or Loans) is listed, even when
/// empty, so gaps are visible. Rows are tappable and report their group value.
class HoldingsListCard extends StatelessWidget {
  final List<FinancialItem> assets;
  final List<FinancialItem> liabilities;
  final void Function(String groupValue, {required bool isLiability}) onTap;

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

    int total(Iterable<FinancialItem> l) =>
        l.fold(0, (s, i) => s + i.currentValuationPaise);

    Widget row({
      required String title,
      required List<FinancialItem> items,
      required VoidCallback onTap,
      bool child = false,
    }) {
      return ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: child ? 36 : 16, right: 16),
        visualDensity: child ? VisualDensity.compact : null,
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (child ? AppTypography.bodySmall : AppTypography.bodyMedium)
                .copyWith(
                    fontWeight: child ? FontWeight.w500 : FontWeight.w600)),
        subtitle: Text(
            items.isEmpty
                ? 'Nothing added yet'
                : '${items.length} ${items.length == 1 ? 'item' : 'items'}',
            style: AppTypography.labelSmall.copyWith(color: muted)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (items.isNotEmpty)
              Text(CurrencyFormatter.formatPaise(total(items)),
                  style: AppTypography.labelMedium
                      .copyWith(fontWeight: FontWeight.w700)),
            Icon(Icons.chevron_right_rounded, size: 18, color: muted),
          ],
        ),
        onTap: onTap,
      );
    }

    Widget section(String title, List<FinancialItem> items, Color color,
        bool isLiability, List<CategoryGroup> groups) {
      final byGroup = <String, List<FinancialItem>>{};
      for (final i in items) {
        byGroup.putIfAbsent(groupOf(i.subType, groups).value, () => []).add(i);
      }
      final rows = <Widget>[];
      for (final g in groups) {
        final groupItems = byGroup[g.value] ?? [];
        void open() => onTap(g.value, isLiability: isLiability);
        if (rows.isNotEmpty) rows.add(const Divider(height: 1));
        rows.add(row(title: g.label, items: groupItems, onTap: open));
        for (final (value, label) in g.children) {
          rows.add(row(
            title: label,
            items: groupItems.where((i) => i.subType == value).toList(),
            onTap: open,
            child: true,
          ));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            badge: Text(CurrencyFormatter.formatPaise(total(items)),
                style: AppTypography.labelMedium
                    .copyWith(color: color, fontWeight: FontWeight.w700)),
          ),
          FinCard(padding: EdgeInsets.zero, child: Column(children: rows)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        section('Assets', assets, AppColors.asset, false, assetGroups),
        const SizedBox(height: 16),
        section('Liabilities', liabilities, AppColors.liability, true,
            liabilityGroups),
      ],
    );
  }
}
