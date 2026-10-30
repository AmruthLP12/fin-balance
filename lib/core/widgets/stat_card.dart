import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'fin_card.dart';

/// Stat card for financial metrics (e.g. Net Worth, Total Assets, Total Debt).
class StatCard extends StatelessWidget {
  const StatCard({
    required this.label,
    required this.value,
    super.key,
    this.subtitle,
    this.deltaText,
    this.isPositive,
    this.icon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final String? deltaText;
  final bool? isPositive;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedDeltaColor = isPositive == null
        ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
        : (isPositive! ? AppColors.asset : AppColors.liability);

    return FinCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (icon != null)
                Icon(
                  icon,
                  size: 16,
                  color: accentColor ??
                      (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.cardAmount.copyWith(
              color: accentColor ??
                  (isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary),
            ),
          ),
          if (deltaText != null || subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (deltaText != null) ...[
                  Text(
                    deltaText!,
                    style: AppTypography.labelSmall.copyWith(
                      color: resolvedDeltaColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
