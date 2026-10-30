import 'package:flutter/material.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';

/// SIP screen for managing SIP configurations, pause/resume, and scheduled installments.
class SipScreen extends StatelessWidget {
  const SipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIP Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create SIP',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'SIP creation form will be available in Milestone 4'),
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
          // SIP Overview Card
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
                      'TOTAL MONTHLY SIP COMMITMENT',
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const StatusBadge(
                      label: '0 Active SIPs',
                      type: BadgeType.scheduled,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  CurrencyFormatter.format(0.0),
                  style: AppTypography.heroAmount.copyWith(
                    color: AppColors.scheduled,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Upcoming installment: None scheduled',
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
                _buildFilterChip('All SIPs', isSelected: true, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Active', isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Paused', isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Completed',
                    isSelected: false, isDark: isDark),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('Upcoming Calendar',
                    isSelected: false, isDark: isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          const SectionHeader(title: 'Active Systematic Plans'),
          const SizedBox(height: AppSpacing.md),
          EmptyStateView(
            icon: Icons.calendar_month_rounded,
            title: 'No Active SIPs',
            description:
                'Set up your monthly, weekly, or quarterly SIPs. FinBalance will automatically project scheduled contributions and simulate investment allocations.',
            actionLabel: 'Configure First SIP',
            onAction: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'SIP configuration engine will be implemented in Milestone 4'),
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
            ? AppColors.scheduled
            : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        borderRadius: AppSpacing.borderRadiusPill,
        border: Border.all(
          color: isSelected
              ? AppColors.scheduled
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
