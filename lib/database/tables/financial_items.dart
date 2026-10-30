import 'package:drift/drift.dart';

/// Table representing trackable financial items scoped to a profile:
/// - Assets (+): Mutual funds, stocks, ETFs, fixed deposits, gold, PPF, EPF, NPS, bonds.
/// - Liabilities (-): Home loans, vehicle loans, education loans, personal loans, credit card debt.
@TableIndex(name: 'idx_item_profile', columns: {#profileId})
@TableIndex(name: 'idx_item_profile_type', columns: {#profileId, #itemType})
@TableIndex(name: 'idx_item_type_status', columns: {#itemType, #status})
@TableIndex(name: 'idx_item_external_code', columns: {#externalCode})
class FinancialItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every financial asset or liability belongs to a profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Primary type: 'asset' or 'liability'
  TextColumn get itemType => text()();

  /// Specific sub-type:
  /// Assets: 'mutual_fund', 'stock', 'fixed_deposit', 'gold', 'ppf', 'epf', 'nps', 'bond', 'cash', 'other_asset'
  /// Liabilities: 'home_loan', 'personal_loan', 'vehicle_loan', 'education_loan', 'credit_card', 'other_liability'
  TextColumn get subType => text()();

  IntColumn get categoryId => integer().customConstraint(
      'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT')();
  IntColumn get accountId => integer().nullable().customConstraint(
      'REFERENCES financial_accounts(id) ON DELETE SET NULL')();

  /// External scheme or account code (e.g. AMFI Scheme Code for mutual funds, ISIN, Loan No.)
  TextColumn get externalCode => text().nullable()();

  /// Status: 'active', 'inactive', 'archived', 'closed'
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Initial or principal value in Paise
  IntColumn get initialValuePaise => integer().withDefault(const Constant(0))();

  /// Latest valuation or outstanding debt balance in Paise
  IntColumn get currentValuationPaise =>
      integer().withDefault(const Constant(0))();

  /// Total units held for unitized investments (1 unit = 1,000,000 micro-units, 0 if not unitized)
  IntColumn get unitCountMicroUnits =>
      integer().withDefault(const Constant(0))();

  /// Annual interest rate in basis points (e.g. 850 = 8.50% p.a., 710 = 7.10% for PPF)
  IntColumn get interestRateBasisPoints => integer().nullable()();

  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get maturityDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
