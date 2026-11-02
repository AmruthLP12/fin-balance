import 'package:drift/drift.dart';
import '../app_database.dart';
import '../precision/financial_precision.dart';
import '../tables/financial_items.dart';
import '../tables/mutual_fund_schemes.dart';
import '../tables/nav_history.dart';
import '../tables/profile_favorite_schemes.dart';
import '../tables/valuation_history.dart';

part 'mutual_fund_dao.g.dart';

@DriftAccessor(tables: [
  MutualFundSchemes,
  NavHistory,
  FinancialItems,
  ValuationHistory,
  ProfileFavoriteSchemes,
])
class MutualFundDao extends DatabaseAccessor<AppDatabase>
    with _$MutualFundDaoMixin {
  MutualFundDao(super.db);

  /// Search locally cached mutual fund schemes by name, fund house, or scheme code.
  Future<List<MutualFundScheme>> searchLocalSchemes(
    String query, {
    int limit = 50,
  }) {
    final cleanQuery = query.trim().toLowerCase();
    final selectQuery = select(mutualFundSchemes);

    if (cleanQuery.isNotEmpty) {
      final code = int.tryParse(cleanQuery);
      if (code != null) {
        selectQuery.where((tbl) =>
            tbl.schemeCode.equals(code) |
            tbl.schemeName.lower().like('%$cleanQuery%'));
      } else {
        selectQuery.where((tbl) =>
            tbl.schemeName.lower().like('%$cleanQuery%') |
            tbl.fundHouse.lower().like('%$cleanQuery%'));
      }
    }

    selectQuery
      ..orderBy([
        (t) => OrderingTerm.desc(t.isFavorite),
        (t) => OrderingTerm.asc(t.schemeName),
      ])
      ..limit(limit);

    return selectQuery.get();
  }

  /// Get scheme by its unique AMFI code.
  Future<MutualFundScheme?> getSchemeByCode(int schemeCode) {
    return (select(mutualFundSchemes)
          ..where((tbl) => tbl.schemeCode.equals(schemeCode)))
        .getSingleOrNull();
  }

  /// Get all mutual fund schemes stored in local database.
  Future<List<MutualFundScheme>> getAllSchemes() {
    return select(mutualFundSchemes).get();
  }

  /// Watch a single scheme by AMFI code.
  Stream<MutualFundScheme?> watchSchemeByCode(int schemeCode) {
    return (select(mutualFundSchemes)
          ..where((tbl) => tbl.schemeCode.equals(schemeCode)))
        .watchSingleOrNull();
  }

  /// Watch favorite/bookmarked schemes.
  Stream<List<MutualFundScheme>> watchFavoriteSchemes() {
    return (select(mutualFundSchemes)
          ..where((tbl) => tbl.isFavorite.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.schemeName)]))
        .watch();
  }

  /// Watch favorite/bookmarked schemes for a specific profile.
  Stream<List<MutualFundScheme>> watchFavoriteSchemesForProfile(int profileId) {
    final query = select(profileFavoriteSchemes).join([
      innerJoin(
        mutualFundSchemes,
        mutualFundSchemes.schemeCode
            .equalsExp(profileFavoriteSchemes.schemeCode),
      ),
    ])
      ..where(profileFavoriteSchemes.profileId.equals(profileId))
      ..orderBy([OrderingTerm.asc(mutualFundSchemes.schemeName)]);

    return query.watch().map(
        (rows) => rows.map((row) => row.readTable(mutualFundSchemes)).toList());
  }

  /// Get favorite schemes for a profile.
  Future<List<MutualFundScheme>> getFavoriteSchemesForProfile(int profileId) {
    final query = select(profileFavoriteSchemes).join([
      innerJoin(
        mutualFundSchemes,
        mutualFundSchemes.schemeCode
            .equalsExp(profileFavoriteSchemes.schemeCode),
      ),
    ])
      ..where(profileFavoriteSchemes.profileId.equals(profileId))
      ..orderBy([OrderingTerm.asc(mutualFundSchemes.schemeName)]);

    return query.get().then(
        (rows) => rows.map((row) => row.readTable(mutualFundSchemes)).toList());
  }

  /// Check whether a scheme is favorited by a specific profile.
  Future<bool> isSchemeFavorite(int profileId, int schemeCode) async {
    final record = await (select(profileFavoriteSchemes)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.schemeCode.equals(schemeCode)))
        .getSingleOrNull();
    return record != null;
  }

  /// Watch whether a scheme is favorited by a specific profile.
  Stream<bool> watchIsSchemeFavorite(int profileId, int schemeCode) {
    return (select(profileFavoriteSchemes)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.schemeCode.equals(schemeCode)))
        .watchSingleOrNull()
        .map((record) => record != null);
  }

  /// Toggle favorite state for a specific profile.
  /// If favorited, removes it. If not favorited, adds it and ensures master scheme exists.
  /// Returns the new favorite state (true if now favorited, false if removed).
  Future<bool> toggleFavorite({
    required int profileId,
    required int schemeCode,
    required String schemeName,
    String? fundHouse,
    String? planType,
    String? optionType,
  }) async {
    return transaction(() async {
      // 1. Ensure scheme master entry exists
      await upsertScheme(
        MutualFundSchemesCompanion(
          schemeCode: Value(schemeCode),
          schemeName: Value(schemeName),
          fundHouse:
              fundHouse != null ? Value(fundHouse) : const Value.absent(),
          planType: planType != null ? Value(planType) : const Value.absent(),
          optionType:
              optionType != null ? Value(optionType) : const Value.absent(),
        ),
      );

      // 2. Check if already favorited by this profile
      final existing = await (select(profileFavoriteSchemes)
            ..where((tbl) =>
                tbl.profileId.equals(profileId) &
                tbl.schemeCode.equals(schemeCode)))
          .getSingleOrNull();

      if (existing != null) {
        // Remove favorite
        await (delete(profileFavoriteSchemes)
              ..where((tbl) => tbl.id.equals(existing.id)))
            .go();
        return false;
      } else {
        // Add favorite (unique key on {profileId, schemeCode} prevents duplicates)
        await into(profileFavoriteSchemes).insert(
          ProfileFavoriteSchemesCompanion(
            profileId: Value(profileId),
            schemeCode: Value(schemeCode),
          ),
          onConflict: DoNothing(),
        );
        return true;
      }
    });
  }

  /// Toggle or set favorite state for a scheme globally (backward compatibility).
  Future<void> setFavorite(int schemeCode, bool isFavorite) async {
    await (update(mutualFundSchemes)
          ..where((tbl) => tbl.schemeCode.equals(schemeCode)))
        .write(MutualFundSchemesCompanion(
      isFavorite: Value(isFavorite),
      updatedAt: Value(DateTime.now().toUtc()),
    ));
  }

  /// Upsert a single mutual fund scheme master record.
  Future<int> upsertScheme(MutualFundSchemesCompanion scheme) {
    return into(mutualFundSchemes).insert(
      scheme,
      onConflict: DoUpdate(
        (old) => scheme,
        target: [mutualFundSchemes.schemeCode],
      ),
    );
  }

  /// Batch upsert schemes into local master cache.
  Future<void> upsertSchemes(List<MutualFundSchemesCompanion> schemes) async {
    await batch((b) {
      for (final scheme in schemes) {
        b.insert(
          mutualFundSchemes,
          scheme,
          onConflict: DoUpdate(
            (old) => scheme,
            target: [mutualFundSchemes.schemeCode],
          ),
        );
      }
    });
  }

  /// Batch upsert NAV historical records for a scheme.
  Future<void> upsertNavRecords(
    int schemeCode,
    List<NavHistoryCompanion> records,
  ) async {
    await batch((b) {
      for (final record in records) {
        b.insert(
          navHistory,
          record,
          onConflict: DoUpdate(
            (old) => record,
            target: [navHistory.schemeCode, navHistory.navDate],
          ),
        );
      }
    });
  }

  /// Get historical NAV records for a scheme ordered by date descending.
  Future<List<NavHistoryData>> getNavHistory(
    int schemeCode, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) {
    final query = select(navHistory)
      ..where((tbl) => tbl.schemeCode.equals(schemeCode));

    if (startDate != null) {
      query.where((tbl) => tbl.navDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where((tbl) => tbl.navDate.isSmallerOrEqualValue(endDate));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.navDate)]);

    if (limit != null) {
      query.limit(limit);
    }

    return query.get();
  }

  /// Get latest NAV record from NavHistory.
  Future<NavHistoryData?> getLatestNavFromHistory(int schemeCode) {
    return (select(navHistory)
          ..where((tbl) => tbl.schemeCode.equals(schemeCode))
          ..orderBy([(t) => OrderingTerm.desc(t.navDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Find the latest available historical NAV on or before [targetDate] for a scheme.
  /// Handles weekends and public market holidays by selecting the most recent prior trading day.
  Future<NavHistoryData?> getNavOnOrBefore(
      int schemeCode, DateTime targetDate) {
    final endOfDate = DateTime.utc(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      23,
      59,
      59,
    );
    return (select(navHistory)
          ..where((tbl) =>
              tbl.schemeCode.equals(schemeCode) &
              tbl.navDate.isSmallerOrEqualValue(endOfDate))
          ..orderBy([(t) => OrderingTerm.desc(t.navDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Synchronize portfolio holdings valuation across all profiles holding this scheme.
  ///
  /// Recalculates `currentValuationPaise` for all [FinancialItems] linked to `schemeCode`,
  /// and logs an updated [ValuationHistory] entry.
  Future<int> syncHoldingsValuation({
    required int schemeCode,
    required int latestNavMicroPaise,
    required DateTime navDate,
    String source = 'mfapi',
  }) async {
    final codeStr = schemeCode.toString();

    // Find all financial items matching this scheme
    final items = await (select(financialItems)
          ..where((tbl) =>
              tbl.subType.equals('mutual_fund') &
              tbl.externalCode.equals(codeStr) &
              tbl.status.equals('active')))
        .get();

    var updatedCount = 0;

    for (final item in items) {
      final newValuationPaise = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: item.unitCountMicroUnits,
        navMicroPaise: latestNavMicroPaise,
      );

      // 1. Update item current valuation
      await (update(financialItems)..where((tbl) => tbl.id.equals(item.id)))
          .write(FinancialItemsCompanion(
        currentValuationPaise: Value(newValuationPaise),
        updatedAt: Value(DateTime.now().toUtc()),
      ));

      // 2. Insert or update valuation history
      await into(valuationHistory).insert(
        ValuationHistoryCompanion(
          financialItemId: Value(item.id),
          valuationDate: Value(navDate),
          valuationPaise: Value(newValuationPaise),
          unitPriceMicroPaise: Value(latestNavMicroPaise),
          sourceProvider: Value(source),
        ),
        onConflict: DoUpdate(
          (old) => ValuationHistoryCompanion(
            valuationPaise: Value(newValuationPaise),
            unitPriceMicroPaise: Value(latestNavMicroPaise),
            sourceProvider: Value(source),
          ),
          target: [
            valuationHistory.financialItemId,
            valuationHistory.valuationDate,
          ],
        ),
      );

      updatedCount++;
    }

    return updatedCount;
  }
}
