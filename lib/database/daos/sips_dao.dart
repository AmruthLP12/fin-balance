import 'package:drift/drift.dart';
import '../../core/scheduling/recurring_date_calculator.dart';
import '../app_database.dart';
import '../precision/financial_precision.dart';
import '../tables/financial_items.dart';
import '../tables/mutual_fund_schemes.dart';
import '../tables/sip_installments.dart';
import '../tables/sip_plans.dart';
import '../tables/sip_schedule_periods.dart';
import '../tables/transactions.dart';

part 'sips_dao.g.dart';

@DriftAccessor(tables: [
  SipPlans,
  SipSchedulePeriods,
  SipInstallments,
  MutualFundSchemes,
  FinancialItems,
  Transactions,
])
class SipsDao extends DatabaseAccessor<AppDatabase> with _$SipsDaoMixin {
  SipsDao(super.db);

  /// Watch all active SIP plans for a profile.
  Stream<List<SipPlan>> watchSipsByProfile(int profileId) {
    return (select(sipPlans)
          ..where((tbl) => tbl.profileId.equals(profileId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Get SIP plan by ID.
  Future<SipPlan?> getSipById(int id) {
    return (select(sipPlans)..where((tbl) => tbl.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch single SIP plan by ID.
  Stream<SipPlan?> watchSipById(int id) {
    return (select(sipPlans)..where((tbl) => tbl.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Watch all schedule periods for a SIP plan ordered chronologically.
  Stream<List<SipSchedulePeriod>> watchSchedulePeriods(int sipPlanId) {
    return (select(sipSchedulePeriods)
          ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)]))
        .watch();
  }

  /// Get all schedule periods for a SIP plan.
  Future<List<SipSchedulePeriod>> getSchedulePeriods(int sipPlanId) {
    return (select(sipSchedulePeriods)
          ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)]))
        .get();
  }

  /// Watch all installments for a SIP plan.
  Stream<List<SipInstallment>> watchInstallments(int sipPlanId) {
    return (select(sipInstallments)
          ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .watch();
  }

  /// Get installments for a SIP plan.
  Future<List<SipInstallment>> getInstallments(int sipPlanId) {
    return (select(sipInstallments)
          ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)]))
        .get();
  }

  /// Get upcoming installments across all SIP plans for a profile.
  Future<List<SipInstallment>> getUpcomingInstallmentsForProfile(
    int profileId, {
    int limit = 15,
  }) {
    return (select(sipInstallments)
          ..where((tbl) =>
              tbl.profileId.equals(profileId) &
              tbl.status.equals('upcoming') &
              tbl.scheduledDate.isBiggerOrEqualValue(DateTime.now().toUtc()))
          ..orderBy([(t) => OrderingTerm.asc(t.scheduledDate)])
          ..limit(limit))
        .get();
  }

  /// Create a new SIP plan with its initial schedule period and auto-generate installments.
  Future<int> createSipWithPeriod({
    required int profileId,
    required int schemeCode,
    required String name,
    required DateTime startDate,
    DateTime? endDate,
    required int amountPaise,
    required int deductionDay,
    String frequency = 'monthly',
    String? notes,
    int? financialItemId,
    bool generateInstallments = true,
    bool isSimulated = true,
  }) async {
    return transaction(() async {
      // 1. Create Master SIP Plan
      final sipId = await into(sipPlans).insert(
        SipPlansCompanion(
          profileId: Value(profileId),
          schemeCode: Value(schemeCode),
          name: Value(name),
          startDate: Value(startDate),
          endDate: endDate != null ? Value(endDate) : const Value.absent(),
          financialItemId: financialItemId != null
              ? Value(financialItemId)
              : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 2. Create Initial Schedule Period
      final periodId = await into(sipSchedulePeriods).insert(
        SipSchedulePeriodsCompanion(
          sipPlanId: Value(sipId),
          effectiveFrom: Value(startDate),
          effectiveTo: endDate != null ? Value(endDate) : const Value.absent(),
          amountPaise: Value(amountPaise),
          deductionDay: Value(deductionDay),
          frequency: Value(frequency),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 3. Generate Installments if requested
      if (generateInstallments) {
        // If no end date, project 12 months ahead from startDate
        final targetEnd = endDate ??
            DateTime.utc(startDate.year + 1, startDate.month, startDate.day);

        final dates = RecurringDateCalculator.generateMonthlyOccurrences(
          fromDate: startDate,
          toDate: targetEnd,
          configuredDay: deductionDay,
        );

        for (final date in dates) {
          await into(sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: Value(sipId),
              schedulePeriodId: Value(periodId),
              profileId: Value(profileId),
              scheduledDate: Value(date),
              expectedAmountPaise: Value(amountPaise),
              status: const Value('upcoming'),
              isSimulated: Value(isSimulated),
            ),
            onConflict: DoNothing(
              target: [
                sipInstallments.sipPlanId,
                sipInstallments.scheduledDate
              ],
            ),
          );
        }
      }

      return sipId;
    });
  }

  /// Add a new schedule period when an amount or deduction date changes (e.g. ₹100 -> ₹500, or 3rd -> 5th).
  /// Closes the previous period, preserves past installments, and schedules future installments.
  Future<int> addSchedulePeriod({
    required int sipPlanId,
    required DateTime effectiveFrom,
    DateTime? effectiveTo,
    required int amountPaise,
    required int deductionDay,
    String frequency = 'monthly',
    String? notes,
    bool generateFutureInstallments = true,
  }) async {
    return transaction(() async {
      final sip = await getSipById(sipPlanId);
      if (sip == null) throw ArgumentError('SIP $sipPlanId does not exist.');

      // 1. Close preceding schedule period
      final existingPeriods = await (select(sipSchedulePeriods)
            ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)]))
          .get();

      if (existingPeriods.isNotEmpty) {
        final lastPeriod = existingPeriods.first;
        // End the previous period one day before the new effectiveFrom
        final closingDate = effectiveFrom.subtract(const Duration(days: 1));
        await (update(sipSchedulePeriods)
              ..where((tbl) => tbl.id.equals(lastPeriod.id)))
            .write(
          SipSchedulePeriodsCompanion(
            effectiveTo: Value(closingDate),
            status: const Value('superseded'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }

      // 2. Create the new schedule period
      final newPeriodId = await into(sipSchedulePeriods).insert(
        SipSchedulePeriodsCompanion(
          sipPlanId: Value(sipPlanId),
          effectiveFrom: Value(effectiveFrom),
          effectiveTo:
              effectiveTo != null ? Value(effectiveTo) : const Value.absent(),
          amountPaise: Value(amountPaise),
          deductionDay: Value(deductionDay),
          frequency: Value(frequency),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 3. Remove unconfirmed future installments on or after effectiveFrom to prevent overlaps
      await (delete(sipInstallments)
            ..where((tbl) =>
                tbl.sipPlanId.equals(sipPlanId) &
                tbl.scheduledDate.isBiggerOrEqualValue(effectiveFrom) &
                tbl.status.equals('upcoming') &
                tbl.isSimulated.equals(true)))
          .go();

      // 4. Generate new future installments
      if (generateFutureInstallments) {
        final targetEnd = effectiveTo ??
            DateTime.utc(
                effectiveFrom.year + 1, effectiveFrom.month, effectiveFrom.day);

        final dates = RecurringDateCalculator.generateMonthlyOccurrences(
          fromDate: effectiveFrom,
          toDate: targetEnd,
          configuredDay: deductionDay,
        );

        for (final date in dates) {
          await into(sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: Value(sipPlanId),
              schedulePeriodId: Value(newPeriodId),
              profileId: Value(sip.profileId),
              scheduledDate: Value(date),
              expectedAmountPaise: Value(amountPaise),
              status: const Value('upcoming'),
              isSimulated: const Value(true),
            ),
            onConflict: DoNothing(
              target: [
                sipInstallments.sipPlanId,
                sipInstallments.scheduledDate
              ],
            ),
          );
        }
      }

      return newPeriodId;
    });
  }

  /// Bulk historical SIP entry: records a continuous historical period (e.g. Jan 2024 to Apr 2024 at ₹100),
  /// generating all individual historical installments automatically.
  Future<int> recordBulkHistoricalSip({
    required int profileId,
    required int schemeCode,
    required String name,
    required DateTime fromDate,
    required DateTime toDate,
    required int amountPaise,
    required int deductionDay,
    required bool markAsConfirmed,
    int? purchaseNavMicroPaise,
    String? notes,
    int? financialItemId,
  }) async {
    return transaction(() async {
      // 1. Create Master SIP
      final sipId = await into(sipPlans).insert(
        SipPlansCompanion(
          profileId: Value(profileId),
          schemeCode: Value(schemeCode),
          name: Value(name),
          startDate: Value(fromDate),
          endDate: Value(toDate),
          financialItemId: financialItemId != null
              ? Value(financialItemId)
              : const Value.absent(),
          notes: notes != null ? Value(notes) : const Value.absent(),
          status: const Value('completed'),
        ),
      );

      // 2. Create Period
      final periodId = await into(sipSchedulePeriods).insert(
        SipSchedulePeriodsCompanion(
          sipPlanId: Value(sipId),
          effectiveFrom: Value(fromDate),
          effectiveTo: Value(toDate),
          amountPaise: Value(amountPaise),
          deductionDay: Value(deductionDay),
          status: const Value('completed'),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 3. Generate occurrences
      final dates = RecurringDateCalculator.generateMonthlyOccurrences(
        fromDate: fromDate,
        toDate: toDate,
        configuredDay: deductionDay,
      );

      for (final date in dates) {
        int? unitsMicro;
        if (purchaseNavMicroPaise != null && purchaseNavMicroPaise > 0) {
          unitsMicro = FinancialPrecision.calculateUnitsPurchased(
            amountPaise: amountPaise,
            navMicroPaise: purchaseNavMicroPaise,
          );
        }

        int? txId;
        if (markAsConfirmed) {
          // Find or default category
          final cat =
              await db.categoriesDao.getCategoriesByClassification('asset');
          final categoryId = cat.isNotEmpty ? cat.first.id : 1;

          txId = await into(transactions).insert(
            TransactionsCompanion(
              profileId: Value(profileId),
              transactionType: const Value('investment_purchase'),
              categoryId: Value(categoryId),
              financialItemId: financialItemId != null
                  ? Value(financialItemId)
                  : const Value.absent(),
              transactionDate: Value(date),
              amountPaise: Value(amountPaise),
              unitsMicroUnits:
                  unitsMicro != null ? Value(unitsMicro) : const Value.absent(),
              unitPriceMicroPaise: purchaseNavMicroPaise != null
                  ? Value(purchaseNavMicroPaise)
                  : const Value.absent(),
              source: const Value('simulated_sip'),
              notes: Value('Historical SIP installment for $name'),
            ),
          );
        }

        await into(sipInstallments).insert(
          SipInstallmentsCompanion(
            sipPlanId: Value(sipId),
            schedulePeriodId: Value(periodId),
            profileId: Value(profileId),
            scheduledDate: Value(date),
            expectedAmountPaise: Value(amountPaise),
            status: Value(markAsConfirmed ? 'recorded' : 'simulated'),
            isSimulated: Value(!markAsConfirmed),
            actualInvestmentDate:
                markAsConfirmed ? Value(date) : const Value.absent(),
            actualAmountPaise:
                markAsConfirmed ? Value(amountPaise) : const Value.absent(),
            purchaseNavMicroPaise: purchaseNavMicroPaise != null
                ? Value(purchaseNavMicroPaise)
                : const Value.absent(),
            unitsMicroUnits:
                unitsMicro != null ? Value(unitsMicro) : const Value.absent(),
            transactionId: txId != null ? Value(txId) : const Value.absent(),
          ),
          onConflict: DoNothing(
            target: [sipInstallments.sipPlanId, sipInstallments.scheduledDate],
          ),
        );
      }

      return sipId;
    });
  }

  /// Record an actual manual investment for a due installment.
  Future<bool> recordActualInstallment({
    required int installmentId,
    required DateTime actualDate,
    required int actualAmountPaise,
    int? purchaseNavMicroPaise,
    int? unitsMicroUnits,
    String? notes,
  }) async {
    return transaction(() async {
      final installment = await (select(sipInstallments)
            ..where((tbl) => tbl.id.equals(installmentId)))
          .getSingleOrNull();

      if (installment == null) return false;

      final sip = await getSipById(installment.sipPlanId);
      if (sip == null) return false;

      // Calculate units if purchaseNav provided and units not passed
      int? calculatedUnits = unitsMicroUnits;
      if (calculatedUnits == null &&
          purchaseNavMicroPaise != null &&
          purchaseNavMicroPaise > 0) {
        calculatedUnits = FinancialPrecision.calculateUnitsPurchased(
          amountPaise: actualAmountPaise,
          navMicroPaise: purchaseNavMicroPaise,
        );
      }

      // Record transaction
      final cat = await db.categoriesDao.getCategoriesByClassification('asset');
      final categoryId = cat.isNotEmpty ? cat.first.id : 1;

      final txId = await into(transactions).insert(
        TransactionsCompanion(
          profileId: Value(installment.profileId),
          transactionType: const Value('investment_purchase'),
          categoryId: Value(categoryId),
          financialItemId: sip.financialItemId != null
              ? Value(sip.financialItemId!)
              : const Value.absent(),
          transactionDate: Value(actualDate),
          amountPaise: Value(actualAmountPaise),
          unitsMicroUnits: calculatedUnits != null
              ? Value(calculatedUnits)
              : const Value.absent(),
          unitPriceMicroPaise: purchaseNavMicroPaise != null
              ? Value(purchaseNavMicroPaise)
              : const Value.absent(),
          source: const Value('manual'),
          notes: Value(notes ?? 'SIP installment for ${sip.name}'),
        ),
      );

      // Update installment
      await (update(sipInstallments)
            ..where((tbl) => tbl.id.equals(installmentId)))
          .write(
        SipInstallmentsCompanion(
          status: const Value('recorded'),
          isSimulated: const Value(false),
          actualInvestmentDate: Value(actualDate),
          actualAmountPaise: Value(actualAmountPaise),
          purchaseNavMicroPaise: purchaseNavMicroPaise != null
              ? Value(purchaseNavMicroPaise)
              : const Value.absent(),
          unitsMicroUnits: calculatedUnits != null
              ? Value(calculatedUnits)
              : const Value.absent(),
          transactionId: Value(txId),
          notes: notes != null ? Value(notes) : const Value.absent(),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      // Update financial holding if linked
      if (sip.financialItemId != null) {
        final holding =
            await db.financialItemsDao.getItemById(sip.financialItemId!);
        if (holding != null) {
          final newInvested = holding.initialValuePaise + actualAmountPaise;
          final newUnits = holding.unitCountMicroUnits + (calculatedUnits ?? 0);

          // Get latest NAV
          final scheme = await db.mutualFundDao.getSchemeByCode(sip.schemeCode);
          final latestNav =
              scheme?.latestNavMicroPaise ?? purchaseNavMicroPaise ?? 100000000;
          final newValuation = FinancialPrecision.calculateValuationPaise(
            unitCountMicroUnits: newUnits,
            navMicroPaise: latestNav,
          );

          await db.financialItemsDao.updateItem(
            holding.copyWith(
              initialValuePaise: newInvested,
              unitCountMicroUnits: newUnits,
              currentValuationPaise: newValuation,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        }
      }

      return true;
    });
  }

  /// Mark an installment as skipped.
  Future<int> skipInstallment(int installmentId) {
    return (update(sipInstallments)
          ..where((tbl) => tbl.id.equals(installmentId)))
        .write(
      SipInstallmentsCompanion(
        status: const Value('skipped'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Mark an installment as cancelled.
  Future<int> cancelInstallment(int installmentId) {
    return (update(sipInstallments)
          ..where((tbl) => tbl.id.equals(installmentId)))
        .write(
      SipInstallmentsCompanion(
        status: const Value('cancelled'),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }
}
