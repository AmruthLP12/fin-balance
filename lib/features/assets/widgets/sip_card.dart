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
import 'edit_sip_schedule_dialog.dart';
import 'sip_installments_sheet.dart';

/// Card displaying a master SIP Plan, current period schedule, and quick management actions.
class SipCard extends ConsumerWidget {
  final SipPlan sip;

  const SipCard({super.key, required this.sip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final periodsAsync = ref.watch(sipPeriodsProvider(sip.id));
    final schemeAsync = ref.watch(schemeByCodeProvider(sip.schemeCode));

    final schemeName =
        schemeAsync.value?.schemeName ?? 'Scheme #${sip.schemeCode}';
    final fundHouse = schemeAsync.value?.fundHouse;

    return FinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name and Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sip.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      schemeName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              StatusBadge(
                label: sip.status.toUpperCase(),
                type: _badgeTypeForStatus(sip.status),
              ),
            ],
          ),
          if (fundHouse != null && fundHouse.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              fundHouse,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),

          // Active Schedule Period Info
          periodsAsync.when(
            data: (periods) {
              if (periods.isEmpty) {
                return const Text('No schedule periods defined.');
              }
              final activePeriod = periods.last;
              final amountStr =
                  CurrencyFormatter.formatPaise(activePeriod.amountPaise);
              final dayStr = _formatDayOrdinal(activePeriod.deductionDay);

              return Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MONTHLY AMOUNT',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          amountStr,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.asset,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DEDUCTION DAY',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Every $dayStr of month',
                          style: AppTypography.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Dates Summary
          Row(
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color:
                    isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Started ${DateFormatter.formatDate(sip.startDate)}${sip.endDate != null ? ' • Until ${DateFormatter.formatDate(sip.endDate!)}' : ' • Ongoing'}',
                style: AppTypography.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.history_rounded, size: 18),
                label: const Text('Installments'),
                onPressed: () => _openInstallments(context),
              ),
              const SizedBox(width: AppSpacing.xs),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                label: const Text('Edit Schedule'),
                onPressed: () => _openEditSchedule(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BadgeType _badgeTypeForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BadgeType.asset;
      case 'paused':
        return BadgeType.scheduled;
      case 'completed':
        return BadgeType.neutral;
      case 'stopped':
      case 'cancelled':
        return BadgeType.liability;
      default:
        return BadgeType.neutral;
    }
  }

  String _formatDayOrdinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  void _openInstallments(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SipInstallmentsSheet(sip: sip),
    );
  }

  void _openEditSchedule(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => EditSipScheduleDialog(sip: sip),
    );
  }
}
