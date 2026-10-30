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

/// Stream of all bookmarked / favourite mutual fund schemes.
final favoriteSchemesProvider = StreamProvider<List<MutualFundScheme>>((ref) {
  return ref.watch(mutualFundDaoProvider).watchFavoriteSchemes();
});

/// Future provider for fetching details of a specific mutual fund scheme.
final schemeDetailsProvider =
    FutureProvider.family<MutualFundSchemeDetail?, int>(
        (ref, schemeCode) async {
  final syncService = ref.watch(navSyncServiceProvider);
  return syncService.getOrFetchSchemeDetails(schemeCode,
      includeHistoricalNav: true);
});
