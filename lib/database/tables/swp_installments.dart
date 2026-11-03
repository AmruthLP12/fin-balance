import 'package:drift/drift.dart';

/// Table representing individual SWP occurrences/installments.
/// Strictly separates scheduled withdrawal projections from actual financial transactions,
/// preserving historical occurrences and keeping units held untouched until actual confirmation.
@TableIndex(name: 'idx_swp_inst_plan', columns: {#swpPlanId})
@TableIndex(name: 'idx_swp_inst_profile', columns: {#profileId})
@TableIndex(name: 'idx_swp_inst_status', columns: {#status})
@TableIndex(name: 'idx_swp_inst_date', columns: {#scheduledDate})
class SwpInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Parent SWP plan reference
  IntColumn get swpPlanId => integer().customConstraint(
      'NOT NULL REFERENCES swp_plans(id) ON DELETE CASCADE')();

  /// The specific schedule period under which this installment was generated
  IntColumn get schedulePeriodId => integer().customConstraint(
      'NOT NULL REFERENCES swp_schedule_periods(id) ON DELETE CASCADE')();

  /// Profile scoping
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Scheduled withdrawal date
  DateTimeColumn get scheduledDate => dateTime()();

  /// Expected withdrawal amount in Paise (null if units mode)
  IntColumn get expectedAmountPaise => integer().nullable()();

  /// Expected withdrawal units in micro-units (null if amount mode)
  IntColumn get expectedUnitsMicroUnits => integer().nullable()();

  /// Status: 'upcoming', 'recorded', 'skipped', 'cancelled'
  TextColumn get status => text().withDefault(const Constant('upcoming'))();

  /// Distinguishes forward projections from confirmed actual withdrawals
  BoolColumn get isSimulated => boolean().withDefault(const Constant(true))();

  /// Actual withdrawal date confirmed by user
  DateTimeColumn get actualWithdrawalDate => dateTime().nullable()();

  /// Actual amount paid out in Paise
  IntColumn get actualAmountPaise => integer().nullable()();

  /// Withdrawal NAV in micro-paise
  IntColumn get withdrawalNavMicroPaise => integer().nullable()();

  /// Units redeemed in micro-units
  IntColumn get unitsMicroUnits => integer().nullable()();

  /// Link to financial transaction record once confirmed
  IntColumn get transactionId => integer()
      .nullable()
      .customConstraint('REFERENCES transactions(id) ON DELETE SET NULL')();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {swpPlanId, scheduledDate},
      ];
}

