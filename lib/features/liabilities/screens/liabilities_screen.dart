import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../profile/widgets/profile_menu_button.dart';

/// Liabilities screen presenting the planned liability and debt tracking capabilities
/// for a future milestone (home loans, personal loans, vehicle loans, education loans,
/// credit card dues, and other liabilities).
class LiabilitiesScreen extends ConsumerWidget {
  const LiabilitiesScreen({super.key});

  static const List<PlannedCategory> _plannedCategories = [
    PlannedCategory(
      title: 'Home Loans',
      description:
          'Mortgage tracking, principal/interest split, and EMI amortization schedules.',
      icon: Icons.home_rounded,
      color: Color(0xFF3B82F6),
    ),
    PlannedCategory(
      title: 'Personal Loans',
      description:
          'Fixed-term unsecured bank loans, tenure tracking, and repayment progress.',
      icon: Icons.person_rounded,
      color: Color(0xFF8B5CF6),
    ),
    PlannedCategory(
      title: 'Vehicle Loans',
      description:
          'Car and two-wheeler financing, hypothecation tracking, and EMI alerts.',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF06B6D4),
    ),
    PlannedCategory(
      title: 'Education Loans',
      description:
          'Student loans, moratorium periods, and Section 80E interest deduction tracking.',
      icon: Icons.school_rounded,
      color: Color(0xFFF59E0B),
    ),
    PlannedCategory(
      title: 'Credit Card Dues',
      description:
          'Statement cycles, total dues vs minimum payment, and billing cycle management.',
      icon: Icons.credit_card_rounded,
      color: Color(0xFFEC4899),
    ),
    PlannedCategory(
      title: 'Other Liabilities',
      description:
          'Peer borrowings, informal family debts, and miscellaneous payment obligations.',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF64748B),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Tooltip(
          message: 'Switch Family Profile',
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              ref.read(hasSelectedInitialProfileProvider.notifier).state =
                  false;
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child:
                  FinBalanceLogo(size: 28, showText: true, showTagline: false),
            ),
          ),
        ),
        actions: const [
          ProfileMenuButton(radius: 16),
          SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Milestone Status Banner
          FinCard(
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.liability.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: const Icon(
                        Icons.account_balance_rounded,
                        color: AppColors.liability,
                        size: 24,
                      ),
                    ),
                    const StatusBadge(
                      label: 'Coming in Future Milestone',
                      type: BadgeType.scheduled,
                      icon: Icons.upcoming_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Liabilities & Debt Tracking',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Full debt tracking, amortization schedules, and liability management will be introduced in an upcoming milestone. FinBalance Milestone 3 is focused exclusively on Mutual Fund Schemes, NAV Integration, and SIP Investment Schedules.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Planned Categories Section
          const SectionHeader(
            title: 'Planned Categories',
          ),
          const SizedBox(height: AppSpacing.sm),

          ..._plannedCategories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: FinCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cat.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Scope Control Note Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated.withValues(alpha: 0.5)
                  : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: AppColors.brandPrimaryLight,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Net worth calculations in the current milestone reflect your verified assets exclusively without speculative debt figures.',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }
}

class PlannedCategory {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PlannedCategory({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
