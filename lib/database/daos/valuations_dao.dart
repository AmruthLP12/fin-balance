import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/valuation_history.dart';

part 'valuations_dao.g.dart';

@DriftAccessor(tables: [ValuationHistory])
class ValuationsDao extends DatabaseAccessor<AppDatabase>
    with _$ValuationsDaoMixin {
  ValuationsDao(super.db);

  /// Get historical valuations for a financial item ordered by date ascending.
  Future<List<ValuationHistoryData>> getValuationHistory(int financialItemId) {
    return (select(valuationHistory)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.valuationDate)]))
        .get();
  }

  /// Watch valuation history for an item.
  Stream<List<ValuationHistoryData>> watchValuationHistory(
      int financialItemId) {
    return (select(valuationHistory)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.asc(t.valuationDate)]))
        .watch();
  }

  /// Get the latest valuation record on or before a given date.
  Future<ValuationHistoryData?> getLatestValuationOnOrBefore(
      int financialItemId, DateTime date) {
    return (select(valuationHistory)
          ..where((tbl) =>
              tbl.financialItemId.equals(financialItemId) &
              tbl.valuationDate.isSmallerOrEqualValue(date))
          ..orderBy([(t) => OrderingTerm.desc(t.valuationDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Get latest valuation record for an item.
  Future<ValuationHistoryData?> getLatestValuation(int financialItemId) {
    return (select(valuationHistory)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.valuationDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Upsert a valuation (insert or update on duplicate `financialItemId` + `valuationDate`).
  Future<int> upsertValuation(ValuationHistoryCompanion valuation) {
    return into(valuationHistory).insert(
      valuation,
      onConflict: DoUpdate(
        (old) => valuation,
        target: [
          valuationHistory.financialItemId,
          valuationHistory.valuationDate
        ],
      ),
    );
  }

  /// Batch insert historical valuations.
  Future<void> insertMultipleValuations(
      List<ValuationHistoryCompanion> entries) async {
    await batch((b) {
      for (final entry in entries) {
        b.insert(
          valuationHistory,
          entry,
          onConflict: DoUpdate(
            (old) => entry,
            target: [
              valuationHistory.financialItemId,
              valuationHistory.valuationDate
            ],
          ),
        );
      }
    });
  }

  /// Delete valuations for an item.
  Future<int> deleteValuationsForItem(int financialItemId) {
    return (delete(valuationHistory)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId)))
        .go();
  }
}
