import 'package:drift/drift.dart';

/// Global master table caching mutual fund schemes and latest NAV values.
///
/// Scheme reference records are global across the application,
/// while user portfolio holdings are profile-specific in [FinancialItems].
@TableIndex(name: 'idx_scheme_name', columns: {#schemeName})
@TableIndex(name: 'idx_scheme_fund_house', columns: {#fundHouse})
@TableIndex(name: 'idx_scheme_favorite', columns: {#isFavorite})
class MutualFundSchemes extends Table {
  /// AMFI unique scheme code (primary key)
  IntColumn get schemeCode => integer()();

  /// Full scheme display name
  TextColumn get schemeName => text().withLength(min: 1, max: 300)();

  /// Asset Management Company / Fund House (e.g. "HDFC Mutual Fund", "SBI Mutual Fund")
  TextColumn get fundHouse => text().nullable()();

  /// Scheme Type (e.g. "Open Ended Schemes", "Close Ended")
  TextColumn get schemeType => text().nullable()();

  /// Scheme Category (e.g. "Equity Scheme - Small Cap Fund", "Debt Scheme - Liquid Fund")
  TextColumn get schemeCategory => text().nullable()();

  /// Plan Type: 'Direct' or 'Regular'
  TextColumn get planType => text().nullable()();

  /// Option Type: 'Growth' or 'IDCW' (Dividend)
  TextColumn get optionType => text().nullable()();

  /// International Securities Identification Number (ISIN)
  TextColumn get isin => text().nullable()();

  /// Latest known NAV in micro-paise (1 Rupee = 1,000,000 micro-paise)
  IntColumn get latestNavMicroPaise => integer().nullable()();

  /// Date of the latest NAV record
  DateTimeColumn get latestNavDate => dateTime().nullable()();

  /// Whether user bookmarked this fund in their favourites/watchlist
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  /// Timestamp of the last successful synchronization from remote provider
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {schemeCode};
}
