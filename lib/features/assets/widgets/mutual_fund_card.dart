import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
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
  final bool? isFavorite;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onTap;

  const MutualFundCard({
    super.key,
    required this.scheme,
    this.latestNavMicroPaise,
    this.latestNavDate,
    this.isFavorite,
    this.onFavoriteToggle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoriteAsync =
        ref.watch(isSchemeFavoriteProvider(scheme.schemeCode));
    final effectiveIsFavorite = isFavorite ?? (favoriteAsync.value ?? false);

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
                  effectiveIsFavorite
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: effectiveIsFavorite
                      ? AppColors.scheduled
                      : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                ),
                tooltip: effectiveIsFavorite
                    ? 'Remove Favorite'
                    : 'Add to Favorites',
                onPressed: () async {
                  if (onFavoriteToggle != null) {
                    onFavoriteToggle!();
                  } else {
                    final profileId = ref.read(activeProfileIdProvider);
                    final dao = ref.read(mutualFundDaoProvider);
                    final nowFav = await dao.toggleFavorite(
                      profileId: profileId,
                      schemeCode: scheme.schemeCode,
                      schemeName: scheme.schemeName,
                      fundHouse: scheme.fundHouse,
                      planType: scheme.planType,
                      optionType: scheme.optionType,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(nowFav
                              ? 'Added to favourites!'
                              : 'Removed from favourites.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
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
