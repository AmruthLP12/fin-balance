import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../screens/sip_details_screen.dart';

/// Minimal schedule row: name, scheme, status and a one-line `SIP · ₹ · Next: date`.
/// Tapping opens the SIP details; edit/delete live there.
class SipCard extends ConsumerWidget {
  final SipPlan sip;

  const SipCard({super.key, required this.sip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    final periods = ref.watch(sipPeriodsProvider(sip.id)).value ??
        const <SipSchedulePeriod>[];
    final installments = ref.watch(sipInstallmentsProvider(sip.id)).value ??
        const <SipInstallment>[];
    final schemeName =
        ref.watch(schemeByCodeProvider(sip.schemeCode)).value?.schemeName ??
            'Scheme #${sip.schemeCode}';

    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final next = installments
        .where((i) => i.status == 'upcoming' && !i.scheduledDate.isBefore(today))
        .firstOrNull;

    final parts = <String>['SIP'];
    if (periods.isNotEmpty) {
      parts.add(CurrencyFormatter.formatPaise(periods.last.amountPaise));
    }
    parts.add(next != null
        ? 'Next: ${DateFormatter.formatDate(next.scheduledDate)}'
        : (sip.endDate != null
            ? 'Ended: ${DateFormatter.formatDate(sip.endDate!)}'
            : 'No upcoming installment'));

    return FinCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => SipDetailsScreen(sip: sip)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sip.name,
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  schemeName,
                  style: AppTypography.labelSmall.copyWith(color: muted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  parts.join(' · '),
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: sip.status.toUpperCase(),
            type: switch (sip.status.toLowerCase()) {
              'active' => BadgeType.asset,
              'paused' => BadgeType.scheduled,
              'stopped' || 'cancelled' => BadgeType.liability,
              _ => BadgeType.neutral,
            },
          ),
        ],
      ),
    );
  }
}
