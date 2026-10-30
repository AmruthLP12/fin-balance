import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Standard surface card for FinBalance.
class FinCard extends StatelessWidget {
  const FinCard({
    required this.child,
    super.key,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBorderColor = borderColor ??
        (isDark
            ? theme.colorScheme.outline
            : theme.colorScheme.outline.withValues(alpha: 0.6));

    final cardContent = Padding(
      padding: padding ?? AppSpacing.cardPadding,
      child: child,
    );

    return Material(
      color: backgroundColor ?? theme.cardTheme.color,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.borderRadiusMd,
        side: BorderSide(
          color: resolvedBorderColor,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              child: cardContent,
            )
          : cardContent,
    );
  }
}
