import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/nav/amfi_provider.dart';
import '../../data/nav/mfapi_provider.dart';
import '../../data/nav/models/nav_models.dart';
import '../../data/nav/nav_provider.dart';
import '../../data/nav/nav_sync_service.dart';
import '../../data/nav/tigzig_provider.dart';
import '../../database/app_database.dart';
import 'database_provider.dart';

final mfapiProvider = Provider<NavProvider>((ref) => MFapiProvider());
final tigzigProvider = Provider<NavProvider>((ref) => TigzigProvider());
final amfiProvider = Provider<NavProvider>((ref) => AmfiProvider());

final navSyncServiceProvider = Provider<NavSyncService>((ref) {
  final mutualFundDao = ref.watch(mutualFundDaoProvider);
  final financialItemsDao = ref.watch(financialItemsDaoProvider);
  final mfapi = ref.watch(mfapiProvider);
  final tigzig = ref.watch(tigzigProvider);
  final amfi = ref.watch(amfiProvider);

  return NavSyncService(
    mutualFundDao: mutualFundDao,
    financialItemsDao: financialItemsDao,
    providers: [mfapi, tigzig, amfi],
  );
});

/// Current mutual fund search query string.
final schemeSearchQueryProvider = StateProvider<String>((ref) => '');

/// Asynchronous search results for the given query.
final schemeSearchResultsProvider =
    FutureProvider.family<List<MutualFundSearchResult>, String>(
        (ref, query) async {
  if (query.trim().isEmpty) return [];
  final syncService = ref.watch(navSyncServiceProvider);
  return syncService.searchSchemes(query);
});

/// Configured NAV sync frequency policy ('daily', 'weekly', 'manual').
class NavRefreshFrequencyNotifier extends StateNotifier<String> {
  final Ref _ref;

  NavRefreshFrequencyNotifier(this._ref) : super('daily') {
    _loadFrequency();
  }

  Future<void> _loadFrequency() async {
    final settingsDao = _ref.read(appSettingsDaoProvider);
    final saved = await settingsDao.getSetting('nav_refresh_frequency');
    if (saved != null &&
        (saved == 'daily' || saved == 'weekly' || saved == 'manual')) {
      state = saved;
    }
  }

  Future<void> setFrequency(String newFrequency) async {
    state = newFrequency;
    final settingsDao = _ref.read(appSettingsDaoProvider);
    await settingsDao.setSetting('nav_refresh_frequency', newFrequency);
  }
}

final navRefreshFrequencyProvider =
    StateNotifierProvider<NavRefreshFrequencyNotifier, String>((ref) {
  return NavRefreshFrequencyNotifier(ref);
});

/// Stream of all bookmarked / favourite mutual fund schemes for the active profile.
final favoriteSchemesProvider = StreamProvider<List<MutualFundScheme>>((ref) {
  final profileId = ref.watch(activeProfileIdProvider);
  return ref
      .watch(mutualFundDaoProvider)
      .watchFavoriteSchemesForProfile(profileId);
});

/// Stream of whether a scheme is favorited by the active profile.
final isSchemeFavoriteProvider =
    StreamProvider.family<bool, int>((ref, schemeCode) {
  final profileId = ref.watch(activeProfileIdProvider);
  return ref
      .watch(mutualFundDaoProvider)
      .watchIsSchemeFavorite(profileId, schemeCode);
});

/// Future provider for fetching details of a specific mutual fund scheme.
final schemeDetailsProvider =
    FutureProvider.family<MutualFundSchemeDetail?, int>(
        (ref, schemeCode) async {
  final syncService = ref.watch(navSyncServiceProvider);
  final frequency = ref.watch(navRefreshFrequencyProvider);
  return syncService.getOrFetchSchemeDetails(
    schemeCode,
    includeHistoricalNav: true,
    refreshFrequency: frequency,
  );
});

/// Stream provider for locally cached scheme master data.
final schemeByCodeProvider =
    StreamProvider.family<MutualFundScheme?, int>((ref, schemeCode) {
  return ref.watch(mutualFundDaoProvider).watchSchemeByCode(schemeCode);
});

/// Future provider for historical NAV datapoints for a scheme.
final schemeNavHistoryProvider =
    FutureProvider.family<List<NavHistoryData>, int>((ref, schemeCode) {
  return ref.watch(mutualFundDaoProvider).getNavHistory(schemeCode, limit: 100);
});
