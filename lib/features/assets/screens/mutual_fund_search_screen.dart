import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/nav_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/nav/models/nav_models.dart';
import '../../../database/app_database.dart';
import '../widgets/mutual_fund_card.dart';
import '../widgets/scheme_details_sheet.dart';

/// Screen for searching mutual fund schemes, exploring NAV values, and managing favourites.
class MutualFundSearchScreen extends ConsumerStatefulWidget {
  const MutualFundSearchScreen({super.key});

  @override
  ConsumerState<MutualFundSearchScreen> createState() =>
      _MutualFundSearchScreenState();
}

class _MutualFundSearchScreenState extends ConsumerState<MutualFundSearchScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;
  Timer? _debounceTimer;
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _activeQuery = text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final favoritesAsync = ref.watch(favoriteSchemesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Funds & NAV'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Search Schemes'),
            Tab(text: 'Favourites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Live Scheme Search
          _buildSearchTab(context, isDark),

          // Tab 2: Favourites / Bookmarks
          _buildFavoritesTab(context, favoritesAsync, isDark),
        ],
      ),
    );
  }

  Widget _buildSearchTab(BuildContext context, bool isDark) {
    final searchResultsAsync = _activeQuery.isEmpty
        ? null
        : ref.watch(schemeSearchResultsProvider(_activeQuery));

    return Column(
      children: [
        // Search TextField Header
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by fund name (e.g. Parag Parikh, HDFC)...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'NAV Source: MFapi.in (Primary) • Offline Cached',
                    style: AppTypography.labelSmall.copyWith(
                      color: isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Results view
        Expanded(
          child: _activeQuery.isEmpty
              ? const EmptyStateView(
                  icon: Icons.manage_search_rounded,
                  title: 'Search Mutual Funds',
                  description:
                      'Search thousands of direct and regular mutual fund schemes in India with live AMFI NAV synchronization.',
                )
              : searchResultsAsync!.when(
                  data: (results) {
                    if (results.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.search_off_rounded,
                        title: 'No Schemes Found',
                        description:
                            'No schemes matching "$_activeQuery". Try checking for spelling or another keyword.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final scheme = results[index];
                        return MutualFundCard(
                          scheme: scheme,
                          onTap: () =>
                              _openSchemeDetails(context, scheme.schemeCode),
                          onFavoriteToggle: () =>
                              _toggleFavorite(scheme.schemeCode, true),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (err, _) => EmptyStateView(
                    icon: Icons.cloud_off_rounded,
                    title: 'Search Error',
                    description:
                        'Could not connect to NAV provider. Please check network connection.',
                    actionLabel: 'Retry',
                    onAction: () => ref.refresh(
                      schemeSearchResultsProvider(_activeQuery),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFavoritesTab(
    BuildContext context,
    AsyncValue<List<MutualFundScheme>> favoritesAsync,
    bool isDark,
  ) {
    return favoritesAsync.when(
      data: (favorites) {
        if (favorites.isEmpty) {
          return const EmptyStateView(
            icon: Icons.star_border_rounded,
            title: 'No Favourites Yet',
            description:
                'Bookmark schemes using the star icon to track their daily NAV updates and historical returns.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: favorites.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final fund = favorites[index];
            final result = MutualFundSearchResult(
              schemeCode: fund.schemeCode,
              schemeName: fund.schemeName,
              fundHouse: fund.fundHouse,
              planType: fund.planType ?? 'Regular',
              optionType: fund.optionType ?? 'Growth',
            );

            return MutualFundCard(
              scheme: result,
              latestNavMicroPaise: fund.latestNavMicroPaise,
              latestNavDate: fund.latestNavDate,
              isFavorite: true,
              onFavoriteToggle: () => _toggleFavorite(fund.schemeCode, false),
              onTap: () => _openSchemeDetails(context, fund.schemeCode),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error loading favorites: $err')),
    );
  }

  void _openSchemeDetails(BuildContext context, int schemeCode) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SchemeDetailsSheet(schemeCode: schemeCode),
    );
  }

  Future<void> _toggleFavorite(int schemeCode, bool targetFavorite) async {
    final dao = ref.read(mutualFundDaoProvider);
    await dao.setFavorite(schemeCode, targetFavorite);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(targetFavorite
              ? 'Added to favourites!'
              : 'Removed from favourites.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
