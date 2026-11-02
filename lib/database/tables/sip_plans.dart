import 'package:drift/drift.dart';

/// Table representing master SIP investment plans scoped to a profile.
/// A SIP plan remains a single entity across its entire lifetime while
/// supporting multiple schedule periods with different amounts and deduction dates.
@TableIndex(name: 'idx_sip_profile', columns: {#profileId})
@TableIndex(name: 'idx_sip_status', columns: {#status})
@TableIndex(name: 'idx_sip_scheme', columns: {#schemeCode})
class SipPlans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every SIP belongs to a specific financial profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Optional link to existing FinancialItems asset holding
  IntColumn get financialItemId => integer()
      .nullable()
      .customConstraint('REFERENCES financial_items(id) ON DELETE SET NULL')();

  /// Mutual fund scheme code
  IntColumn get schemeCode => integer().customConstraint(
      'NOT NULL REFERENCES mutual_fund_schemes(scheme_code) ON DELETE RESTRICT')();

  /// User-defined display name for this SIP (e.g., 'Parag Parikh Monthly SIP')
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Master start date when SIP was first initiated
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
