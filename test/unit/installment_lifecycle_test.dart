import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // Seed shared scheme & NAV history
    await db.mutualFundDao.upsertScheme(
      const MutualFundSchemesCompanion(
        schemeCode: Value(120503),
        schemeName: Value('Axis Bluechip Fund - Direct Plan - Growth'),
        fundHouse: Value('Axis Mutual Fund'),
        latestNavMicroPaise: Value(50000000), // ₹50.0000
      ),
    );

    await db.mutualFundDao.upsertNavRecords(
      120503,
      [
        NavHistoryCompanion(
          schemeCode: const Value(120503),
          navDate: Value(DateTime.utc(2024, 1, 15)),
          navMicroPaise: const Value(50000000), // ₹50.0000
        ),
        NavHistoryCompanion(
          schemeCode: const Value(120503),
          navDate: Value(DateTime.utc(2024, 2, 15)),
          navMicroPaise: const Value(50000000), // ₹50.0000
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Installment Lifecycle & Granular Deletion Tests', () {
    test(
        'Deleting a recorded installment removes its transaction and adjusts holding',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Investor C')),
      );

      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000, // ₹5,000
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2, // 2 past installments
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
        latestNavMicroPaise: 50000000,
      );

      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      expect(installments.length, 2);

      final inst1 = installments.first;
      expect(inst1.status, 'recorded');
      expect(inst1.transactionId, isNotNull);

      final holdingBefore =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;
      final unitsBefore = holdingBefore.unitCountMicroUnits;
      final investedBefore = holdingBefore.initialValuePaise;

      // Delete inst1
      final success = await db.sipsDao.deleteInstallment(inst1.id);
      expect(success, isTrue);

      // Verify inst1 is gone
      final installmentsAfter =
          await db.sipsDao.getInstallments(result.sipPlanId);
      expect(installmentsAfter.length, 1);
      expect(installmentsAfter.map((i) => i.id), isNot(contains(inst1.id)));

      // Linked transaction must be deleted
      final tx = await (db.select(db.transactions)
            ..where((tbl) => tbl.id.equals(inst1.transactionId!)))
          .getSingleOrNull();
      expect(tx, isNull);

      // Holding must have reduced units and invested amount
      final holdingAfter =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;
      expect(holdingAfter.unitCountMicroUnits, lessThan(unitsBefore));
      expect(holdingAfter.initialValuePaise, lessThan(investedBefore));
    });

    test(
        'Deleting an upcoming installment does not affect holding or transactions',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Investor D')),
      );

      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 4, // 2 past, 2 future
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
        latestNavMicroPaise: 50000000,
      );

      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      final upcoming = installments.firstWhere((i) => i.status == 'upcoming');

      final holdingBefore =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;

      // Delete upcoming installment
      await db.sipsDao.deleteInstallment(upcoming.id);

      final holdingAfter =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;
      expect(holdingAfter.unitCountMicroUnits,
          equals(holdingBefore.unitCountMicroUnits));
      expect(holdingAfter.initialValuePaise,
          equals(holdingBefore.initialValuePaise));
    });

    test('Skip and Cancel installment update status cleanly', () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Investor E')),
      );

      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 4,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
      );

      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      final upcoming1 = installments.where((i) => i.status == 'upcoming').first;
      final upcoming2 = installments.where((i) => i.status == 'upcoming').last;

      await db.sipsDao.skipInstallment(upcoming1.id);
      final updated1 = (await (db.select(db.sipInstallments)
            ..where((tbl) => tbl.id.equals(upcoming1.id)))
          .getSingle());
      expect(updated1.status, 'skipped');

      await db.sipsDao.cancelInstallment(upcoming2.id);
      final updated2 = (await (db.select(db.sipInstallments)
            ..where((tbl) => tbl.id.equals(upcoming2.id)))
          .getSingle());
      expect(updated2.status, 'cancelled');
    });

    test(
        'cancelFutureInstallments cancels future while preserving recorded past',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Investor F')),
      );

      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 4, // 2 past, 2 future
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
      );

      final holdingBefore =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;

      // Cancel all future
      final cancelledCount =
          await db.sipsDao.cancelFutureInstallments(result.sipPlanId);
      expect(cancelledCount, 2);

      // Verify SIP status stopped
      final sip = await db.sipsDao.getSipById(result.sipPlanId);
      expect(sip!.status, 'stopped');

      // Verify past installments are still recorded
      final installments = await db.sipsDao.getInstallments(result.sipPlanId);
      final recorded = installments.where((i) => i.status == 'recorded');
      expect(recorded.length, 2);

      final cancelled = installments.where((i) => i.status == 'cancelled');
      expect(cancelled.length, 2);

      // Verify holding is untouched
      final holdingAfter =
          (await db.financialItemsDao.getItemById(result.financialItemId))!;
      expect(holdingAfter.unitCountMicroUnits,
          equals(holdingBefore.unitCountMicroUnits));
    });
  });
}
