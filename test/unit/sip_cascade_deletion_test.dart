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
        latestNavMicroPaise: Value(52450000), // ₹52.4500
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
          navMicroPaise: const Value(52000000), // ₹52.0000
        ),
      ],
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('SIP Cascade Deletion Tests', () {
    test(
        'Deleting a SIP atomically cascades to periods, installments, and transactions',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Investor A'),
          relationship: Value('self'),
        ),
      );

      // Create investment schedule starting in past (2 past + 2 future)
      final result = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund - Direct Plan - Growth',
        fundHouse: 'Axis Mutual Fund',
        amountPerInstallmentPaise: 500000, // ₹5,000
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 4,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
        latestNavMicroPaise: 52450000,
      );

      final sipId = result.sipPlanId;
      final holdingId = result.financialItemId;

      // Verify records were created
      final periodsBefore = await db.sipsDao.getSchedulePeriods(sipId);
      final installmentsBefore = await db.sipsDao.getInstallments(sipId);
      final txsBefore = await db.transactionsDao.getTransactionsByItem(
        profileId,
        holdingId,
      );
      final holdingBefore = await db.financialItemsDao.getItemById(holdingId);

      expect(periodsBefore, isNotEmpty);
      expect(installmentsBefore.length, 4);
      expect(
          txsBefore.length, 2); // 2 past installments recorded as transactions
      expect(holdingBefore, isNotNull);
      expect(holdingBefore!.unitCountMicroUnits, greaterThan(0));

      // ACT: Delete the SIP
      final deleted = await db.sipsDao.deleteSip(sipId);
      expect(deleted, isTrue);

      // ASSERT: Master plan, periods, installments, and transactions are completely removed
      final sipAfter = await db.sipsDao.getSipById(sipId);
      expect(sipAfter, isNull);

      final periodsAfter = await db.sipsDao.getSchedulePeriods(sipId);
      expect(periodsAfter, isEmpty);

      final installmentsAfter = await db.sipsDao.getInstallments(sipId);
      expect(installmentsAfter, isEmpty);

      final txsAfter = await db.transactionsDao.getTransactionsByItem(
        profileId,
        holdingId,
      );
      expect(txsAfter, isEmpty);

      // Since no other SIPs or transactions existed for this holding, holding is cleaned up
      final holdingAfter = await db.financialItemsDao.getItemById(holdingId);
      expect(holdingAfter, isNull);

      // Shared scheme & NAV history MUST BE PRESERVED
      final scheme = await db.mutualFundDao.getSchemeByCode(120503);
      expect(scheme, isNotNull);
      expect(scheme!.schemeName, 'Axis Bluechip Fund - Direct Plan - Growth');

      final navList = await db.mutualFundDao.getNavHistory(120503);
      expect(navList.length, 2);
    });

    test(
        'Deleting one SIP retains holding and decrements units when another SIP shares the same holding',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Investor B'),
          relationship: Value('self'),
        ),
      );

      // Create first SIP schedule
      final sip1 = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund - Direct Plan - Growth',
        amountPerInstallmentPaise: 500000, // ₹5,000
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
        latestNavMicroPaise: 52450000,
      );

      // Create second SIP schedule for the same holding
      final sip2 = await db.sipsDao.createInvestmentSchedule(
        profileId: profileId,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund - Direct Plan - Growth',
        amountPerInstallmentPaise: 1000000, // ₹10,000
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
        latestNavMicroPaise: 52450000,
      );

      expect(sip1.financialItemId, equals(sip2.financialItemId));
      final holdingId = sip1.financialItemId;

      final holdingBoth = (await db.financialItemsDao.getItemById(holdingId))!;
      final totalUnitsBefore = holdingBoth.unitCountMicroUnits;
      final totalInvestedBefore = holdingBoth.initialValuePaise;

      // Delete SIP 1
      await db.sipsDao.deleteSip(sip1.sipPlanId);

      // Holding should STILL EXIST because SIP 2 is active
      final holdingAfterSip1 =
          await db.financialItemsDao.getItemById(holdingId);
      expect(holdingAfterSip1, isNotNull);
      expect(holdingAfterSip1!.unitCountMicroUnits, lessThan(totalUnitsBefore));
      expect(
        holdingAfterSip1.initialValuePaise,
        lessThan(totalInvestedBefore),
      );

      // SIP 2 still has its installments and transactions
      final sip2Installments = await db.sipsDao.getInstallments(sip2.sipPlanId);
      expect(sip2Installments.length, 2);

      // Delete SIP 2
      await db.sipsDao.deleteSip(sip2.sipPlanId);

      // Now holding should be completely removed
      final holdingFinal = await db.financialItemsDao.getItemById(holdingId);
      expect(holdingFinal, isNull);
    });

    test('Deleting SIP in Profile 1 does not affect Profile 2', () async {
      final p1 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Person 1')),
      );
      final p2 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(name: Value('Person 2')),
      );

      final sipP1 = await db.sipsDao.createInvestmentSchedule(
        profileId: p1,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 500000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
      );

      final sipP2 = await db.sipsDao.createInvestmentSchedule(
        profileId: p2,
        schemeCode: 120503,
        schemeName: 'Axis Bluechip Fund',
        amountPerInstallmentPaise: 700000,
        startDate: DateTime.utc(2024, 1, 15),
        installmentCount: 2,
        frequency: ScheduleFrequency.monthly,
        asOfDate: DateTime.utc(2024, 2, 20),
      );

      // Delete Person 1's SIP
      await db.sipsDao.deleteSip(sipP1.sipPlanId);

      // Person 2's SIP, installments, holding, and transactions must be 100% intact
      final p2Sip = await db.sipsDao.getSipById(sipP2.sipPlanId);
      expect(p2Sip, isNotNull);

      final p2Installments = await db.sipsDao.getInstallments(sipP2.sipPlanId);
      expect(p2Installments.length, 2);

      final p2Holding =
          await db.financialItemsDao.getItemById(sipP2.financialItemId);
      expect(p2Holding, isNotNull);
      expect(p2Holding!.profileId, equals(p2));
    });
  });
}
