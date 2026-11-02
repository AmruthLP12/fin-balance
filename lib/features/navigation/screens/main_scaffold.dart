import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../activity/screens/activity_screen.dart';
import '../../activity/widgets/add_transaction_dialog.dart';
import '../../assets/screens/assets_screen.dart';
import '../../assets/screens/mutual_fund_search_screen.dart';
import '../../liabilities/screens/liabilities_screen.dart';
import '../../liabilities/widgets/add_liability_dialog.dart';
import '../../overview/screens/overview_screen.dart';
import '../../profile/widgets/profile_selector_button.dart';
import '../../settings/screens/settings_screen.dart';

/// Responsive main navigation scaffold adapting cleanly between mobile, tablet, and desktop layouts.
///
/// Features:
/// - Context-aware circular Floating Action Button (`+`) customized to each primary view:
///   - Overview (0): Quick add sheet for mutual funds, liabilities, and transactions.
///   - Assets (1): Add Mutual Fund schedule or custom asset.
///   - Liabilities (2): Direct launch of mobile Add Liability dialog.
///   - Activity (3): Quick record sheet for Income, Expense, or Transfer.
///   - Settings (4): Suppressed (null).
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _screens = <Widget>[
    OverviewScreen(),
    AssetsScreen(),
    LiabilitiesScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final isExpandedRail = constraints.maxWidth >= 1024;

        if (isWide) {
          // Desktop / Tablet layout with side NavigationRail
          return Scaffold(
            floatingActionButton: _buildContextualFab(context, isDark),
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _currentIndex,
                  extended: isExpandedRail,
                  minWidth: 72,
                  minExtendedWidth: 220,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurface,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: AppSpacing.sm,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: FinBalanceLogo(
                        size: 32,
                        showText: isExpandedRail,
                        showTagline: false,
                      ),
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ProfileSelectorButton(compact: !isExpandedRail),
                      ),
                    ),
                  ),
                  onDestinationSelected: (index) {
                    setState(() => _currentIndex = index);
                  },
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: Text('Overview'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.trending_up_rounded),
                      selectedIcon: Icon(Icons.trending_up_rounded),
                      label: Text('Assets'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.credit_card_outlined),
                      selectedIcon: Icon(Icons.credit_card_rounded),
                      label: Text('Liabilities'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: Text('Activity'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune_rounded),
                      label: Text('Settings'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: IndexedStack(
                        index: _currentIndex,
                        children: _screens,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Mobile layout with bottom NavigationBar
        return Scaffold(
          floatingActionButton: _buildContextualFab(context, isDark),
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Overview',
              ),
              NavigationDestination(
                icon: Icon(Icons.trending_up_rounded),
                selectedIcon: Icon(Icons.trending_up_rounded),
                label: 'Assets',
              ),
              NavigationDestination(
                icon: Icon(Icons.credit_card_outlined),
                selectedIcon: Icon(Icons.credit_card_rounded),
                label: 'Liabilities',
              ),
              NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long_rounded),
                label: 'Activity',
              ),
              NavigationDestination(
                icon: Icon(Icons.tune_outlined),
                selectedIcon: Icon(Icons.tune_rounded),
                label: 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }

  /// Compact circular context-aware Floating Action Button
  Widget? _buildContextualFab(BuildContext context, bool isDark) {
    if (_currentIndex == 4) return null; // No FAB on Settings

    String tooltip = 'Add';
    VoidCallback? onPressed;

    if (_currentIndex == 0) {
      // Overview
      tooltip = 'Quick Add';
      onPressed = () => _showOverviewAddSheet(context, isDark);
    } else if (_currentIndex == 1) {
      // Assets
      tooltip = 'Add Asset';
      onPressed = () => _showAssetsAddSheet(context, isDark);
    } else if (_currentIndex == 2) {
      // Liabilities
      tooltip = 'Add Liability / Loan';
      onPressed = () => AddLiabilityDialog.show(context);
    } else if (_currentIndex == 3) {
      // Activity
      tooltip = 'Record Activity';
      onPressed = () => _showActivityAddSheet(context, isDark);
    }

    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: Colors.white,
      tooltip: tooltip,
      onPressed: onPressed,
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }

  void _showOverviewAddSheet(BuildContext context, bool isDark) {
    final activeProfileId = ref.read(activeProfileIdProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Quick Financial Action',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: const Icon(Icons.trending_up_rounded,
                      color: AppColors.asset),
                  title: const Text('Add Mutual Fund Investment'),
                  subtitle:
                      const Text('Search schemes and schedule installments'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MutualFundSearchScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card_rounded,
                      color: AppColors.liability),
                  title: const Text('Add Liability / Debt'),
                  subtitle:
                      const Text('Home loans, personal loans, vehicle loans'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddLiabilityDialog.show(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded,
                      color: AppColors.asset),
                  title: const Text('Record Income'),
                  subtitle:
                      const Text('Salary, dividend, interest, or consulting'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddTransactionDialog.show(
                      context,
                      initialType: 'income',
                      preselectedProfileId: activeProfileId,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.liability),
                  title: const Text('Record Expense'),
                  subtitle: const Text('Living expenses, bills, or shopping'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddTransactionDialog.show(
                      context,
                      initialType: 'expense',
                      preselectedProfileId: activeProfileId,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAssetsAddSheet(BuildContext context, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Add Asset',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: const Icon(Icons.trending_up_rounded,
                      color: AppColors.asset),
                  title: const Text('Mutual Fund Investment Schedule'),
                  subtitle: const Text(
                      'Search AMFI schemes & configure installments'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const MutualFundSearchScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.savings_rounded,
                      color: AppColors.brandPrimaryLight),
                  title: const Text('Other Asset Class'),
                  subtitle:
                      const Text('Fixed deposits, PPF, gold, or bank accounts'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Direct forms for Fixed Deposits, Gold, and PPF will be enabled in upcoming asset milestones.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showActivityAddSheet(BuildContext context, bool isDark) {
    final activeProfileId = ref.read(activeProfileIdProvider);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          isDark ? AppColors.darkSurface : AppColors.lightBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      borderRadius: AppSpacing.borderRadiusPill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Text(
                    'Record Transaction',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ListTile(
                  leading: const Icon(Icons.arrow_downward_rounded,
                      color: AppColors.asset),
                  title: const Text('Add Income'),
                  subtitle:
                      const Text('Record inflow from salary, interest, etc.'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddTransactionDialog.show(
                      context,
                      initialType: 'income',
                      preselectedProfileId: activeProfileId,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.arrow_upward_rounded,
                      color: AppColors.liability),
                  title: const Text('Add Expense'),
                  subtitle:
                      const Text('Record living costs, bills, or purchases'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddTransactionDialog.show(
                      context,
                      initialType: 'expense',
                      preselectedProfileId: activeProfileId,
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.swap_horiz_rounded,
                      color: AppColors.brandPrimaryLight),
                  title: const Text('Record Transfer'),
                  subtitle: const Text(
                      'Internal transfer between cash and bank accounts'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AddTransactionDialog.show(
                      context,
                      initialType: 'transfer',
                      preselectedProfileId: activeProfileId,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
