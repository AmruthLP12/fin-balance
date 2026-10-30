import 'package:drift/drift.dart';
import '../app_database.dart';
import '../precision/financial_precision.dart';
import '../tables/financial_items.dart';
import '../tables/mutual_fund_schemes.dart';
import '../tables/nav_history.dart';
import '../tables/valuation_history.dart';

part 'mutual_fund_dao.g.dart';

@DriftAccessor(tables: [
  MutualFundSchemes,
  NavHistory,
  FinancialItems,
  ValuationHistory,
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

  /// Toggle or set favorite state for a scheme.
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
