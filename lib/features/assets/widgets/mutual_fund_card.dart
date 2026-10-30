import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/nav/models/nav_models.dart';
import '../../../database/precision/financial_precision.dart';

/// Card displaying mutual fund search result or cached scheme summary.
class MutualFundCard extends ConsumerWidget {
  final MutualFundSearchResult scheme;
  final int? latestNavMicroPaise;
  final DateTime? latestNavDate;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const MutualFundCard({
    super.key,
    required this.scheme,
    this.latestNavMicroPaise,
    this.latestNavDate,
    this.isFavorite = false,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FinCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  scheme.schemeName,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFavorite
                      ? AppColors.scheduled
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                ),
                tooltip: isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                onPressed: onFavoriteToggle,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          if (scheme.fundHouse != null && scheme.fundHouse!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              scheme.fundHouse!,
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              StatusBadge(
                label: scheme.planType,
                type: scheme.planType == 'Direct'
                    ? BadgeType.brand
                    : BadgeType.neutral,
              ),
              const SizedBox(width: AppSpacing.xs),
              StatusBadge(
                label: scheme.optionType,
                type: scheme.optionType == 'Growth'
                    ? BadgeType.asset
                    : BadgeType.scheduled,
              ),
              const Spacer(),
              if (latestNavMicroPaise != null && latestNavMicroPaise! > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(
                        FinancialPrecision.microPaiseToNav(
                            latestNavMicroPaise!),
                      ),
                      style: AppTypography.cardAmount.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (latestNavDate != null)
                      Text(
                        '${latestNavDate!.day}/${latestNavDate!.month}/${latestNavDate!.year}',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          fontSize: 10,
                        ),
                      ),
                  ],
                )
              else
                Text(
                  'Code: ${scheme.schemeCode}',
                  style: AppTypography.labelSmall.copyWith(
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
  }
}
