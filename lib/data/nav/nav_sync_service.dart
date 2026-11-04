import 'package:drift/drift.dart';
import '../../database/app_database.dart';
import '../../database/daos/financial_items_dao.dart';
import '../../database/daos/mutual_fund_dao.dart';
import 'amfi_provider.dart';
import 'mfapi_provider.dart';
import 'models/nav_models.dart';
import 'nav_provider.dart';
import 'tigzig_provider.dart';

/// Central coordinator for mutual fund scheme discovery, NAV synchronization,
/// multi-provider failover, and local SQLite caching.
class NavSyncService {
  final MutualFundDao _mutualFundDao;
  final FinancialItemsDao _financialItemsDao;
  final List<NavProvider> _providers;
  final Map<String,
          ({DateTime timestamp, List<MutualFundSearchResult> results})>
      _searchCache = {};

  NavSyncService({
    required MutualFundDao mutualFundDao,
    required FinancialItemsDao financialItemsDao,
    List<NavProvider>? providers,
  })  : _mutualFundDao = mutualFundDao,
        _financialItemsDao = financialItemsDao,
        _providers = providers ??
            [
              MFapiProvider(),
              TigzigProvider(),
              AmfiProvider(),
            ];

  /// Clears in-memory search query cache.
  void clearSearchCache() {
    _searchCache.clear();
  }

  /// Determines whether NAV synchronization is due based on the last sync timestamp
  /// and the configured refresh policy ('daily', 'weekly', 'manual').
  bool isSyncDue(DateTime? lastSyncedAt, String frequency) {
    if (frequency == 'manual') return false;
    if (lastSyncedAt == null) return true;
    final now = DateTime.now().toUtc();
    if (frequency == 'weekly') {
      return now.difference(lastSyncedAt).inDays >= 7;
    }
    // Default 'daily' (24 hours)
    return now.difference(lastSyncedAt).inHours >= 24;
  }

  /// Returns the next eligible sync timestamp, or null if sync is set to 'manual'.
  DateTime? getNextEligibleSync(DateTime? lastSyncedAt, String frequency) {
    if (frequency == 'manual') return null;
    if (lastSyncedAt == null) return DateTime.now().toUtc();
    if (frequency == 'weekly') {
      return lastSyncedAt.add(const Duration(days: 7));
    }
    // Default 'daily'
    return lastSyncedAt.add(const Duration(hours: 24));
  }

  /// Returns the latest successful sync timestamp recorded across any mutual fund scheme.
  Future<DateTime?> getLastSuccessfulSyncTime() async {
    final schemes = await _mutualFundDao.getAllSchemes();
    DateTime? latest;
    for (final s in schemes) {
      if (s.lastSyncedAt != null) {
        if (latest == null || s.lastSyncedAt!.isAfter(latest)) {
          latest = s.lastSyncedAt;
        }
      }
    }
    return latest;
  }

  /// Search mutual fund schemes using local database cache and remote providers.
  /// Hits fast in-memory query cache if searched recently within 10 minutes.
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final cacheKey = clean.toLowerCase();
    final cachedEntry = _searchCache[cacheKey];
    if (cachedEntry != null &&
        DateTime.now().difference(cachedEntry.timestamp).inMinutes < 10) {
      return cachedEntry.results;
    }

    // 1. Check local database cache first
    final localSchemes =
        await _mutualFundDao.searchLocalSchemes(clean, limit: 30);
    final localResults = localSchemes
        .map((s) => MutualFundSearchResult(
              schemeCode: s.schemeCode,
              schemeName: s.schemeName,
              fundHouse: s.fundHouse,
              planType: s.planType ??
                  MutualFundSearchResult.detectPlanType(s.schemeName),
              optionType: s.optionType ??
                  MutualFundSearchResult.detectOptionType(s.schemeName),
            ))
        .toList();

    // 2. Query remote providers in priority order
    List<MutualFundSearchResult> remoteResults = [];
    for (final provider in _providers) {
      try {
        final results = await provider.searchSchemes(clean);
        if (results.isNotEmpty) {
          remoteResults = results;
          break;
        }
      } catch (_) {
        // Continue to fallback provider
      }
    }

    if (remoteResults.isNotEmpty) {
      // 3. Cache discovered schemes into local database
      final companions = remoteResults.map((r) {
        return MutualFundSchemesCompanion(
          schemeCode: Value(r.schemeCode),
          schemeName: Value(r.schemeName),
          fundHouse:
              r.fundHouse != null ? Value(r.fundHouse) : const Value.absent(),
          planType: Value(r.planType),
          optionType: Value(r.optionType),
        );
      }).toList();

      await _mutualFundDao.upsertSchemes(companions);
      // Keep locally known schemes (e.g. old or closed funds the provider no longer lists).
      final remoteCodes = remoteResults.map((r) => r.schemeCode).toSet();
      final merged = [
        ...remoteResults,
        ...localResults.where((r) => !remoteCodes.contains(r.schemeCode)),
      ];
      _searchCache[cacheKey] = (timestamp: DateTime.now(), results: merged);
      return merged;
    }

    if (localResults.isNotEmpty) {
      _searchCache[cacheKey] =
          (timestamp: DateTime.now(), results: localResults);
    }
    return localResults;
  }

  static String _historyKey(int schemeCode) => 'nav_history_full_$schemeCode';

  Future<MutualFundSchemeDetail> _detailFromCache(
    MutualFundScheme scheme,
    bool includeHistoricalNav,
  ) async {
    final history = includeHistoricalNav
        ? await _mutualFundDao.getNavHistory(scheme.schemeCode, limit: 100)
        : <NavHistoryData>[];
    return MutualFundSchemeDetail(
      schemeCode: scheme.schemeCode,
      schemeName: scheme.schemeName,
      fundHouse: scheme.fundHouse,
      schemeType: scheme.schemeType,
      schemeCategory: scheme.schemeCategory,
      isin: scheme.isin,
      planType: scheme.planType ??
          MutualFundSearchResult.detectPlanType(scheme.schemeName),
      optionType: scheme.optionType ??
          MutualFundSearchResult.detectOptionType(scheme.schemeName),
      latestNav:
          scheme.latestNavDate != null && scheme.latestNavMicroPaise != null
              ? NavRecord(
                  date: scheme.latestNavDate!,
                  navMicroPaise: scheme.latestNavMicroPaise!,
                )
              : null,
      navHistory: history
          .map(
              (h) => NavRecord(date: h.navDate, navMicroPaise: h.navMicroPaise))
          .toList(),
    );
  }

  /// Get scheme details from local cache or remote provider.
  Future<MutualFundSchemeDetail?> getOrFetchSchemeDetails(
    int schemeCode, {
    bool forceRefresh = false,
    bool includeHistoricalNav = false,
    String refreshFrequency = 'daily',
  }) async {
    final cachedScheme = await _mutualFundDao.getSchemeByCode(schemeCode);
    final historyKey = _historyKey(schemeCode);
    final hasFullHistory =
        await _mutualFundDao.db.appSettingsDao.getSetting(historyKey) != null;
    final needFullHistory = includeHistoricalNav && !hasFullHistory;

    // 1. Serve from the local cache while it is fresh under the refresh policy and
    // already holds the history the caller needs; otherwise go online.
    if (!forceRefresh &&
        !needFullHistory &&
        cachedScheme != null &&
        cachedScheme.latestNavMicroPaise != null &&
        !isSyncDue(cachedScheme.lastSyncedAt, refreshFrequency)) {
      return _detailFromCache(cachedScheme, includeHistoricalNav);
    }

    // 2. Query remote providers in priority order (MFapi -> Tigzig -> AMFI)
    for (final provider in _providers) {
      try {
        // Full history is downloaded once per scheme; later refreshes fetch only the latest NAV.
        final details = await provider.getSchemeDetails(
          schemeCode,
          includeHistoricalNav: needFullHistory,
        );
        if (details != null) {
          // Check if remote NAV is older than cached NAV (prevent regression)
          final isOlderNav = cachedScheme?.latestNavDate != null &&
              details.latestNav != null &&
              details.latestNav!.date.isBefore(cachedScheme!.latestNavDate!);

          final navMicroPaiseToStore = isOlderNav
              ? cachedScheme.latestNavMicroPaise
              : (details.latestNav?.navMicroPaise ??
                  cachedScheme?.latestNavMicroPaise);

          final navDateToStore = isOlderNav
              ? cachedScheme.latestNavDate
              : (details.latestNav?.date ?? cachedScheme?.latestNavDate);

          // 3. Cache scheme details and latest NAV in database
          await _mutualFundDao.upsertScheme(
            MutualFundSchemesCompanion(
              schemeCode: Value(details.schemeCode),
              schemeName: Value(details.schemeName),
              fundHouse: details.fundHouse != null
                  ? Value(details.fundHouse)
                  : (cachedScheme?.fundHouse != null
                      ? Value(cachedScheme!.fundHouse)
                      : const Value.absent()),
              schemeType: details.schemeType != null
                  ? Value(details.schemeType)
                  : (cachedScheme?.schemeType != null
                      ? Value(cachedScheme!.schemeType)
                      : const Value.absent()),
              schemeCategory: details.schemeCategory != null
                  ? Value(details.schemeCategory)
                  : (cachedScheme?.schemeCategory != null
                      ? Value(cachedScheme!.schemeCategory)
                      : const Value.absent()),
              isin: details.isin != null
                  ? Value(details.isin)
                  : (cachedScheme?.isin != null
                      ? Value(cachedScheme!.isin)
                      : const Value.absent()),
              planType: Value(details.planType),
              optionType: Value(details.optionType),
              latestNavMicroPaise: navMicroPaiseToStore != null
                  ? Value(navMicroPaiseToStore)
                  : const Value.absent(),
              latestNavDate: navDateToStore != null
                  ? Value(navDateToStore)
                  : const Value.absent(),
              lastSyncedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

          // 4. Cache historical NAV datapoints into NavHistory
          if (details.navHistory.isNotEmpty) {
            final companions = details.navHistory.map((rec) {
              return NavHistoryCompanion(
                schemeCode: Value(schemeCode),
                navDate: Value(rec.date),
                navMicroPaise: Value(rec.navMicroPaise),
                sourceProvider: Value(provider.providerId),
              );
            }).toList();
            await _mutualFundDao.upsertNavRecords(schemeCode, companions);
          } else if (details.latestNav != null) {
            await _mutualFundDao.upsertNavRecords(schemeCode, [
              NavHistoryCompanion(
                schemeCode: Value(schemeCode),
                navDate: Value(details.latestNav!.date),
                navMicroPaise: Value(details.latestNav!.navMicroPaise),
                sourceProvider: Value(provider.providerId),
              ),
            ]);
          }

          // 5. Propagate updated NAV to any portfolio holdings across all profiles
          if (navMicroPaiseToStore != null && navDateToStore != null) {
            await _mutualFundDao.syncHoldingsValuation(
              schemeCode: schemeCode,
              latestNavMicroPaise: navMicroPaiseToStore,
              navDate: navDateToStore,
              source: provider.providerId,
            );
          }

          if (details.navHistory.length > 1) {
            await _mutualFundDao.db.appSettingsDao.setSetting(
                historyKey, DateTime.now().toUtc().toIso8601String());
          }

          if (includeHistoricalNav && !needFullHistory) {
            final fresh = await _mutualFundDao.getSchemeByCode(schemeCode);
            if (fresh != null) return await _detailFromCache(fresh, true);
          }
          return details;
        }
      } catch (_) {
        // Fallback to next provider
      }
    }

    // 6. If all remote providers failed, fall back to the local cache if present
    if (cachedScheme != null) {
      return _detailFromCache(cachedScheme, includeHistoricalNav);
    }

    return null;
  }

  /// Synchronize the latest NAV for a specific individual scheme.
  Future<SchemeNavSyncResult> syncSchemeNav(
    int schemeCode, {
    bool force = true,
    String frequency = 'daily',
  }) async {
    final cachedScheme = await _mutualFundDao.getSchemeByCode(schemeCode);
    final schemeName = cachedScheme?.schemeName ?? 'Scheme $schemeCode';

    // Respect refresh policy: if not forced and sync is not due, return cached state
    if (!force && !isSyncDue(cachedScheme?.lastSyncedAt, frequency)) {
      return SchemeNavSyncResult(
        schemeCode: schemeCode,
        schemeName: schemeName,
        success: true,
        navMicroPaise: cachedScheme?.latestNavMicroPaise,
        navDate: cachedScheme?.latestNavDate,
        provider: 'Cache-Valid (Sync Not Due)',
      );
    }

    for (final provider in _providers) {
      try {
        final navRecord = await provider.getLatestNav(schemeCode);
        if (navRecord != null) {
          // Do not overwrite a newer NAV with an older NAV
          final isOlder = cachedScheme?.latestNavDate != null &&
              navRecord.date.isBefore(cachedScheme!.latestNavDate!);

          final navMicro = isOlder
              ? cachedScheme.latestNavMicroPaise
              : navRecord.navMicroPaise;
          final navDate = isOlder ? cachedScheme.latestNavDate : navRecord.date;

          if (navMicro == null || navDate == null) continue;

          // 1. Update scheme master
          await _mutualFundDao.upsertScheme(
            MutualFundSchemesCompanion(
              schemeCode: Value(schemeCode),
              schemeName: Value(schemeName),
              latestNavMicroPaise: Value(navMicro),
              latestNavDate: Value(navDate),
              lastSyncedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

          // 2. Insert into NavHistory (prevent duplicate entries)
          await _mutualFundDao.upsertNavRecords(schemeCode, [
            NavHistoryCompanion(
              schemeCode: Value(schemeCode),
              navDate: Value(navRecord.date),
              navMicroPaise: Value(navRecord.navMicroPaise),
              sourceProvider: Value(provider.providerId),
            ),
          ]);

          // 3. Propagate updated valuation to all profile holdings
          await _mutualFundDao.syncHoldingsValuation(
            schemeCode: schemeCode,
            latestNavMicroPaise: navMicro,
            navDate: navDate,
            source: provider.providerId,
          );

          return SchemeNavSyncResult(
            schemeCode: schemeCode,
            schemeName: schemeName,
            success: true,
            navMicroPaise: navMicro,
            navDate: navDate,
            provider: provider.providerName,
          );
        }
      } catch (e) {
        // Continue to fallback provider
      }
    }

    return SchemeNavSyncResult(
      schemeCode: schemeCode,
      schemeName: schemeName,
      success: false,
      errorMessage:
          'Could not connect to online NAV providers. Existing cached valuation preserved.',
    );
  }

  /// Sync latest NAVs for all mutual fund schemes held across all profiles and bookmarked favourites.
  Future<PortfolioSyncSummary> syncAllPortfolioSchemes({
    bool force = true,
    String frequency = 'daily',
  }) async {
    final distinctCodes = <int>{};

    // 1. Collect all mutual funds held across all profiles
    final householdFunds = await _financialItemsDao.db
        .select(_financialItemsDao.db.financialItems)
        .get();

    for (final item in householdFunds) {
      if (item.subType == 'mutual_fund' &&
          item.externalCode != null &&
          item.status == 'active') {
        final code = int.tryParse(item.externalCode!);
        if (code != null) distinctCodes.add(code);
      }
    }

    // 2. Collect all bookmarked favourite schemes (legacy + profile-specific)
    final favoriteSchemes =
        await (_mutualFundDao.db.select(_mutualFundDao.db.mutualFundSchemes)
              ..where((tbl) => tbl.isFavorite.equals(true)))
            .get();

    for (final s in favoriteSchemes) {
      distinctCodes.add(s.schemeCode);
    }

    final profileFavs = await _mutualFundDao.db
        .select(_mutualFundDao.db.profileFavoriteSchemes)
        .get();
    for (final f in profileFavs) {
      distinctCodes.add(f.schemeCode);
    }

    final results = <SchemeNavSyncResult>[];
    int successCount = 0;
    int failedCount = 0;
    String? primaryProvider;

    for (final code in distinctCodes) {
      final res = await syncSchemeNav(code, force: force, frequency: frequency);
      results.add(res);
      if (res.success) {
        successCount++;
        primaryProvider ??= res.provider;
      } else {
        failedCount++;
      }
    }

    // Record last sync timestamp in AppSettings
    final now = DateTime.now().toUtc();
    await _mutualFundDao.db.appSettingsDao.setSetting(
      'last_nav_sync_time',
      now.toIso8601String(),
    );

    return PortfolioSyncSummary(
      totalSchemes: distinctCodes.length,
      successCount: successCount,
      failedCount: failedCount,
      results: results,
      syncTime: now,
      primaryProvider: primaryProvider,
    );
  }
}
