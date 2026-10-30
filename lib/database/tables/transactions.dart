import 'package:drift/drift.dart';

import 'financial_profiles.dart';

/// Table representing all financial transactions and cash flows:
/// income, expense, transfer, investment purchase/redemption, debt repayment, and adjustment.
/// Every transaction is strictly scoped to a profile.
@TableIndex(name: 'idx_transaction_profile', columns: {#profileId})
@TableIndex(name: 'idx_transaction_profile_date', columns: {#profileId, #transactionDate})
@TableIndex(name: 'idx_transaction_date', columns: {#transactionDate})
@TableIndex(name: 'idx_transaction_item', columns: {#financialItemId})
@TableIndex(name: 'idx_transaction_type', columns: {#transactionType})
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every transaction belongs to an individual profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Transaction type:
  /// 'income', 'expense', 'transfer', 'investment_purchase', 'investment_redemption', 'debt_repayment', 'adjustment'
  TextColumn get transactionType => text()();

  IntColumn get categoryId => integer().customConstraint(
      'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT')();
  IntColumn get financialItemId => integer()
      .nullable()
      .customConstraint('REFERENCES financial_items(id) ON DELETE SET NULL')();

  @ReferenceName('outgoingTransactions')
  IntColumn get fromAccountId => integer().nullable().customConstraint(
      'REFERENCES financial_accounts(id) ON DELETE SET NULL')();

  @ReferenceName('incomingTransactions')
  IntColumn get toAccountId => integer().nullable().customConstraint(
      'REFERENCES financial_accounts(id) ON DELETE SET NULL')();

  DateTimeColumn get transactionDate => dateTime()();

  /// Cash transaction value in Paise (e.g., ₹5,000.00 = 500,000 paise)
  IntColumn get amountPaise => integer()();

  /// Units transacted for investments (in micro-units: 1.0 unit = 1,000,000 micro-units)
  IntColumn get unitsMicroUnits => integer().nullable()();

  /// NAV or unit price in micro-paise (1 Rupee = 100 paise = 1,000,000 micro-paise)
  IntColumn get unitPriceMicroPaise => integer().nullable()();

  /// Source identifier: 'manual', 'simulated_sip', 'loan_schedule', 'imported', 'correction'
  TextColumn get source => text().withDefault(const Constant('manual'))();

  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
