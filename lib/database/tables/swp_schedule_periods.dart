import 'package:drift/drift.dart';

/// Table representing distinct schedule periods for an SWP plan.
/// Allows revising withdrawal amount or units over time without modifying past withdrawals.
@TableIndex(name: 'idx_swp_period_plan', columns: {#swpPlanId})
@TableIndex(
    name: 'idx_swp_period_dates', columns: {#effectiveFrom, #effectiveTo})
class SwpSchedulePeriods extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Parent SWP plan reference
  IntColumn get swpPlanId => integer().customConstraint(
      'NOT NULL REFERENCES swp_plans(id) ON DELETE CASCADE')();

  /// Effective starting date for this period's configuration
  DateTimeColumn get effectiveFrom => dateTime()();

  /// Optional ending date when this period was superseded or completed (null if currently active)
  DateTimeColumn get effectiveTo => dateTime().nullable()();

  /// Withdrawal mode: 'amount' or 'units'
  TextColumn get withdrawalMode =>
      text().withDefault(const Constant('amount'))();

  /// Scheduled withdrawal amount in Paise (e.g. ₹5,000.00 = 500,000 paise), null if units mode
  IntColumn get amountPaise => integer().nullable()();

  /// Scheduled withdrawal units in micro-units (e.g. 10.5 units = 10,500,000 micro-units), null if amount mode
  IntColumn get unitsMicroUnits => integer().nullable()();

  /// Deduction day of the month (1-31)
  IntColumn get deductionDay => integer()();

  /// Frequency: 'one_time', 'daily', 'weekly', 'fortnightly', 'monthly', 'quarterly', 'half_yearly', 'yearly'
  TextColumn get frequency => text().withDefault(const Constant('monthly'))();

  /// Status: 'active', 'superseded', 'closed', 'completed'
  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
