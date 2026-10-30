import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

/// Liabilities screen for managing loans, credit lines, and repayment obligations.
class LiabilitiesScreen extends StatelessWidget {
  const LiabilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liabilities & Debt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Liability',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Liability tracking forms will be available in subsequent milestones'),
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
          // Debt Overview Card
          FinCard(
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL OUTSTANDING DEBT',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const StatusBadge(
                      label: '0 Active Debts',
                      type: BadgeType.liability,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(0.0),
                  style: AppTypography.heroAmount.copyWith(
                    color: AppColors.liability,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Monthly EMI Commitments: ${CurrencyFormatter.format(0.0)}',
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
                _buildFilterChip('All Liabilities',
                    isSelected: true, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Home Loans',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Vehicle Loans',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Education Loans',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Credit Cards',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Personal Loans',
                    isSelected: false, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Active Obligations'),
          const SizedBox(height: AppSpacing.md),
          EmptyStateView(
            icon: Icons.credit_score_rounded,
            title: 'No Debt Recorded',
            description:
                'Track your loans, monthly EMIs, and debt payoff progress privately without linking bank credentials.',
            actionLabel: 'Add First Liability',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Liability configuration form is in development'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
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
            ? AppColors.liability
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isSelected
              ? AppColors.liability
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
