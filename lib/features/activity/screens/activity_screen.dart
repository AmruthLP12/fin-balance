import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/formatting/date_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

/// Activity & Cash Flow screen for tracking transactions, simulated SIP installments,
/// loan EMI payments, and adjustments.
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transactionsAsync = ref.watch(activeProfileTransactionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity & Cash Flow'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter Activity',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Transaction filters will be enabled with the database layer'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Monthly Flow Summary Card
          FinCard(
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'PROJECTED MONTHLY FLOW',
                        style: AppTypography.labelSmall.copyWith(
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const StatusBadge(
                      label: 'Cash Flow',
                      type: BadgeType.scheduled,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(0.0),
                  style: AppTypography.heroAmount.copyWith(
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'SIP Outflows: ${CurrencyFormatter.format(0.0)} • Debt EMIs: ${CurrencyFormatter.format(0.0)}',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Activity',
                    isSelected: true, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Simulated SIPs',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Debt Payments',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Manual Purchases',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Redemptions',
                    isSelected: false, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Transaction Timeline'),
          const SizedBox(height: AppSpacing.md),
          transactionsAsync.when(
            data: (txns) {
              if (txns.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.receipt_long_rounded,
                  title: 'No Recorded Activity',
                  description:
                      'Scheduled SIP contributions, debt repayments, and manual adjustments will appear in this unified financial ledger.',
                );
              }

              return Column(
                children: txns.map((txn) {
                  final isIncome = txn.transactionType == 'income';
                  final isExpense = txn.transactionType == 'expense';
                  final prefix = isIncome ? '+' : (isExpense ? '-' : '');
                  final color = isIncome
                      ? AppColors.asset
                      : (isExpense
                          ? AppColors.liability
                          : AppColors.brandPrimaryLight);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FinCard(
                      child: Row(
                        children: [
                          Icon(
                            isIncome
                                ? Icons.arrow_downward_rounded
                                : (isExpense
                                    ? Icons.arrow_upward_rounded
                                    : Icons.swap_horiz_rounded),
                            color: color,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  txn.notes ??
                                      txn.transactionType
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormatter.formatDate(txn.transactionDate),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '$prefix${CurrencyFormatter.formatPaise(txn.amountPaise)}',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, _) =>
                Center(child: Text('Error loading activity: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label,
      {required bool isSelected, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.brandPrimary
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isSelected
              ? AppColors.brandPrimary
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.labelMedium.copyWith(
          color: isSelected
              ? Colors.white
              : (isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
