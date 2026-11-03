import 'package:drift/drift.dart';
import '../../core/scheduling/investment_schedule_service.dart';
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

  /// Watch SIP plans linked to a specific holding/financial item.
  Stream<List<SipPlan>> watchSipsByFinancialItem(int financialItemId) {
    return (select(sipPlans)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .watch();
  }

  /// Get SIP plans linked to a specific holding/financial item.
  Future<List<SipPlan>> getSipsByFinancialItem(int financialItemId) {
    return (select(sipPlans)
          ..where((tbl) => tbl.financialItemId.equals(financialItemId))
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
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

  /// Atomically delete an individual installment, removing its linked transaction and updating the holding.
  Future<bool> deleteInstallment(int installmentId) async {
    return transaction(() async {
      final inst = await (select(sipInstallments)
            ..where((tbl) => tbl.id.equals(installmentId)))
          .getSingleOrNull();
      if (inst == null) return false;

      // 1. Remove linked transaction if present
      if (inst.transactionId != null) {
        await (delete(transactions)
              ..where((tbl) => tbl.id.equals(inst.transactionId!)))
            .go();
      }

      // 2. Adjust holding if units or amount were contributed
      final unitsToRemove = inst.unitsMicroUnits ?? 0;
      final amountToRemove = inst.actualAmountPaise ?? 0;
      if (unitsToRemove > 0 || amountToRemove > 0) {
        final sip = await getSipById(inst.sipPlanId);
        if (sip != null && sip.financialItemId != null) {
          final holding = await (select(financialItems)
                ..where((tbl) => tbl.id.equals(sip.financialItemId!)))
              .getSingleOrNull();
          if (holding != null) {
            final newUnits = (holding.unitCountMicroUnits - unitsToRemove)
                .clamp(0, double.maxFinite.toInt());
            final newInvested = (holding.initialValuePaise - amountToRemove)
                .clamp(0, double.maxFinite.toInt());
            final scheme =
                await db.mutualFundDao.getSchemeByCode(sip.schemeCode);
            final latestNav = scheme?.latestNavMicroPaise ?? 0;
            final newValuation = FinancialPrecision.calculateValuationPaise(
              unitCountMicroUnits: newUnits,
              navMicroPaise: latestNav,
            );

            await (update(financialItems)
                  ..where((tbl) => tbl.id.equals(holding.id)))
                .write(
              FinancialItemsCompanion(
                initialValuePaise: Value(newInvested),
                unitCountMicroUnits: Value(newUnits),
                currentValuationPaise: Value(newValuation),
                updatedAt: Value(DateTime.now().toUtc()),
              ),
            );
          }
        }
      }

      // 3. Delete installment record
      await (delete(sipInstallments)
            ..where((tbl) => tbl.id.equals(installmentId)))
          .go();
      return true;
    });
  }

  /// Cancel all future/upcoming installments for a SIP plan, preserving historical recorded investments.
  Future<int> cancelFutureInstallments(int sipPlanId) async {
    return transaction(() async {
      final count = await (update(sipInstallments)
            ..where((tbl) =>
                tbl.sipPlanId.equals(sipPlanId) &
                (tbl.status.equals('upcoming') |
                    tbl.status.equals('simulated'))))
          .write(
        SipInstallmentsCompanion(
          status: const Value('cancelled'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      await (update(sipPlans)..where((tbl) => tbl.id.equals(sipPlanId))).write(
        SipPlansCompanion(
          status: const Value('stopped'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      return count;
    });
  }

  /// Atomically delete a SIP Plan and all associated periods, installments, and exclusively linked transactions.
  ///
  /// Cascade rules:
  /// 1. Finds all installments belonging to this SIP plan.
  /// 2. Gathers all transaction IDs linked to these installments.
  /// 3. Computes the confirmed units and amount generated by this SIP's installments.
  /// 4. Deletes exclusively linked transactions from `Transactions`.
  /// 5. Deletes all installments belonging to this SIP plan.
  /// 6. Deletes all schedule periods belonging to this SIP plan.
  /// 7. Deletes the master SIP plan.
  /// 8. Cleans up or recalculates the associated holding (`FinancialItem`):
  ///    - If no other SIPs and no other transactions exist for the holding, deletes the holding.
  ///    - Otherwise, decrements the units and invested capital and recalculates valuation.
  /// 9. Guarantees that shared market reference data (`MutualFundSchemes`, `NavHistory`) is NEVER deleted.
  /// 10. Executes all operations atomically within a Drift database transaction.
  Future<bool> deleteSip(int sipPlanId) async {
    return transaction(() async {
      final sip = await getSipById(sipPlanId);
      if (sip == null) return false;

      // 1. Fetch all installments for this SIP plan
      final installments = await (select(sipInstallments)
            ..where((tbl) => tbl.sipPlanId.equals(sipPlanId)))
          .get();

      // 2. Identify all exclusively linked transaction IDs
      final txIds = installments
          .map((i) => i.transactionId)
          .whereType<int>()
          .toSet()
          .toList();

      int unitsToRemove = 0;
      int investedToRemove = 0;
      for (final inst in installments) {
        if (inst.unitsMicroUnits != null && inst.unitsMicroUnits! > 0) {
          unitsToRemove += inst.unitsMicroUnits!;
        }
        if (inst.actualAmountPaise != null && inst.actualAmountPaise! > 0) {
          investedToRemove += inst.actualAmountPaise!;
        }
      }

      // 3. Delete transactions
      if (txIds.isNotEmpty) {
        await (delete(transactions)..where((tbl) => tbl.id.isIn(txIds))).go();
      }

      // 4. Delete installments
      await (delete(sipInstallments)
            ..where((tbl) => tbl.sipPlanId.equals(sipPlanId)))
          .go();

      // 5. Delete schedule periods
      await (delete(sipSchedulePeriods)
            ..where((tbl) => tbl.sipPlanId.equals(sipPlanId)))
          .go();

      // 6. Delete master SIP plan
      await (delete(sipPlans)..where((tbl) => tbl.id.equals(sipPlanId))).go();

      // 7. Inspect linked holding
      if (sip.financialItemId != null) {
        final holdingId = sip.financialItemId!;
        final otherSips = await (select(sipPlans)
              ..where((tbl) =>
                  tbl.financialItemId.equals(holdingId) &
                  tbl.id.isNotValue(sipPlanId)))
            .get();

        final remainingTxs = await (select(transactions)
              ..where((tbl) => tbl.financialItemId.equals(holdingId)))
            .get();

        final holding = await (select(financialItems)
              ..where((tbl) => tbl.id.equals(holdingId)))
            .getSingleOrNull();

        if (holding != null) {
          if (otherSips.isEmpty && remainingTxs.isEmpty) {
            // No remaining SIPs or transactions for this holding -> delete holding
            await (delete(financialItems)
                  ..where((tbl) => tbl.id.equals(holdingId)))
                .go();
          } else {
            // Deduct units and invested capital
            final newUnits = (holding.unitCountMicroUnits - unitsToRemove)
                .clamp(0, double.maxFinite.toInt());
            final newInvested = (holding.initialValuePaise - investedToRemove)
                .clamp(0, double.maxFinite.toInt());

            if (newUnits == 0 &&
                newInvested == 0 &&
                otherSips.isEmpty &&
                remainingTxs.isEmpty) {
              await (delete(financialItems)
                    ..where((tbl) => tbl.id.equals(holdingId)))
                  .go();
            } else {
              final scheme =
                  await db.mutualFundDao.getSchemeByCode(sip.schemeCode);
              final latestNav = scheme?.latestNavMicroPaise ?? 0;
              final newValuation = FinancialPrecision.calculateValuationPaise(
                unitCountMicroUnits: newUnits,
                navMicroPaise: latestNav,
              );

              await (update(financialItems)
                    ..where((tbl) => tbl.id.equals(holdingId)))
                  .write(
                FinancialItemsCompanion(
                  initialValuePaise: Value(newInvested),
                  unitCountMicroUnits: Value(newUnits),
                  currentValuationPaise: Value(newValuation),
                  updatedAt: Value(DateTime.now().toUtc()),
                ),
              );
            }
          }
        }
      }

      return true;
    });
  }

  /// Fetch all installments for a specific SIP plan.
  Future<List<SipInstallment>> getInstallmentsByPlan(int sipPlanId) {
    return (select(sipInstallments)
          ..where((tbl) => tbl.sipPlanId.equals(sipPlanId))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.scheduledDate)]))
        .get();
  }

  /// Create a complete investment schedule for a mutual fund asset.
  ///
  /// Guarantees:
  /// 1. Links to or creates an isolated profile holding (`FinancialItem`).
  /// 2. Calculates historical NAV applicable for EACH past scheduled installment.
  /// 3. Marks past installments as `pending_valuation` if historical NAV is missing without inventing NAV.
  /// 4. Leaves future installments as planned contributions without calculating future units using today's NAV.
  /// 5. Separates confirmed user investments from future planned amounts.
  Future<InvestmentScheduleResult> createInvestmentSchedule({
    required int profileId,
    required int schemeCode,
    required String schemeName,
    String? fundHouse,
    required int amountPerInstallmentPaise,
    required DateTime startDate,
    int? installmentCount,
    int? totalInstallments,
    required ScheduleFrequency frequency,
    String? name,
    String? notes,
    bool markPastAsConfirmed = true,
    int? latestNavMicroPaise,
    DateTime? asOfDate,
  }) async {
    final effectiveCount = installmentCount ?? totalInstallments ?? 1;
    return transaction(() async {
      // 1. Ensure master scheme exists in mutual_fund_schemes
      await db.mutualFundDao.upsertScheme(
        MutualFundSchemesCompanion(
          schemeCode: Value(schemeCode),
          schemeName: Value(schemeName),
          fundHouse:
              fundHouse != null ? Value(fundHouse) : const Value.absent(),
          latestNavMicroPaise: latestNavMicroPaise != null
              ? Value(latestNavMicroPaise)
              : const Value.absent(),
        ),
      );

      // 2. Calculate schedule dates and past/future partition
      final schedule = InvestmentScheduleService.calculateSchedule(
        startDate: startDate,
        installmentCount: effectiveCount,
        frequency: frequency,
        amountPerInstallmentPaise: amountPerInstallmentPaise,
        asOfDate: asOfDate,
      );

      // 3. Find existing holding or create a new profile-owned holding
      final existingHolding = await (select(financialItems)
            ..where((tbl) =>
                tbl.profileId.equals(profileId) &
                tbl.subType.equals('mutual_fund') &
                tbl.externalCode.equals(schemeCode.toString()) &
                tbl.status.equals('active')))
          .getSingleOrNull();

      final categories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final categoryId = categories.isNotEmpty ? categories.first.id : 1;

      int holdingId;
      if (existingHolding == null) {
        holdingId = await into(financialItems).insert(
          FinancialItemsCompanion(
            profileId: Value(profileId),
            name: Value(schemeName),
            itemType: const Value('asset'),
            subType: const Value('mutual_fund'),
            categoryId: Value(categoryId),
            externalCode: Value(schemeCode.toString()),
            initialValuePaise: const Value(0),
            currentValuationPaise: const Value(0),
            unitCountMicroUnits: const Value(0),
            status: const Value('active'),
          ),
        );
      } else {
        holdingId = existingHolding.id;
      }

      // 4. Create Master SipPlan
      final isAllPast = schedule.futureInstallments == 0;
      final sipId = await into(sipPlans).insert(
        SipPlansCompanion(
          profileId: Value(profileId),
          financialItemId: Value(holdingId),
          schemeCode: Value(schemeCode),
          name: Value(name ?? '$schemeName (${frequency.label})'),
          startDate: Value(startDate),
          endDate: schedule.occurrences.isNotEmpty
              ? Value(schedule.occurrences.last.scheduledDate)
              : Value(startDate),
          status: Value(isAllPast ? 'completed' : 'active'),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 5. Create Initial Schedule Period
      final periodId = await into(sipSchedulePeriods).insert(
        SipSchedulePeriodsCompanion(
          sipPlanId: Value(sipId),
          effectiveFrom: Value(startDate),
          effectiveTo: schedule.occurrences.isNotEmpty
              ? Value(schedule.occurrences.last.scheduledDate)
              : Value(startDate),
          amountPaise: Value(amountPerInstallmentPaise),
          deductionDay: Value(startDate.day),
          frequency: Value(frequency.name),
          status: const Value('active'),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 6. Generate individual occurrences
      int confirmedInvestedPaise = 0;
      int confirmedUnitsMicro = 0;
      int valuedPastCount = 0;
      int pendingValuationCount = 0;

      for (final occ in schedule.occurrences) {
        if (occ.isPast) {
          // Look up historical NAV on or before this scheduled date
          final navRecord = await db.mutualFundDao.getNavOnOrBefore(
            schemeCode,
            occ.scheduledDate,
          );

          if (navRecord != null && navRecord.navMicroPaise > 0) {
            final purchaseNav = navRecord.navMicroPaise;
            final units = FinancialPrecision.calculateUnitsPurchased(
              amountPaise: amountPerInstallmentPaise,
              navMicroPaise: purchaseNav,
            );
            valuedPastCount++;

            int? txId;
            if (markPastAsConfirmed) {
              confirmedInvestedPaise += amountPerInstallmentPaise;
              confirmedUnitsMicro += units;

              txId = await into(transactions).insert(
                TransactionsCompanion(
                  profileId: Value(profileId),
                  transactionType: const Value('investment_purchase'),
                  categoryId: Value(categoryId),
                  financialItemId: Value(holdingId),
                  transactionDate: Value(occ.scheduledDate),
                  amountPaise: Value(amountPerInstallmentPaise),
                  unitsMicroUnits: Value(units),
                  unitPriceMicroPaise: Value(purchaseNav),
                  source: const Value('sip_installment'),
                  notes: Value(
                    'SIP installment for $schemeName (NAV: ₹${FinancialPrecision.microPaiseToNav(purchaseNav).toStringAsFixed(4)} as of ${navRecord.navDate.toIso8601String().split('T').first})',
                  ),
                ),
              );
            }

            await into(sipInstallments).insert(
              SipInstallmentsCompanion(
                sipPlanId: Value(sipId),
                schedulePeriodId: Value(periodId),
                profileId: Value(profileId),
                scheduledDate: Value(occ.scheduledDate),
                expectedAmountPaise: Value(amountPerInstallmentPaise),
                status: Value(markPastAsConfirmed ? 'recorded' : 'simulated'),
                isSimulated: Value(!markPastAsConfirmed),
                actualInvestmentDate: Value(occ.scheduledDate),
                actualAmountPaise: Value(amountPerInstallmentPaise),
                purchaseNavMicroPaise: Value(purchaseNav),
                unitsMicroUnits: Value(units),
                transactionId:
                    txId != null ? Value(txId) : const Value.absent(),
                notes: Value(
                  'Applicable NAV date: ${navRecord.navDate.toIso8601String().split('T').first}',
                ),
              ),
              onConflict: DoNothing(
                target: [
                  sipInstallments.sipPlanId,
                  sipInstallments.scheduledDate,
                ],
              ),
            );
          } else {
            // Missing NAV -> pending_valuation
            pendingValuationCount++;
            await into(sipInstallments).insert(
              SipInstallmentsCompanion(
                sipPlanId: Value(sipId),
                schedulePeriodId: Value(periodId),
                profileId: Value(profileId),
                scheduledDate: Value(occ.scheduledDate),
                expectedAmountPaise: Value(amountPerInstallmentPaise),
                status: const Value('pending_valuation'),
                isSimulated: Value(!markPastAsConfirmed),
                actualInvestmentDate: markPastAsConfirmed
                    ? Value(occ.scheduledDate)
                    : const Value.absent(),
                actualAmountPaise: markPastAsConfirmed
                    ? Value(amountPerInstallmentPaise)
                    : const Value.absent(),
                notes: const Value('Historical NAV pending for this date'),
              ),
              onConflict: DoNothing(
                target: [
                  sipInstallments.sipPlanId,
                  sipInstallments.scheduledDate,
                ],
              ),
            );
          }
        } else {
          // Future installment -> planned occurrence, NO units calculated using today's NAV
          await into(sipInstallments).insert(
            SipInstallmentsCompanion(
              sipPlanId: Value(sipId),
              schedulePeriodId: Value(periodId),
              profileId: Value(profileId),
              scheduledDate: Value(occ.scheduledDate),
              expectedAmountPaise: Value(amountPerInstallmentPaise),
              status: const Value('upcoming'),
              isSimulated: const Value(true),
            ),
            onConflict: DoNothing(
              target: [
                sipInstallments.sipPlanId,
                sipInstallments.scheduledDate,
              ],
            ),
          );
        }
      }

      // 7. Update holding totals with confirmed past investments
      if (confirmedInvestedPaise > 0 || confirmedUnitsMicro > 0) {
        final currentHolding =
            await db.financialItemsDao.getItemById(holdingId);
        if (currentHolding != null) {
          final newInvested =
              currentHolding.initialValuePaise + confirmedInvestedPaise;
          final newUnits =
              currentHolding.unitCountMicroUnits + confirmedUnitsMicro;

          // Value holding using latest scheme NAV
          final scheme = await db.mutualFundDao.getSchemeByCode(schemeCode);
          final latestNav = scheme?.latestNavMicroPaise ?? 0;
          final newValuation = latestNav > 0
              ? FinancialPrecision.calculateValuationPaise(
                  unitCountMicroUnits: newUnits,
                  navMicroPaise: latestNav,
                )
              : newInvested;

          await db.financialItemsDao.updateItem(
            currentHolding.copyWith(
              initialValuePaise: newInvested,
              unitCountMicroUnits: newUnits,
              currentValuationPaise: newValuation,
              updatedAt: DateTime.now().toUtc(),
            ),
          );
        }
      }

      return InvestmentScheduleResult(
        sipPlanId: sipId,
        financialItemId: holdingId,
        totalInstallments: schedule.totalInstallments,
        pastInstallments: schedule.pastInstallments,
        futureInstallments: schedule.futureInstallments,
        valuedPastInstallments: valuedPastCount,
        pendingValuationInstallments: pendingValuationCount,
        confirmedInvestedPaise: confirmedInvestedPaise,
        futurePlannedPaise: schedule.futureScheduledAmountPaise,
        totalUnitsMicroUnits: confirmedUnitsMicro,
      );
    });
  }

  /// Retries valuation for all installments marked `pending_valuation` under a scheme.
  Future<int> revaluePendingInstallments(int schemeCode) async {
    return transaction(() async {
      // Find all pending valuation installments for this scheme
      final pendingQuery = select(sipInstallments).join([
        innerJoin(
          sipPlans,
          sipPlans.id.equalsExp(sipInstallments.sipPlanId),
        ),
      ])
        ..where(sipPlans.schemeCode.equals(schemeCode) &
            sipInstallments.status.equals('pending_valuation'));

      final rows = await pendingQuery.get();
      if (rows.isEmpty) return 0;

      int revaluedCount = 0;
      final categoryList =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final categoryId = categoryList.isNotEmpty ? categoryList.first.id : 1;

      for (final row in rows) {
        final inst = row.readTable(sipInstallments);
        final sip = row.readTable(sipPlans);

        final navRecord = await db.mutualFundDao.getNavOnOrBefore(
          schemeCode,
          inst.scheduledDate,
        );

        if (navRecord != null && navRecord.navMicroPaise > 0) {
          final purchaseNav = navRecord.navMicroPaise;
          final units = FinancialPrecision.calculateUnitsPurchased(
            amountPaise: inst.expectedAmountPaise,
            navMicroPaise: purchaseNav,
          );

          int? txId = inst.transactionId;
          // If this was a confirmed investment, create transaction
          if (!inst.isSimulated && txId == null) {
            txId = await into(transactions).insert(
              TransactionsCompanion(
                profileId: Value(inst.profileId),
                transactionType: const Value('investment_purchase'),
                categoryId: Value(categoryId),
                financialItemId: sip.financialItemId != null
                    ? Value(sip.financialItemId!)
                    : const Value.absent(),
                transactionDate: Value(inst.scheduledDate),
                amountPaise: Value(inst.expectedAmountPaise),
                unitsMicroUnits: Value(units),
                unitPriceMicroPaise: Value(purchaseNav),
                source: const Value('sip_installment'),
                notes: Value('Revalued SIP installment for ${sip.name}'),
              ),
            );

            // Update holding
            if (sip.financialItemId != null) {
              final holding =
                  await db.financialItemsDao.getItemById(sip.financialItemId!);
              if (holding != null) {
                final newInvested =
                    holding.initialValuePaise + inst.expectedAmountPaise;
                final newUnits = holding.unitCountMicroUnits + units;
                final latestNav =
                    (await db.mutualFundDao.getSchemeByCode(schemeCode))
                            ?.latestNavMicroPaise ??
                        purchaseNav;

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
          }

          // Update installment record
          await (update(sipInstallments)
                ..where((tbl) => tbl.id.equals(inst.id)))
              .write(
            SipInstallmentsCompanion(
              status: Value(inst.isSimulated ? 'simulated' : 'recorded'),
              actualInvestmentDate: Value(inst.scheduledDate),
              actualAmountPaise: Value(inst.expectedAmountPaise),
              purchaseNavMicroPaise: Value(purchaseNav),
              unitsMicroUnits: Value(units),
              transactionId: txId != null ? Value(txId) : const Value.absent(),
              notes: Value(
                'Valued from NAV on ${navRecord.navDate.toIso8601String().split('T').first}',
              ),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

          revaluedCount++;
        }
      }

      return revaluedCount;
    });
  }

  /// Update an investment schedule's future occurrences while preserving all historical transactions.
  Future<bool> updateInvestmentSchedule({
    required int sipPlanId,
    required DateTime effectiveDate,
    required int newAmountPaise,
    required ScheduleFrequency newFrequency,
    required int remainingInstallments,
    String? notes,
  }) async {
    return transaction(() async {
      final sip = await getSipById(sipPlanId);
      if (sip == null) return false;

      final normalizedEffective = DateTime.utc(
        effectiveDate.year,
        effectiveDate.month,
        effectiveDate.day,
      );

      // 1. Delete only future upcoming unrecorded occurrences on or after effectiveDate
      await (delete(sipInstallments)
            ..where((tbl) =>
                tbl.sipPlanId.equals(sipPlanId) &
                tbl.scheduledDate.isBiggerOrEqualValue(normalizedEffective) &
                (tbl.status.equals('upcoming') | tbl.isSimulated.equals(true))))
          .go();

      // 2. Archive active period by setting effectiveTo
      final activePeriods = await (select(sipSchedulePeriods)
            ..where((tbl) =>
                tbl.sipPlanId.equals(sipPlanId) & tbl.status.equals('active')))
          .get();

      for (final period in activePeriods) {
        await (update(sipSchedulePeriods)
              ..where((tbl) => tbl.id.equals(period.id)))
            .write(
          SipSchedulePeriodsCompanion(
            effectiveTo: Value(
              normalizedEffective.subtract(const Duration(days: 1)),
            ),
            status: const Value('superseded'),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
      }

      // 3. Generate future dates starting from effectiveDate
      final futureDates = InvestmentScheduleService.generateScheduleDates(
        startDate: normalizedEffective,
        installmentCount: remainingInstallments,
        frequency: newFrequency,
      );

      final newEndDate =
          futureDates.isNotEmpty ? futureDates.last : normalizedEffective;

      // 4. Create new schedule period
      final periodId = await into(sipSchedulePeriods).insert(
        SipSchedulePeriodsCompanion(
          sipPlanId: Value(sipPlanId),
          effectiveFrom: Value(normalizedEffective),
          effectiveTo: Value(newEndDate),
          amountPaise: Value(newAmountPaise),
          deductionDay: Value(normalizedEffective.day),
          frequency: Value(newFrequency.name),
          status: const Value('active'),
          notes: notes != null ? Value(notes) : const Value.absent(),
        ),
      );

      // 5. Insert new future installments
      for (final date in futureDates) {
        await into(sipInstallments).insert(
          SipInstallmentsCompanion(
            sipPlanId: Value(sipPlanId),
            schedulePeriodId: Value(periodId),
            profileId: Value(sip.profileId),
            scheduledDate: Value(date),
            expectedAmountPaise: Value(newAmountPaise),
            status: const Value('upcoming'),
            isSimulated: const Value(true),
          ),
          onConflict: DoNothing(
            target: [
              sipInstallments.sipPlanId,
              sipInstallments.scheduledDate,
            ],
          ),
        );
      }

      // 6. Update master SIP plan end date and status
      await (update(sipPlans)..where((tbl) => tbl.id.equals(sipPlanId))).write(
        SipPlansCompanion(
          endDate: Value(newEndDate),
          status: const Value('active'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      return true;
    });
  }
}

/// Result summary returned after creating a complete investment schedule.
class InvestmentScheduleResult {
  final int sipPlanId;
  final int financialItemId;
  final int totalInstallments;
  final int pastInstallments;
  final int futureInstallments;
  final int valuedPastInstallments;
  final int pendingValuationInstallments;
  final int confirmedInvestedPaise;
  final int futurePlannedPaise;
  final int totalUnitsMicroUnits;

  const InvestmentScheduleResult({
    required this.sipPlanId,
    required this.financialItemId,
    required this.totalInstallments,
    required this.pastInstallments,
    required this.futureInstallments,
    required this.valuedPastInstallments,
    required this.pendingValuationInstallments,
    required this.confirmedInvestedPaise,
    required this.futurePlannedPaise,
    required this.totalUnitsMicroUnits,
  });

  int get confirmedUnitsMicro => totalUnitsMicroUnits;
  int get valuedPastCount => valuedPastInstallments;
  int get pendingValuationCount => pendingValuationInstallments;
}
