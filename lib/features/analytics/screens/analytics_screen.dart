import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/stat_card.dart';

/// Analytics screen for Net Worth trends, XIRR, and Debt-to-Asset ratios.
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Analytics'),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Net Worth Composition Card
          FinCard(
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NET WORTH COMPOSITION',
                  style: AppTypography.labelSmall.copyWith(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress Ratio Bar
                ClipRRect(
                  borderRadius: AppSpacing.borderRadiusPill,
                  child: Container(
                    height: 12,
                    color: isDark
                        ? AppColors.darkSurfaceHighlight
                        : AppColors.lightSurfaceHighlight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(color: AppColors.asset),
                        ),
                        Expanded(
                          flex: 0,
                          child: Container(color: AppColors.liability),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.asset,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Assets: 100%',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.liability,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Debt: 0%',
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Key Ratios
          const SectionHeader(title: 'Financial Health Indicators'),
          Row(
            children: [
              const Expanded(
                child: StatCard(
                  label: 'Debt / Asset Ratio',
                  value: '0.0%',
                  subtitle: 'Optimal < 30%',
                  icon: Icons.health_and_safety_outlined,
                  accentColor: AppColors.brandPrimaryLight,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: StatCard(
                  label: 'Portfolio XIRR',
                  value: CurrencyFormatter.formatPercent(0.0),
                  subtitle: 'Dated cash flow returns',
                  icon: Icons.speed_rounded,
                  accentColor: AppColors.asset,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Historical Trends'),
          const SizedBox(height: AppSpacing.md),
          const EmptyStateView(
            icon: Icons.auto_graph_rounded,
            title: 'Analytics Require Transaction Data',
            description:
                'As you record investments and repayment milestones, historical growth curves and allocation breakdowns will automatically generate here.',
          ),
        ],
      ),
    );
  }
}
