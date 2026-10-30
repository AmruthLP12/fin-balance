import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

/// Assets screen for managing Mutual Funds, SIPs, Stocks, FDs, Gold, and other wealth holdings.
class AssetsScreen extends StatelessWidget {
  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets & Holdings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search Schemes',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Mutual fund scheme search arrives in Milestone 3'),
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
          // Portfolio Value Header Card
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
                      'TOTAL ASSETS VALUE',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const StatusBadge(
                      label: '0 Holdings',
                      type: BadgeType.asset,
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
                  'Invested: ${CurrencyFormatter.format(0.0)} • Returns: +0.00%',
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

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Assets',
                    isSelected: true, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Mutual Funds & SIPs',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Stocks & ETFs',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Fixed Deposits',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Gold & Commodities',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Retirement (PPF/EPF/NPS)',
                    isSelected: false, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Holdings List'),
          const SizedBox(height: AppSpacing.md),
          EmptyStateView(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No Assets Tracked Yet',
            description:
                'Search 40,000+ Indian mutual funds or configure offline asset records to track your net worth securely on-device.',
            actionLabel: 'Search Mutual Funds',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Mutual Fund scheme catalogue will be integrated in Milestone 3'),
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
