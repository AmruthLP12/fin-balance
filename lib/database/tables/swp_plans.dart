import 'package:drift/drift.dart';

/// Table representing master SWP (Systematic Withdrawal Plan) schedules scoped to a profile.
/// Supports both fixed amount and fixed units withdrawal modes across multiple schedule periods.
@TableIndex(name: 'idx_swp_profile', columns: {#profileId})
@TableIndex(name: 'idx_swp_status', columns: {#status})
@TableIndex(name: 'idx_swp_scheme', columns: {#schemeCode})
class SwpPlans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every SWP belongs to a specific financial profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Optional link to existing FinancialItems asset holding
  IntColumn get financialItemId => integer()
      .nullable()
      .customConstraint('REFERENCES financial_items(id) ON DELETE SET NULL')();

  /// Mutual fund scheme code
  IntColumn get schemeCode => integer().customConstraint(
      'NOT NULL REFERENCES mutual_fund_schemes(scheme_code) ON DELETE RESTRICT')();

  /// User-defined display name for this SWP (e.g., 'HDFC Top 100 Monthly SWP')
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Withdrawal mode: 'amount' (fixed cash) or 'units' (fixed units)
  TextColumn get withdrawalMode =>
      text().withDefault(const Constant('amount'))();

  /// Master start date when SWP was first initiated
  DateTimeColumn get startDate => dateTime()();

  /// Optional planned conclusion date (null if ongoing indefinitely)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Status: 'active', 'paused', 'stopped', 'completed'
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// General description or notes
  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

