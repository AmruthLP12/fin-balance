import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/formatting/currency_formatter.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/fin_card.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../database/app_database.dart';
import '../../profile/widgets/profile_avatar.dart';
import '../widgets/add_sip_dialog.dart';
import '../widgets/holding_card.dart';
import '../widgets/holding_details_sheet.dart';
import '../widgets/sip_card.dart';
import 'mutual_fund_search_screen.dart';

/// Assets screen for managing Mutual Funds, Stocks, FDs, Gold, and wealth holdings scoped to the active profile.
class AssetsScreen extends ConsumerStatefulWidget {
  const AssetsScreen({super.key});

  @override
  ConsumerState<AssetsScreen> createState() => _AssetsScreenState();
}

class _AssetsScreenState extends ConsumerState<AssetsScreen> {
  String _selectedCategoryFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeProfileAsync = ref.watch(activeProfileProvider);
    final assetsAsync = ref.watch(activeProfileAssetsProvider);
    final sipsAsync = ref.watch(activeProfileSipPlansProvider);

    final profileName = activeProfileAsync.value?.name ?? 'Profile';
    final sips = sipsAsync.value ?? [];

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
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search & Add Mutual Funds',
            onPressed: () => _openSearchScreen(context),
          ),
          Tooltip(
            message: 'Switch Family Profile',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                ref.read(hasSelectedInitialProfileProvider.notifier).state =
                    false;
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ProfileAvatar(
                    profile: activeProfileAsync.value, radius: 16),
              ),
            ),
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
                    _buildFilterChip('PPF', 'ppf', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('EPF', 'epf', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('GPF', 'gpf', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('NPS', 'nps', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Bonds', 'bond', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Cash & Bank', 'cash', isDark: isDark),
                    const SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Other Assets', 'other_asset',
                        isDark: isDark),
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

              // Active SIP Schedules Section
              const SizedBox(height: AppSpacing.xl),
              SectionHeader(
                title: 'SIP Schedules (${sips.length})',
                actionLabel: '+ Add SIP',
                onActionTap: () => _openAddSipDialog(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (sips.isEmpty)
                FinCard(
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.scheduled),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('No Active SIPs',
                                style: AppTypography.titleMedium),
                            Text(
                              'Set up ongoing or bulk historical SIP investments for $profileName.',
                              style: AppTypography.labelSmall.copyWith(
                                color: isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _openAddSipDialog(context),
                        child: const Text('Add SIP'),
                      ),
                    ],
                  ),
                )
              else
                ...sips.map((sip) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: SipCard(sip: sip),
                    )),

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
    );
  }

  List<FinancialItem> _filterItems(List<FinancialItem> items, String filter) {
    if (filter == 'all') return items;
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

  void _openAddSipDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const AddSipDialog(),
    );
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
              await itemsDao.deleteHoldingCascade(item.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Removed "${item.name}" and associated records.'),
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
