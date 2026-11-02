import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';

/// Sheet displaying all installments generated for a SIP Plan, with actions to record or skip.
class SipInstallmentsSheet extends ConsumerWidget {
  final SipPlan sip;

  const SipInstallmentsSheet({super.key, required this.sip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final installmentsAsync = ref.watch(sipInstallmentsProvider(sip.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sip.name,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Installment Ledger & Projections',
                            style: AppTypography.labelSmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),

              Expanded(
                child: installmentsAsync.when(
                  data: (installments) {
                    if (installments.isEmpty) {
                      return const EmptyStateView(
                        icon: Icons.calendar_month_rounded,
                        title: 'No Installments Generated',
                        description:
                            'Installments are generated according to the SIP schedule periods.',
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: AppSpacing.screenPadding,
                      itemCount: installments.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.xs),
                      itemBuilder: (context, index) {
                        final inst = installments[index];
                        final isRecorded = inst.status == 'recorded';
                        final isUpcoming = inst.status == 'upcoming';
                        final amount =
                            inst.actualAmountPaise ?? inst.expectedAmountPaise;

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkSurfaceElevated
                                : AppColors.lightSurfaceElevated,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusSm),
                            border: Border.all(
                              color: isRecorded
                                  ? AppColors.asset.withValues(alpha: 0.3)
                                  : (isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightBorder),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isRecorded
                                    ? Icons.check_circle_rounded
                                    : (inst.isSimulated
                                        ? Icons.query_builder_rounded
                                        : Icons.schedule_rounded),
                                color: isRecorded
                                    ? AppColors.asset
                                    : (inst.isSimulated
                                        ? AppColors.scheduled
                                        : (isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted)),
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          DateFormatter.formatDate(
                                              inst.scheduledDate),
                                          style: AppTypography.titleMedium
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.xs),
                                        StatusBadge(
                                          label: inst.status.toUpperCase(),
                                          type:
                                              _badgeTypeForStatus(inst.status),
                                        ),
                                        if (inst.isSimulated) ...[
                                          const SizedBox(width: AppSpacing.xs),
                                          const StatusBadge(
                                            label: 'SIMULATED',
                                            type: BadgeType.neutral,
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      CurrencyFormatter.formatPaise(amount),
                                      style: AppTypography.labelMedium.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextSecondary
                                            : AppColors.lightTextSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUpcoming) ...[
                                IconButton(
                                  icon: const Icon(Icons.check_rounded,
                                      color: AppColors.asset),
                                  tooltip: 'Record as Invested',
                                  onPressed: () =>
                                      _markRecorded(context, ref, inst),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded,
                                      color: AppColors.warning),
                                  tooltip: 'Skip Installment',
                                  onPressed: () => _skipInstallment(ref, inst),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  BadgeType _badgeTypeForStatus(String status) {
    switch (status.toLowerCase()) {
      case 'recorded':
        return BadgeType.asset;
      case 'upcoming':
        return BadgeType.scheduled;
      case 'skipped':
        return BadgeType.neutral;
      case 'cancelled':
        return BadgeType.liability;
      default:
        return BadgeType.neutral;
    }
  }

  Future<void> _markRecorded(
      BuildContext context, WidgetRef ref, SipInstallment inst) async {
    final sipsDao = ref.read(sipsDaoProvider);
    await sipsDao.recordActualInstallment(
      installmentId: inst.id,
      actualDate: inst.scheduledDate,
      actualAmountPaise: inst.expectedAmountPaise,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Installment marked as recorded & investment logged!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _skipInstallment(WidgetRef ref, SipInstallment inst) async {
    final sipsDao = ref.read(sipsDaoProvider);
    await sipsDao.skipInstallment(inst.id);
  }
}
