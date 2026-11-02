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
import '../../../core/widgets/return_to_profiles_button.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../widgets/add_liability_dialog.dart';

/// Liabilities screen for managing loans, credit lines, and repayment obligations.
class LiabilitiesScreen extends ConsumerStatefulWidget {
  const LiabilitiesScreen({super.key});

  @override
  ConsumerState<LiabilitiesScreen> createState() => _LiabilitiesScreenState();
}

class _LiabilitiesScreenState extends ConsumerState<LiabilitiesScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final liabilitiesAsync = ref.watch(activeProfileLiabilitiesProvider);
    final activeProfile = ref.watch(activeProfileProvider).value;
    final profileName = activeProfile?.name ?? 'Profile';

    return Scaffold(
      appBar: AppBar(
        leading: const ReturnToProfilesButton(),
        title: const Text('Liabilities & Debt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Add Liability',
            onPressed: () => AddLiabilityDialog.show(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: liabilitiesAsync.when(
        data: (items) {
          final totalDebtPaise =
              items.fold<int>(0, (sum, i) => sum + i.currentValuationPaise);
          final filteredItems = _filterItems(items, _selectedFilter);

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Debt Overview Card
              FinCard(
                backgroundColor: isDark
                    ? AppColors.darkSurfaceElevated
                    : AppColors.lightSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$profileName’s OUTSTANDING DEBT'.toUpperCase(),
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
                        StatusBadge(
                          label: '${items.length} Active Debts',
                          type: items.isNotEmpty
                              ? BadgeType.liability
                              : BadgeType.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.formatPaise(totalDebtPaise),
                      style: AppTypography.heroAmount.copyWith(
                        color: AppColors.liability,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Principal borrowings across ${items.length} recorded debt commitments.',
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
                    _buildFilterChip('All Liabilities', 'all', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Home Loans', 'home_loan', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Vehicle Loans', 'vehicle_loan',
                        isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Education Loans', 'education_loan',
                        isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Credit Cards', 'credit_card',
                        isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Personal Loans', 'personal_loan',
                        isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              SectionHeader(
                title: 'Active Obligations (${filteredItems.length})',
                actionLabel: '+ Add',
                onActionTap: () => AddLiabilityDialog.show(context),
              ),
              const SizedBox(height: AppSpacing.md),

              if (items.isEmpty)
                EmptyStateView(
                  icon: Icons.credit_score_rounded,
                  title: 'No Debt Recorded in $profileName’s Balance Sheet',
                  description:
                      'Track loans, credit card dues, and debt payoff progress privately on-device.',
                  actionLabel: 'Add First Liability',
                  onAction: () => AddLiabilityDialog.show(context),
                )
              else if (filteredItems.isEmpty)
                EmptyStateView(
                  icon: Icons.filter_list_off_rounded,
                  title: 'No Liabilities in Selected Filter',
                  description:
                      'No obligations match the "$_selectedFilter" category for $profileName.',
                  actionLabel: 'Show All',
                  onAction: () => setState(() => _selectedFilter = 'all'),
                )
              else
                ...filteredItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: FinCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              StatusBadge(
                                label: _formatSubType(item.subType),
                                type: BadgeType.liability,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OUTSTANDING',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDark
                                          ? AppColors.darkTextMuted
                                          : AppColors.lightTextMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormatter.formatPaise(
                                        item.currentValuationPaise),
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.liability,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              if (item.interestRateBasisPoints != null)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'INTEREST RATE',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isDark
                                            ? AppColors.darkTextMuted
                                            : AppColors.lightTextMuted,
                                        fontSize: 10,
                                      ),
                                    ),
                                    Text(
                                      '${(item.interestRateBasisPoints! / 100).toStringAsFixed(2)}% p.a.',
                                      style: AppTypography.labelMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (item.startDate != null || item.notes != null) ...[
                            const Divider(height: AppSpacing.md),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.startDate != null
                                      ? 'Started ${DateFormatter.formatDate(item.startDate!)}'
                                      : (item.notes ?? ''),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      size: 18),
                                  tooltip: 'Delete Liability',
                                  onPressed: () =>
                                      _confirmDelete(context, item),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading debts: $err')),
      ),
    );
  }

  List<FinancialItem> _filterItems(List<FinancialItem> items, String filter) {
    if (filter == 'all') return items;
    return items.where((i) => i.subType == filter).toList();
  }

  String _formatSubType(String subType) {
    switch (subType) {
      case 'home_loan':
        return 'HOME LOAN';
      case 'vehicle_loan':
        return 'VEHICLE LOAN';
      case 'personal_loan':
        return 'PERSONAL LOAN';
      case 'education_loan':
        return 'EDUCATION LOAN';
      case 'credit_card':
        return 'CREDIT CARD';
      default:
        return 'BORROWING';
    }
  }

  Widget _buildFilterChip(String label, String value, {required bool isDark}) {
    final isSelected = _selectedFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = value),
      borderRadius: AppSpacing.borderRadiusPill,
      child: Container(
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
      ),
    );
  }

  void _confirmDelete(BuildContext context, FinancialItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Liability?'),
        content: Text(
            'Are you sure you want to remove "${item.name}" from this profile’s balance sheet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () async {
              Navigator.pop(ctx);
              final itemsDao = ref.read(financialItemsDaoProvider);
              await (itemsDao.delete(itemsDao.financialItems)
                    ..where((tbl) => tbl.id.equals(item.id)))
                  .go();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed "${item.name}"')),
                );
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
