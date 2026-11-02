import 'package:drift/drift.dart';

/// Table representing distinct schedule periods for a SIP plan.
/// Allows a SIP to change amount (e.g. ₹100 -> ₹500 -> ₹200) or deduction date (3rd -> 5th -> 7th)
/// over time without fragmenting into separate SIPs or modifying past installments.
@TableIndex(name: 'idx_period_sip', columns: {#sipPlanId})
@TableIndex(name: 'idx_period_dates', columns: {#effectiveFrom, #effectiveTo})
class SipSchedulePeriods extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Parent SIP plan reference
  IntColumn get sipPlanId => integer().customConstraint(
      'NOT NULL REFERENCES sip_plans(id) ON DELETE CASCADE')();

  /// Effective starting date for this period's configuration
  DateTimeColumn get effectiveFrom => dateTime()();

  /// Optional ending date when this period was superseded or completed (null if currently active)
  DateTimeColumn get effectiveTo => dateTime().nullable()();

  /// Scheduled investment amount in Paise (e.g. ₹500.00 = 50,000 paise)
  IntColumn get amountPaise => integer()();

  /// Deduction day of the month (1-31). Handled with month-end clamping (e.g. 31st clamps to 28th/29th Feb)
  IntColumn get deductionDay => integer()();

  /// Investment frequency: 'monthly', 'quarterly'
  TextColumn get frequency => text().withDefault(const Constant('monthly'))();

  /// Status: 'active', 'superseded', 'completed'
  TextColumn get status => text().withDefault(const Constant('active'))();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
