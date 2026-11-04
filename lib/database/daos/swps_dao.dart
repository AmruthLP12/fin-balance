import 'package:drift/drift.dart';
import '../../core/scheduling/investment_schedule_service.dart';
import '../app_database.dart';
import '../tables/swp_installments.dart';
import '../tables/swp_plans.dart';
import '../tables/swp_schedule_periods.dart';

part 'swps_dao.g.dart';

/// Data Access Object for SWP plans, schedule periods, and installments.
@DriftAccessor(tables: [SwpPlans, SwpSchedulePeriods, SwpInstallments])
class SwpsDao extends DatabaseAccessor<AppDatabase> with _$SwpsDaoMixin {
  SwpsDao(super.db);

  /// Get SWP plan by ID.
  Future<SwpPlan?> getSwpById(int id) {
    return (select(swpPlans)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch single SWP plan by ID.
  Stream<SwpPlan?> watchSwpById(int id) {
    return (select(swpPlans)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Watch SWP plans for a financial holding.
  Stream<List<SwpPlan>> watchSwpsByHolding(int financialItemId) {
    return (select(swpPlans)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  /// Get SWP plans for a financial holding.
  Future<List<SwpPlan>> getSwpsByHolding(int financialItemId) {
    return (select(swpPlans)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
  }

  /// Watch SWP plans for a profile.
  Stream<List<SwpPlan>> watchSwpsForProfile(int profileId) {
    return (select(swpPlans)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  /// Watch all schedule periods for an SWP plan ordered chronologically.
  Stream<List<SwpSchedulePeriod>> watchSchedulePeriods(int swpPlanId) {
    return (select(swpSchedulePeriods)
          ..where((tbl) => tbl.swpPlanId.equals(swpPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)]))
        .watch();
  }

  /// Get all schedule periods for an SWP plan.
  Future<List<SwpSchedulePeriod>> getSchedulePeriods(int swpPlanId) {
    return (select(swpSchedulePeriods)
          ..where((tbl) => tbl.swpPlanId.equals(swpPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)]))
        .get();
  }

  /// Watch all installments for an SWP plan.
  Stream<List<SwpInstallment>> watchInstallments(int swpPlanId) {
    return (select(swpInstallments)
          ..where((tbl) => tbl.swpPlanId.equals(swpPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  /// Get all installments for an SWP plan.
  Future<List<SwpInstallment>> getInstallments(int swpPlanId) {
    return (select(swpInstallments)
          ..where((tbl) => tbl.swpPlanId.equals(swpPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  /// Create an SWP plan with initial schedule period and generate planned withdrawals.
  Future<int> createSwpWithPeriod({
    required int profileId,
    required int schemeCode,
    required String name,
    required String withdrawalMode, // 'amount' or 'units'
    required DateTime startDate,
    DateTime? endDate,
    int? amountPaise,
    int? unitsMicroUnits,
    required int deductionDay,
    String frequency = 'monthly',
    int? installmentCount,
    String? notes,
    int? financialItemId,
    bool generateInstallments = true,
  }) async {
    return transaction(() async {
      // 1. Create Master SWP Plan
      final swpId = await into(swpPlans).insert(
        SwpPlansCompanion(
          profileId: Value(profileId),
          schemeCode: Value(schemeCode),
          name: Value(name),
          withdrawalMode: Value(withdrawalMode),
          startDate: Value(startDate),
          endDate: endDate != null ? Value(endDate) : const Value.absent(),
          financialItemId: financialItemId != null
              ? Value(financialItemId)
              : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 2. Create Initial Schedule Period
      final periodId = await into(swpSchedulePeriods).insert(
        SwpSchedulePeriodsCompanion(
          swpPlanId: Value(swpId),
          effectiveFrom: Value(startDate),
          effectiveTo: endDate != null ? Value(endDate) : const Value.absent(),
          withdrawalMode: Value(withdrawalMode),
          amountPaise:
              amountPaise != null ? Value(amountPaise) : const Value.absent(),
          unitsMicroUnits: unitsMicroUnits != null
              ? Value(unitsMicroUnits)
              : const Value.absent(),
          deductionDay: Value(deductionDay),
          frequency: Value(frequency),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 3. Generate planned withdrawals using shared frequency utility
      if (generateInstallments) {
        final freq = ScheduleFrequency.fromString(frequency);
        final dates = InvestmentScheduleService.generateScheduleDatesRange(
          startDate: startDate,
          endDate: endDate,
          installmentCount: installmentCount,
          frequency: freq,
        );

        for (final date in dates) {
          await into(swpInstallments).insert(
            SwpInstallmentsCompanion(
              swpPlanId: Value(swpId),
              schedulePeriodId: Value(periodId),
              profileId: Value(profileId),
              scheduledDate: Value(date),
              expectedAmountPaise: amountPaise != null
                  ? Value(amountPaise)
                  : const Value.absent(),
              expectedUnitsMicroUnits: unitsMicroUnits != null
                  ? Value(unitsMicroUnits)
                  : const Value.absent(),
              status: const Value('upcoming'),
              isSimulated: const Value(true),
            ),
            onConflict: DoNothing(
              target: [
                swpInstallments.swpPlanId,
                swpInstallments.scheduledDate,
              ],
            ),
          );
        }
      }

      return swpId;
    });
  }

  /// Add a new schedule period for an existing SWP plan, superseding the previous period.
  Future<int> addSchedulePeriod({
    required int swpPlanId,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    required String withdrawalMode,
    int? amountPaise,
    int? unitsMicroUnits,
    required int deductionDay,
    String frequency = 'monthly',
    int? installmentCount,
    String? notes,
    bool generateFutureInstallments = true,
  }) async {
    return transaction(() async {
      final swp = await getSwpById(swpPlanId);
      if (swp == null) throw ArgumentError('SWP $swpPlanId does not exist.');

      // 1. Close preceding period
      final existingPeriods = await (select(swpSchedulePeriods)
            ..where((tbl) => tbl.swpPlanId.equals(swpPlanId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)]))
          .get();

      if (existingPeriods.isNotEmpty) {
        final lastPeriod = existingPeriods.first;
        final closingDate = effectiveFrom.subtract(const Duration(days: 1));
        await (update(swpSchedulePeriods)
              ..where((tbl) => tbl.id.equals(lastPeriod.id)))
            .write(
          SwpSchedulePeriodsCompanion(
            effectiveTo: Value(closingDate),
            status: const Value('superseded'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }

      // 2. Create the new schedule period
      final newPeriodId = await into(swpSchedulePeriods).insert(
        SwpSchedulePeriodsCompanion(
          swpPlanId: Value(swpPlanId),
          effectiveFrom: Value(effectiveFrom),
          effectiveTo:
              effectiveTo != null ? Value(effectiveTo) : const Value.absent(),
          withdrawalMode: Value(withdrawalMode),
          amountPaise:
              amountPaise != null ? Value(amountPaise) : const Value.absent(),
          unitsMicroUnits: unitsMicroUnits != null
              ? Value(unitsMicroUnits)
              : const Value.absent(),
          deductionDay: Value(deductionDay),
          frequency: Value(frequency),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 3. Remove unconfirmed future installments on or after effectiveFrom to prevent overlaps
      await (delete(swpInstallments)
            ..where((tbl) =>
                tbl.swpPlanId.equals(swpPlanId) &
                tbl.scheduledDate.isBiggerOrEqualValue(effectiveFrom) &
                tbl.status.equals('upcoming') &
                tbl.isSimulated.equals(true)))
          .go();

      // 4. Generate future planned installments
      if (generateFutureInstallments) {
        final freq = ScheduleFrequency.fromString(frequency);
        final dates = InvestmentScheduleService.generateScheduleDatesRange(
          startDate: effectiveFrom,
          endDate: effectiveTo,
          installmentCount: installmentCount,
          frequency: freq,
        );

        for (final date in dates) {
          await into(swpInstallments).insert(
            SwpInstallmentsCompanion(
              swpPlanId: Value(swpPlanId),
              schedulePeriodId: Value(newPeriodId),
              profileId: Value(swp.profileId),
              scheduledDate: Value(date),
              expectedAmountPaise: amountPaise != null
                  ? Value(amountPaise)
                  : const Value.absent(),
              expectedUnitsMicroUnits: unitsMicroUnits != null
                  ? Value(unitsMicroUnits)
                  : const Value.absent(),
              status: const Value('upcoming'),
              isSimulated: const Value(true),
            ),
            onConflict: DoNothing(
              target: [
                swpInstallments.swpPlanId,
                swpInstallments.scheduledDate,
              ],
            ),
          );
        }
      }

      return newPeriodId;
    });
  }

  /// Close an SWP period, marking it closed and cancelling future planned withdrawals.
  Future<void> closeSchedulePeriod({
    required int swpPlanId,
    DateTime? closeDate,
  }) async {
    return transaction(() async {
      final now = closeDate ?? DateTime.now().toUtc();
      final periods = await (select(swpSchedulePeriods)
            ..where((tbl) =>
                tbl.swpPlanId.equals(swpPlanId) & tbl.status.equals('active')))
          .get();

      for (final period in periods) {
        await (update(swpSchedulePeriods)
              ..where((tbl) => tbl.id.equals(period.id)))
            .write(
          SwpSchedulePeriodsCompanion(
            effectiveTo: Value(now),
            status: const Value('closed'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }

      await (update(swpPlans)..where((tbl) => tbl.id.equals(swpPlanId))).write(
        SwpPlansCompanion(
          status: const Value('stopped'),
          endDate: Value(now),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      // Cancel future simulated installments
      await (update(swpInstallments)
            ..where((tbl) =>
                tbl.swpPlanId.equals(swpPlanId) &
                tbl.scheduledDate.isBiggerOrEqualValue(now) &
                tbl.status.equals('upcoming') &
                tbl.isSimulated.equals(true)))
          .write(
        const SwpInstallmentsCompanion(
          status: Value('cancelled'),
        ),
      );
    });
  }

  /// Marks the planned installment closest to [transactionDate] as recorded by an
  /// already-saved withdrawal transaction. Only `upcoming` installments within
  /// [tolerance] are considered; the holding is not touched (the transaction DAO has
  /// already applied units and amount). Returns false when nothing matched.
  Future<bool> linkTransactionToInstallment({
    required int swpPlanId,
    required int transactionId,
    required DateTime transactionDate,
    required int amountPaise,
    int? navMicroPaise,
    int? unitsMicroUnits,
    Duration tolerance = const Duration(days: 31),
  }) async {
    final candidates = await (select(swpInstallments)
          ..where((tbl) =>
              tbl.swpPlanId.equals(swpPlanId) & tbl.status.equals('upcoming')))
        .get();

    SwpInstallment? best;
    var bestGap = tolerance + const Duration(days: 1);
    for (final c in candidates) {
      final gap = c.scheduledDate.difference(transactionDate).abs();
      if (gap <= tolerance && gap < bestGap) {
        best = c;
        bestGap = gap;
      }
    }
    if (best == null) return false;

    await (update(swpInstallments)..where((tbl) => tbl.id.equals(best!.id)))
        .write(
      SwpInstallmentsCompanion(
        status: const Value('recorded'),
        isSimulated: const Value(false),
        actualWithdrawalDate: Value(transactionDate),
        actualAmountPaise: Value(amountPaise),
        withdrawalNavMicroPaise: Value(navMicroPaise),
        unitsMicroUnits: Value(unitsMicroUnits),
        transactionId: Value(transactionId),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return true;
  }

  /// Delete an SWP plan. Foreign keys cascade to its periods and installments and
  /// null `swpPlanId` on any transactions, which are kept.
  Future<void> deleteSwpCascade(int swpPlanId) async {
    await (delete(swpPlans)..where((tbl) => tbl.id.equals(swpPlanId))).go();
  }
}
