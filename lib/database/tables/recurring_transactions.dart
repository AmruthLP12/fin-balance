import 'package:drift/drift.dart';

/// Table representing recurring schedules for SIP contributions, loan EMIs,
/// recurring salary, subscriptions, and rent scoped to a profile.
@TableIndex(name: 'idx_recurring_profile', columns: {#profileId})
@TableIndex(name: 'idx_recurring_status', columns: {#status})
@TableIndex(name: 'idx_recurring_item', columns: {#financialItemId})
class RecurringTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Profile scoping: Every recurring schedule belongs to an individual profile
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  TextColumn get name => text().withLength(min: 1, max: 150)();

  /// Recurring type: 'sip_investment', 'loan_emi', 'recurring_income', 'recurring_expense'
  TextColumn get recurringType => text()();

  IntColumn get financialItemId => integer()
      .nullable()
      .customConstraint('REFERENCES financial_items(id) ON DELETE SET NULL')();

  @ReferenceName('outgoingRecurring')
  IntColumn get fromAccountId => integer().nullable().customConstraint(
      'REFERENCES financial_accounts(id) ON DELETE SET NULL')();

  @ReferenceName('incomingRecurring')
  IntColumn get toAccountId => integer().nullable().customConstraint(
      'REFERENCES financial_accounts(id) ON DELETE SET NULL')();

  IntColumn get categoryId => integer().customConstraint(
      'NOT NULL REFERENCES financial_categories(id) ON DELETE RESTRICT')();

  /// Scheduled cash amount in Paise
  IntColumn get amountPaise => integer()();

  /// Frequency: 'weekly', 'monthly', 'quarterly', 'yearly'
  TextColumn get frequency => text()();

  /// Scheduled day: 1-31 for monthly/quarterly, 1-7 for weekly
  IntColumn get scheduledDay => integer()();

  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Status: 'active', 'paused', 'completed', 'cancelled'
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
