import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/finbalance_logo.dart';
import '../../activity/screens/activity_screen.dart';
import '../../assets/screens/assets_screen.dart';
import '../../assets/screens/mutual_fund_search_screen.dart';
import '../../liabilities/screens/liabilities_screen.dart';
import '../../overview/screens/overview_screen.dart';
import '../../profile/widgets/profile_menu_button.dart';
import '../../settings/screens/settings_screen.dart';
import '../../settings/widgets/update_dialog.dart';

/// Responsive main navigation scaffold adapting cleanly between mobile, tablet, and desktop layouts.
///
/// Features:
/// - Handles Android back navigation: switches to Overview (tab 0) before returning to Profile Selection screen.
/// - Context-aware circular Floating Action Button (`+`) customized to primary investment workflows:
///   - Overview (0): Search and schedule mutual fund investments.
///   - Assets (1): Search and schedule mutual fund investments.
///   - Liabilities (2): Suppressed (planned for future milestone).
///   - Activity (3): Suppressed (manual transactions disabled in this milestone).
///   - Settings (4): Suppressed (null).
class MainScaffold extends ConsumerStatefulWidget {
  const MainScaffold({super.key});

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> {
  int get _currentIndex => ref.read(mainTabProvider);
  set _currentIndex(int v) => ref.read(mainTabProvider.notifier).state = v;

  @override
  void initState() {
    super.initState();
    ref.read(databaseProvider).categoriesDao.repairMutualFundCategories();
    // Refresh NAVs once per launch when due under the user's refresh policy.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(navSyncServiceProvider).syncAllPortfolioSchemes(
              force: false,
              frequency: ref.read(navRefreshFrequencyProvider),
            );
      } catch (_) {}
      if (mounted) await checkForUpdates(context, ref, silent: true);
    });
  }

  static const List<Widget> _screens = <Widget>[
    OverviewScreen(),
    AssetsScreen(),
    LiabilitiesScreen(),
    ActivityScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(mainTabProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _currentIndex = 0;
        } else {
          ref.read(hasSelectedInitialProfileProvider.notifier).state = false;
        }
      },
      child: LayoutBuilder(
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
                      child: Tooltip(
                        message: 'Switch Family Profile',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            ref
                                .read(
                                    hasSelectedInitialProfileProvider.notifier)
                                .state = false;
                          },
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
                      ),
                    ),
                    trailing: const Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.md),
                          child: ProfileMenuButton(radius: 18),
                        ),
                      ),
                    ),
                    onDestinationSelected: (index) {
                      _currentIndex = index;
                    },
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.account_balance_wallet_outlined),
                        selectedIcon:
                            Icon(Icons.account_balance_wallet_rounded),
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
                _currentIndex = index;
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
      ),
    );
  }

  /// Compact circular context-aware Floating Action Button
  Widget? _buildContextualFab(BuildContext context, bool isDark) {
    // Milestone Scope Control:
    // Floating action button is enabled only for investment workflows (Overview & Assets).
    // Suppressed on Liabilities (index 2), Activity (index 3), and Settings (index 4).
    if (_currentIndex > 1) return null;
    // Only mutual funds can be added so far; other categories have no add flow.
    if (_currentIndex == 1) {
      final tab = ref.watch(assetsActiveCategoryProvider);
      if (tab != 'mutual_fund' && tab != 'all') return null;
    }

    final String tooltip =
        _currentIndex == 0 ? 'Add Investment Schedule' : 'Add Asset';

    return FloatingActionButton(
      shape: const CircleBorder(),
      backgroundColor: AppColors.brandPrimary,
      foregroundColor: Colors.white,
      tooltip: tooltip,
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const MutualFundSearchScreen(),
          ),
        );
      },
      child: const Icon(Icons.add_rounded, size: 28),
    );
  }
}
