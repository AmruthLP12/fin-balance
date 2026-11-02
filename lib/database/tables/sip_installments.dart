import 'package:drift/drift.dart';

/// Table representing individual SIP occurrences/installments.
/// Strictly separates scheduled installments from financial transactions,
/// preserves historical occurrences, prevents duplicates, and tracks simulated vs confirmed status.
@TableIndex(name: 'idx_installment_sip', columns: {#sipPlanId})
@TableIndex(name: 'idx_installment_profile', columns: {#profileId})
@TableIndex(name: 'idx_installment_status', columns: {#status})
@TableIndex(name: 'idx_installment_date', columns: {#scheduledDate})
class SipInstallments extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Parent SIP plan reference
  IntColumn get sipPlanId => integer().customConstraint(
      'NOT NULL REFERENCES sip_plans(id) ON DELETE CASCADE')();

  /// The specific schedule period under which this installment was generated
  IntColumn get schedulePeriodId => integer().customConstraint(
      'NOT NULL REFERENCES sip_schedule_periods(id) ON DELETE CASCADE')();

  /// Profile scoping
  IntColumn get profileId => integer().customConstraint(
      'NOT NULL REFERENCES financial_profiles(id) ON DELETE CASCADE')();

  /// Scheduled investment date
  DateTimeColumn get scheduledDate => dateTime()();

  /// Expected scheduled amount in Paise
  IntColumn get expectedAmountPaise => integer()();

  /// Status: 'upcoming', 'recorded', 'skipped', 'cancelled', 'pending_valuation'
  TextColumn get status => text().withDefault(const Constant('upcoming'))();

  /// Distinguishes automatically generated/simulated installments from confirmed user investments
  BoolColumn get isSimulated => boolean().withDefault(const Constant(true))();

  /// Actual investment date confirmed by the user (may differ from scheduledDate)
  DateTimeColumn get actualInvestmentDate => dateTime().nullable()();

  /// Actual amount invested in Paise (may differ from expectedAmountPaise)
  IntColumn get actualAmountPaise => integer().nullable()();

  /// Actual purchase NAV in micro-paise
  IntColumn get purchaseNavMicroPaise => integer().nullable()();

  /// Units allotted in micro-units (1.0 unit = 1,000,000 micro-units)
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
        {sipPlanId, scheduledDate},
      ];
}
