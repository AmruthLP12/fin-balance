import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../profile/widgets/profile_selector_button.dart';
import '../widgets/holding_card.dart';
import '../widgets/holding_details_sheet.dart';
import 'mutual_fund_search_screen.dart';

/// Assets screen for managing Mutual Funds, Stocks, FDs, Gold, and wealth holdings scoped to the active profile.
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  String _selectedCategoryFilter = 'all';
  bool _isSyncingNav = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);

    final profileName = activeProfileAsync.value?.name ?? 'Profile';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assets & Holdings'),
        actions: [
          const ProfileSelectorButton(),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: _isSyncingNav
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync Portfolio NAV',
            onPressed: _isSyncingNav ? null : _triggerPortfolioNavSync,
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search & Add Mutual Funds',
            onPressed: () => _openSearchScreen(context),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: assetsAsync.when(
        data: (items) {
          // Calculate summary metrics
          final totalCurrentPaise =
              items.fold<int>(0, (sum, i) => sum + i.currentValuationPaise);
          final totalInvestedPaise =
              items.fold<int>(0, (sum, i) => sum + i.initialValuePaise);
          final totalReturnPaise = totalCurrentPaise - totalInvestedPaise;
          final isProfit = totalReturnPaise >= 0;
          final returnPercentage = totalInvestedPaise > 0
              ? (totalReturnPaise / totalInvestedPaise) * 100
              : 0.0;

          final filteredItems = _filterItems(items, _selectedCategoryFilter);

          return ListView(
            padding: AppSpacing.screenPadding,
            children: [
              // Portfolio Value Header Card
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
                        Text(
                          '$profileName’s ASSET VALUE'.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        StatusBadge(
                          label:
                              '${items.length} ${items.length == 1 ? 'Holding' : 'Holdings'}',
                          type: BadgeType.asset,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      CurrencyFormatter.formatPaise(totalCurrentPaise),
                      style: AppTypography.heroAmount.copyWith(
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      children: [
                        Text(
                          'Invested: ${CurrencyFormatter.formatPaise(totalInvestedPaise)}',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                          ),
                        ),
                        Text('•',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted,
                            )),
                        Text(
                          '${isProfit ? '+' : ''}${CurrencyFormatter.formatPaise(totalReturnPaise)} (${returnPercentage >= 0 ? '+' : ''}${returnPercentage.toStringAsFixed(2)}%)',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isProfit
                                ? AppColors.asset
                                : AppColors.liability,
                          ),
                        ),
                      ],
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
                    _buildFilterChip('All Assets', 'all', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Mutual Funds', 'mutual_fund',
                        isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Stocks & ETFs', 'stock', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Fixed Deposits', 'fixed_deposit',
                        isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Gold', 'gold', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Retirement', 'ppf', isDark: isDark),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Holdings List
              SectionHeader(
                title: 'Holdings (${filteredItems.length})',
                actionLabel: 'Add Scheme',
                onActionTap: () => _openSearchScreen(context),
              ),
              const SizedBox(height: AppSpacing.sm),

              if (items.isEmpty)
                EmptyStateView(
                  icon: Icons.pie_chart_outline_rounded,
                  title: 'No Assets in $profileName’s Portfolio',
                  description:
                      'Search 40,000+ Indian mutual funds or add holdings to track $profileName’s isolated wealth safely on-device.',
                  actionLabel: 'Search & Add Mutual Funds',
                  onAction: () => _openSearchScreen(context),
                )
              else if (filteredItems.isEmpty)
                EmptyStateView(
                  icon: Icons.filter_list_off_rounded,
                  title: 'No Assets in Selected Category',
                  description:
                      'No holdings match the current filter in $profileName’s portfolio.',
                  actionLabel: 'Show All Assets',
                  onAction: () =>
                      setState(() => _selectedCategoryFilter = 'all'),
                )
              else
                ...filteredItems.map(
                  (item) => HoldingCard(
                    item: item,
                    onTap: () => _openHoldingDetails(context, item),
                    onDelete: () => _confirmDeleteHolding(context, item),
                  ),
                ),

              const SizedBox(height: 80), // FAB clearance
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('Error loading assets: $err'),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_chart_rounded),
        label: const Text('Add Mutual Fund'),
        onPressed: () => _openSearchScreen(context),
      ),
    );
  }

  List<FinancialItem> _filterItems(List<FinancialItem> items, String filter) {
    if (filter == 'all') return items;
    if (filter == 'ppf') {
      return items
          .where((i) =>
              i.subType == 'ppf' || i.subType == 'epf' || i.subType == 'nps')
          .toList();
    }
    return items.where((i) => i.subType == filter).toList();
  }

  Widget _buildFilterChip(String label, String value, {required bool isDark}) {
    final isSelected = _selectedCategoryFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedCategoryFilter = value),
      borderRadius: AppSpacing.borderRadiusPill,
      child: Container(
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
      ),
    );
  }

  void _openSearchScreen(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const MutualFundSearchScreen(),
      ),
    );
  }

  void _openHoldingDetails(BuildContext context, FinancialItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HoldingDetailsSheet(holding: item),
    );
  }

  Future<void> _triggerPortfolioNavSync() async {
    setState(() => _isSyncingNav = true);
    try {
      final syncService = ref.read(navSyncServiceProvider);
      final summary = await syncService.syncAllPortfolioSchemes();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(summary.totalSchemes > 0
                ? 'Updated NAV for ${summary.successCount} of ${summary.totalSchemes} schemes (${summary.primaryProvider ?? "MFapi"})'
                : 'No tracked schemes to sync in portfolio.'),
            backgroundColor:
                summary.failedCount == 0 ? AppColors.asset : AppColors.warning,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NAV sync notice: $e'),
            backgroundColor: AppColors.liability,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncingNav = false);
    }
  }

  void _confirmDeleteHolding(BuildContext context, FinancialItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Holding?'),
        content: Text(
          'Are you sure you want to remove "${item.name}" from this profile’s portfolio?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liability),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final itemsDao = ref.read(financialItemsDaoProvider);
              await (itemsDao.delete(itemsDao.financialItems)
                    ..where((tbl) => tbl.id.equals(item.id)))
                  .go();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed "${item.name}"'),
                  ),
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
