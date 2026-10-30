import 'package:drift/drift.dart';

/// Table representing financial accounts such as bank accounts, cash wallets,
/// demat accounts, and credit lines scoped to a specific financial profile.
@TableIndex(name: 'idx_account_type', columns: {#accountType})
@TableIndex(name: 'idx_account_profile', columns: {#profileId})
class FinancialAccounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every account belongs to an individual profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Account type: 'bank', 'cash', 'demat', 'wallet', 'loan_account', 'credit_card'
  TextColumn get accountType => text()();

  TextColumn get accountNumberMasked => text().nullable()();
  TextColumn get institutionName => text().nullable()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();

  /// Opening balance in integer minor units (paise)
  IntColumn get openingBalancePaise =>
      integer().withDefault(const Constant(0))();

  /// Cached current balance in integer minor units (paise)
  IntColumn get currentBalancePaise =>
      integer().withDefault(const Constant(0))();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
