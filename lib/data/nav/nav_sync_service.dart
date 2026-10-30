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

  /// Search mutual fund schemes using local database cache and remote providers.
  Future<List<MutualFundSearchResult>> searchSchemes(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

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
      return remoteResults;
    }

    return localResults;
  }

  /// Get scheme details from local cache or remote provider.
  Future<MutualFundSchemeDetail?> getOrFetchSchemeDetails(
    int schemeCode, {
    bool forceRefresh = false,
    bool includeHistoricalNav = false,
  }) async {
    // 1. Check local cache if refresh not forced
    if (!forceRefresh) {
      final cachedScheme = await _mutualFundDao.getSchemeByCode(schemeCode);
      if (cachedScheme != null && cachedScheme.latestNavMicroPaise != null) {
        // If historical data is requested, verify if we have history
        if (includeHistoricalNav) {
          final history =
              await _mutualFundDao.getNavHistory(schemeCode, limit: 100);
          if (history.isNotEmpty) {
            return MutualFundSchemeDetail(
              schemeCode: cachedScheme.schemeCode,
              schemeName: cachedScheme.schemeName,
              fundHouse: cachedScheme.fundHouse,
              schemeType: cachedScheme.schemeType,
              schemeCategory: cachedScheme.schemeCategory,
              isin: cachedScheme.isin,
              planType: cachedScheme.planType ?? 'Regular',
              optionType: cachedScheme.optionType ?? 'Growth',
              latestNav: cachedScheme.latestNavDate != null
                  ? NavRecord(
                      date: cachedScheme.latestNavDate!,
                      navMicroPaise: cachedScheme.latestNavMicroPaise!,
                    )
                  : null,
              navHistory: history
                  .map((h) => NavRecord(
                        date: h.navDate,
                        navMicroPaise: h.navMicroPaise,
                      ))
                  .toList(),
            );
          }
        } else {
          return MutualFundSchemeDetail(
            schemeCode: cachedScheme.schemeCode,
            schemeName: cachedScheme.schemeName,
            fundHouse: cachedScheme.fundHouse,
            schemeType: cachedScheme.schemeType,
            schemeCategory: cachedScheme.schemeCategory,
            isin: cachedScheme.isin,
            planType: cachedScheme.planType ?? 'Regular',
            optionType: cachedScheme.optionType ?? 'Growth',
            latestNav: cachedScheme.latestNavDate != null
                ? NavRecord(
                    date: cachedScheme.latestNavDate!,
                    navMicroPaise: cachedScheme.latestNavMicroPaise!,
                  )
                : null,
          );
        }
      }
    }

    // 2. Query remote providers in priority order
    for (final provider in _providers) {
      try {
        final details = await provider.getSchemeDetails(
          schemeCode,
          includeHistoricalNav: includeHistoricalNav,
        );
        if (details != null) {
          // 3. Cache scheme details and latest NAV in database
          await _mutualFundDao.upsertScheme(
            MutualFundSchemesCompanion(
              schemeCode: Value(details.schemeCode),
              schemeName: Value(details.schemeName),
              fundHouse: details.fundHouse != null
                  ? Value(details.fundHouse)
                  : const Value.absent(),
              schemeType: details.schemeType != null
                  ? Value(details.schemeType)
                  : const Value.absent(),
              schemeCategory: details.schemeCategory != null
                  ? Value(details.schemeCategory)
                  : const Value.absent(),
              isin: details.isin != null
                  ? Value(details.isin)
                  : const Value.absent(),
              planType: Value(details.planType),
              optionType: Value(details.optionType),
              latestNavMicroPaise: details.latestNav != null
                  ? Value(details.latestNav!.navMicroPaise)
                  : const Value.absent(),
              latestNavDate: details.latestNav != null
                  ? Value(details.latestNav!.date)
                  : const Value.absent(),
              lastSyncedAt: Value(DateTime.now().toUtc()),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

          // 4. Cache historical NAV datapoints if provided
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
          }

          // 5. Propagate updated NAV to any profile holdings
          if (details.latestNav != null) {
            await _mutualFundDao.syncHoldingsValuation(
              schemeCode: schemeCode,
              latestNavMicroPaise: details.latestNav!.navMicroPaise,
              navDate: details.latestNav!.date,
              source: provider.providerId,
            );
          }

          return details;
        }
      } catch (_) {
        // Fallback to next provider
      }
    }

    return null;
  }

  /// Sync latest NAVs for all mutual fund schemes held across all profiles.
  Future<int> syncAllPortfolioSchemes() async {
    // Get all household mutual funds
    final householdFunds = await _financialItemsDao.db
        .select(_financialItemsDao.db.financialItems)
        .get();

    final fundCodes = <int>{};
    for (final item in householdFunds) {
      if (item.subType == 'mutual_fund' && item.externalCode != null) {
        final code = int.tryParse(item.externalCode!);
        if (code != null) {
          fundCodes.add(code);
        }
      }
    }

    var successCount = 0;
    for (final code in fundCodes) {
      final detail = await getOrFetchSchemeDetails(code, forceRefresh: true);
      if (detail != null) {
        successCount++;
      }
    }

    return successCount;
  }
}
