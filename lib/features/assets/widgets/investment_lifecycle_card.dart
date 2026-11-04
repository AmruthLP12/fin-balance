import 'package:flutter/material.dart';
import '../../../core/calculations/investment_lifecycle_summary.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';

/// Lifecycle overview (status, held-for, key totals) above a dated timeline.
class InvestmentLifecycleCard extends StatelessWidget {
  final LifecycleOverview overview;
  final List<LifecycleEvent> events;

  const InvestmentLifecycleCard({
    super.key,
    required this.overview,
    required this.events,
  });

  static (IconData, Color) _style(LifecycleKind kind) => switch (kind) {
        LifecycleKind.created => (Icons.flag_rounded, AppColors.brandPrimary),
        LifecycleKind.oneTime => (
            Icons.add_shopping_cart_rounded,
            AppColors.brandPrimary
          ),
        LifecycleKind.sipStart || LifecycleKind.sipRevised => (
            Icons.autorenew_rounded,
            AppColors.brandPrimary
          ),
        LifecycleKind.swpStart || LifecycleKind.swpRevised => (
            Icons.outbox_rounded,
            AppColors.scheduled
          ),
        LifecycleKind.sipEnd || LifecycleKind.swpEnd => (
            Icons.stop_circle_outlined,
            AppColors.warning
          ),
        LifecycleKind.redemption || LifecycleKind.swpWithdrawal => (
            Icons.south_east_rounded,
            AppColors.liability
          ),
        LifecycleKind.dividendReinvested || LifecycleKind.dividendReceived => (
            Icons.savings_outlined,
            AppColors.asset
          ),
        LifecycleKind.switchIn || LifecycleKind.switchOut => (
            Icons.swap_horiz_rounded,
            AppColors.scheduled
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final stats = <(String, String)>[
      ('Invested', CurrencyFormatter.formatPaise(overview.investedPaise)),
      ('Value', CurrencyFormatter.formatPaise(overview.currentValuePaise)),
      ('Units', overview.unitsHeld.toStringAsFixed(3)),
      if (overview.sipInstallments > 0)
        ('SIP installments', '${overview.sipInstallments}'),
      if (overview.withdrawnPaise > 0)
        ('Withdrawn', CurrencyFormatter.formatPaise(overview.withdrawnPaise)),
      if (overview.dividendsPaise > 0)
        ('Dividends', CurrencyFormatter.formatPaise(overview.dividendsPaise)),
    ];

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: overview.status.toUpperCase(),
                type: overview.status == 'Fully redeemed'
                    ? BadgeType.neutral
                    : BadgeType.asset,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Held ${overview.heldFor} · since ${DateFormatter.formatDate(overview.heldSince)}',
                  style: AppTypography.labelSmall.copyWith(color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (label, value) in stats)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label,
                        style: AppTypography.labelSmall.copyWith(color: muted)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: AppTypography.labelMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          for (int i = 0; i < events.length; i++)
            _TimelineRow(
              event: events[i],
              isLast: i == events.length - 1,
              muted: muted,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final LifecycleEvent event;
  final bool isLast;
  final Color muted;
  final bool isDark;

  const _TimelineRow({
    required this.event,
    required this.isLast,
    required this.muted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = InvestmentLifecycleCard._style(event.kind);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormatter.formatDate(event.date),
                    style: AppTypography.labelSmall.copyWith(color: muted),
                  ),
                  Text(
                    event.title,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (event.detail != null)
                    Text(
                      event.detail!,
                      style: AppTypography.bodySmall
                          .copyWith(color: muted, height: 1.35),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
