import 'package:drift/drift.dart';

/// Historical NAV time-series for mutual fund schemes.
///
/// Stores immutable date-wise NAV values fetched from MFapi, TIGZIG, or AMFI.
@TableIndex(name: 'idx_nav_scheme_date', columns: {#schemeCode, #navDate})
class NavHistory extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get schemeCode => integer().customConstraint(
      'NOT NULL REFERENCES mutual_fund_schemes(scheme_code) ON DELETE CASCADE')();

  /// Normalized date of NAV valuation (UTC midnight)
  DateTimeColumn get navDate => dateTime()();

  /// NAV in micro-paise (1 Rupee = 1,000,000 micro-paise, 4-6 decimal places)
  IntColumn get navMicroPaise => integer()();

  /// Data source: 'mfapi', 'tigzig', 'amfi', 'manual'
  TextColumn get sourceProvider =>
      text().withDefault(const Constant('mfapi'))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {schemeCode, navDate},
      ];
}
