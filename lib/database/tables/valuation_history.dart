import 'package:drift/drift.dart';

/// Table storing historical valuations for assets (e.g. daily mutual fund NAV, stock closes)
/// and balance snapshots for liabilities.
@TableIndex(name: 'idx_valuation_date', columns: {#valuationDate})
class ValuationHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get financialItemId => integer().customConstraint(
      'NOT NULL REFERENCES financial_items(id) ON DELETE CASCADE')();
  DateTimeColumn get valuationDate => dateTime()();

  /// Total valuation or outstanding debt balance on valuationDate in Paise
  IntColumn get valuationPaise => integer()();

  /// NAV or unit price in micro-paise, if applicable
  IntColumn get unitPriceMicroPaise => integer().nullable()();

  /// Provider: 'mfapi', 'tigzig', 'amfi', 'manual', 'imported'
  TextColumn get sourceProvider =>
      text().withDefault(const Constant('manual'))();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {financialItemId, valuationDate},
      ];
}
