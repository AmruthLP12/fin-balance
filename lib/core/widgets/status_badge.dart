import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum BadgeType { asset, liability, scheduled, neutral, brand }

/// Reusable status badge pill for FinBalance.
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    super.key,
    this.type = BadgeType.neutral,
    this.icon,
  });

  final String label;
  final BadgeType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.asset:
        bg = isDark
            ? AppColors.assetBackgroundDark
            : AppColors.assetBackgroundLight;
        fg = isDark ? AppColors.assetLight : AppColors.asset;
        break;
      case BadgeType.liability:
        bg = isDark
            ? AppColors.liabilityBackgroundDark
            : AppColors.liabilityBackgroundLight;
        fg = isDark ? AppColors.liabilityLight : AppColors.liability;
        break;
      case BadgeType.scheduled:
        bg = isDark
            ? AppColors.scheduledBackgroundDark
            : AppColors.scheduledBackgroundLight;
        fg = isDark ? AppColors.scheduled : const Color(0xFFB45309);
        break;
      case BadgeType.brand:
        bg = isDark ? const Color(0xFF1E3A8A) : const Color(0xFFDBEAFE);
        fg = isDark ? AppColors.brandPrimaryLight : AppColors.brandPrimary;
        break;
      case BadgeType.neutral:
        bg = isDark
            ? AppColors.darkSurfaceElevated
            : AppColors.lightSurfaceElevated;
        fg =
            isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppSpacing.borderRadiusPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
