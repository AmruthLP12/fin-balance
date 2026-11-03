import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/calculations/investment_lifecycle_summary.dart';
import 'package:finbalance/core/scheduling/investment_schedule_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId;
  late int categoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());

    // 1. Create financial profile
    profileId = await db.profilesDao.createProfile(
      const FinancialProfilesCompanion(
        name: drift.Value('Vikram'),
        relationship: drift.Value('Self'),
        isDefault: drift.Value(true),
      ),
    );

    // 2. Fetch asset category
    final categories =
        await db.categoriesDao.getCategoriesByClassification('asset');
    categoryId = categories.isNotEmpty ? categories.first.id : 1;

    // 3. Seed mutual fund schemes
    await db.mutualFundDao.upsertScheme(
      MutualFundSchemesCompanion(
        schemeCode: const drift.Value(122639),
        schemeName:
            const drift.Value('Parag Parikh Flexi Cap Fund Direct Growth'),
        fundHouse: const drift.Value('PPFAS Mutual Fund'),
        latestNavMicroPaise: const drift.Value(75000000), // ₹75.00
        latestNavDate: drift.Value(DateTime.utc(2026, 11, 1)),
      ),
    );

    await db.mutualFundDao.upsertScheme(
      MutualFundSchemesCompanion(
        schemeCode: const drift.Value(119551),
        schemeName: const drift.Value('Axis Bluechip Fund Direct Plan Growth'),
        fundHouse: const drift.Value('Axis Mutual Fund'),
        latestNavMicroPaise: const drift.Value(50000000), // ₹50.00
        latestNavDate: drift.Value(DateTime.utc(2026, 11, 1)),
      ),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Frequency Calculation & Month-End Clamping Tests', () {
    test('One Time generates exactly 1 occurrence', () {
      final start = DateTime.utc(2026, 1, 15);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.oneTime,
        installmentCount: 12, // Count should be ignored for oneTime
      );
      expect(dates.length, 1);
      expect(dates.first, start);
    });

    test('Daily generates dates every day', () {
      final start = DateTime.utc(2026, 1, 1);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.daily,
        installmentCount: 5,
      );
      expect(dates.length, 5);
      expect(dates, [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 2),
        DateTime.utc(2026, 1, 3),
        DateTime.utc(2026, 1, 4),
        DateTime.utc(2026, 1, 5),
      ]);
    });

    test('Weekly generates dates every 7 days', () {
      final start = DateTime.utc(2026, 1, 1);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.weekly,
        installmentCount: 4,
      );
      expect(dates.length, 4);
      expect(dates, [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 8),
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 1, 22),
      ]);
    });

    test('Fortnightly generates dates every 14 days', () {
      final start = DateTime.utc(2026, 1, 1);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.fortnightly,
        installmentCount: 3,
      );
      expect(dates.length, 3);
      expect(dates, [
        DateTime.utc(2026, 1, 1),
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 1, 29),
      ]);
    });

    test(
        'Monthly month-end clamping prevents drift (Jan 31 -> Feb 28 -> Mar 31)',
        () {
      // 2026 is non-leap year (Feb has 28 days)
      final start = DateTime.utc(2026, 1, 31);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.monthly,
        installmentCount: 4,
      );
      expect(dates.length, 4);
      expect(dates[0], DateTime.utc(2026, 1, 31));
      expect(dates[1], DateTime.utc(2026, 2, 28)); // clamped to 28
      expect(
          dates[2], DateTime.utc(2026, 3, 31)); // restored to original day 31!
      expect(dates[3], DateTime.utc(2026, 4, 30)); // April has 30 days
    });

    test('Leap year Feb 29 preserves target day for yearly schedule', () {
      // 2024 is a leap year (Feb 29)
      final start = DateTime.utc(2024, 2, 29);
      final dates = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.yearly,
        installmentCount: 5,
      );
      expect(dates.length, 5);
      expect(dates[0], DateTime.utc(2024, 2, 29)); // Leap year
      expect(dates[1], DateTime.utc(2025, 2, 28)); // Non-leap year clamped
      expect(dates[2], DateTime.utc(2026, 2, 28)); // Non-leap year clamped
      expect(dates[3], DateTime.utc(2027, 2, 28)); // Non-leap year clamped
      expect(dates[4],
          DateTime.utc(2028, 2, 29)); // Next leap year restored to 29!
    });

    test('Quarterly and Half-Yearly frequencies calculate correct intervals',
        () {
      final start = DateTime.utc(2026, 1, 15);
      final quarterly = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.quarterly,
        installmentCount: 4,
      );
      expect(quarterly, [
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 4, 15),
        DateTime.utc(2026, 7, 15),
        DateTime.utc(2026, 10, 15),
      ]);

      final halfYearly = InvestmentScheduleService.generateScheduleDatesRange(
        startDate: start,
        frequency: ScheduleFrequency.halfYearly,
        installmentCount: 3,
      );
      expect(halfYearly, [
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 7, 15),
        DateTime.utc(2027, 1, 15),
      ]);
    });
  });

  group('SWP Recurring Installments & Isolation Tests', () {
    test('SWP plan creation and periods generation in Amount mode', () async {
      // Create parent holding with 100 units at ₹75 = ₹7,500
      final holdingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(750000),
          currentValuationPaise: const drift.Value(750000),
          unitCountMicroUnits: const drift.Value(100000000), // 100.0 units
        ),
      );

      final swpId = await db.swpsDao.createSwpWithPeriod(
        profileId: profileId,
        financialItemId: holdingId,
        schemeCode: 122639,
        name: 'PPFAS Monthly SWP',
        startDate: DateTime.utc(2026, 1, 10),
        withdrawalMode: 'amount',
        amountPaise: 100000, // ₹1,000 / month
        deductionDay: 10,
        frequency: 'monthly',
        installmentCount: 6,
      );

      expect(swpId, greaterThan(0));

      final periods = await db.swpsDao.getSchedulePeriods(swpId);
      expect(periods.length, 1);
      expect(periods.first.withdrawalMode, 'amount');
      expect(periods.first.amountPaise, 100000);
      expect(periods.first.frequency, 'monthly');

      final installments = await db.swpsDao.getInstallments(swpId);
      expect(installments.length, 6);
      expect(installments.every((i) => i.isSimulated && i.status == 'upcoming'),
          isTrue);

      // Planned future withdrawals must NOT reduce holding units or valuation!
      final holding = await db.financialItemsDao.getItemById(holdingId);
      expect(holding!.unitCountMicroUnits,
          100000000); // exactly 100 units preserved
      expect(holding.currentValuationPaise, 750000);
    });

    test('SWP plan creation in Units mode', () async {
      final holdingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(1000000),
          currentValuationPaise: const drift.Value(1000000),
          unitCountMicroUnits: const drift.Value(100000000),
        ),
      );

      final swpId = await db.swpsDao.createSwpWithPeriod(
        profileId: profileId,
        financialItemId: holdingId,
        schemeCode: 122639,
        name: 'PPFAS Units SWP',
        startDate: DateTime.utc(2026, 2, 1),
        withdrawalMode: 'units',
        unitsMicroUnits: 10000000, // 10 units / month
        deductionDay: 1,
        frequency: 'monthly',
        installmentCount: 3,
      );

      final periods = await db.swpsDao.getSchedulePeriods(swpId);
      expect(periods.first.withdrawalMode, 'units');
      expect(periods.first.unitsMicroUnits, 10000000);

      final installments = await db.swpsDao.getInstallments(swpId);
      expect(installments.length, 3);
      expect(installments.first.expectedUnitsMicroUnits, 10000000);
    });

    test('Confirming actual SWP withdrawal reduces units and valuation',
        () async {
      final holdingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(750000),
          currentValuationPaise: const drift.Value(750000),
          unitCountMicroUnits: const drift.Value(100000000), // 100 units
        ),
      );

      // Record SWP withdrawal of ₹1,500 (20 units at ₹75 NAV)
      await db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: 'swp_withdrawal',
        transactionDate: DateTime.utc(2026, 2, 10),
        amountPaise: 150000,
        unitsMicroUnits: 20000000, // 20 units
        unitPriceMicroPaise: 75000000,
      );

      final updatedHolding = await db.financialItemsDao.getItemById(holdingId);
      expect(
          updatedHolding!.unitCountMicroUnits, 80000000); // 80 units remaining
      expect(updatedHolding.currentValuationPaise, 600000); // 80 * 75 = ₹6,000
    });

    test('Closing SWP period cancels future installments and updates status',
        () async {
      final holdingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
        ),
      );

      final swpId = await db.swpsDao.createSwpWithPeriod(
        profileId: profileId,
        financialItemId: holdingId,
        schemeCode: 122639,
        name: 'PPFAS SWP',
        startDate: DateTime.utc(2026, 1, 1),
        withdrawalMode: 'amount',
        amountPaise: 100000,
        deductionDay: 1,
        frequency: 'monthly',
        installmentCount: 12,
      );

      await db.swpsDao.closeSchedulePeriod(
        swpPlanId: swpId,
        closeDate: DateTime.utc(2026, 3, 1),
      );

      final periods = await db.swpsDao.getSchedulePeriods(swpId);
      expect(periods.first.status, 'closed');
      expect(periods.first.effectiveTo, isNotNull);

      final swp = await db.swpsDao.getSwpById(swpId);
      expect(swp!.status, 'stopped');

      final installments = await db.swpsDao.getInstallments(swpId);
      final futureInstallments = installments
          .where((i) => !i.scheduledDate.isBefore(DateTime.utc(2026, 3, 1)));
      expect(futureInstallments.every((i) => i.status == 'cancelled'), isTrue);
    });
  });

  group('Switch Transaction with Destination Scheme Tests', () {
    test('Switch Out from source into newly created destination scheme',
        () async {
      // 1. Source holding with 100 units at ₹75 = ₹7,500
      final sourceHoldingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(750000),
          currentValuationPaise: const drift.Value(750000),
          unitCountMicroUnits: const drift.Value(100000000), // 100 units
        ),
      );

      // 2. Auto-create destination holding for Axis Bluechip (0 initial capital avoids double counting)
      final destHoldingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Axis Bluechip Fund Direct Plan Growth'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('119551'),
          status: const drift.Value('active'),
          initialValuePaise:
              const drift.Value(0), // Transferred capital from switch
          currentValuationPaise: const drift.Value(0),
          unitCountMicroUnits: const drift.Value(0),
        ),
      );

      // 3. Switch ₹3,000 from PPFAS (40 units at ₹75) into Axis (60 units at ₹50)
      await db.transactionsDao.recordSwitchBetweenHoldings(
        profileId: profileId,
        sourceItemId: sourceHoldingId,
        destItemId: destHoldingId,
        categoryId: categoryId,
        transactionDate: DateTime.utc(2026, 2, 15),
        switchAmountPaise: 300000, // ₹3,000
        chargesPaise: 0,
        sourceUnitsMicroUnits: 40000000, // 40 units out
        sourceNavMicroPaise: 75000000, // ₹75
        destUnitsMicroUnits: 60000000, // 60 units in
        destNavMicroPaise: 50000000, // ₹50
        sourceNotes: 'Switched out to Axis Bluechip Fund Direct Plan Growth',
        destNotes: 'Switched in from Parag Parikh Flexi Cap Fund',
      );

      // 4. Verify Source Holding balance
      final updatedSource =
          await db.financialItemsDao.getItemById(sourceHoldingId);
      expect(
          updatedSource!.unitCountMicroUnits, 60000000); // 100 - 40 = 60 units
      expect(updatedSource.currentValuationPaise, 450000); // 60 * ₹75 = ₹4,500

      // 5. Verify Destination Holding balance
      final updatedDest = await db.financialItemsDao.getItemById(destHoldingId);
      expect(updatedDest!.unitCountMicroUnits, 60000000); // 60 units
      expect(updatedDest.currentValuationPaise, 300000); // 60 * ₹50 = ₹3,000

      // 6. Verify linked transactions
      final txs = await (db.select(db.transactions)
            ..where((tbl) => tbl.profileId.equals(profileId)))
          .get();
      final switchOutTx =
          txs.firstWhere((t) => t.transactionType == 'switch_out');
      final switchInTx =
          txs.firstWhere((t) => t.transactionType == 'switch_in');

      expect(switchOutTx.notes, contains('Switched out to'));
      expect(switchInTx.notes, contains('Switched in from'));
      expect(switchOutTx.linkedTransactionId, switchInTx.id);
      expect(switchInTx.linkedTransactionId, switchOutTx.id);
    });
  });

  group('Investment Lifecycle Point-Wise Narrative Tests', () {
    test('generateLifecycleEvents returns discrete chronological events', () {
      final holding = FinancialItem(
        id: 1,
        profileId: profileId,
        name: 'PPFAS Flexi Cap',
        itemType: 'asset',
        subType: 'mutual_fund',
        categoryId: categoryId,
        status: 'active',
        initialValuePaise: 500000,
        currentValuationPaise: 600000,
        unitCountMicroUnits: 80000000,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      final sips = <SipPlan>[
        SipPlan(
          id: 1,
          profileId: profileId,
          schemeCode: 122639,
          name: 'PPFAS SIP',
          startDate: DateTime.utc(2024, 1, 1),
          status: 'active',
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 1),
        ),
      ];

      final periods = [
        SipSchedulePeriod(
          id: 1,
          sipPlanId: 1,
          effectiveFrom: DateTime.utc(2024, 1, 1),
          effectiveTo: DateTime.utc(2024, 12, 31),
          amountPaise: 100000,
          deductionDay: 5,
          frequency: 'monthly',
          status: 'closed',
          createdAt: DateTime.utc(2024, 1, 1),
          updatedAt: DateTime.utc(2024, 1, 1),
        ),
        SipSchedulePeriod(
          id: 2,
          sipPlanId: 1,
          effectiveFrom: DateTime.utc(2025, 1, 1),
          amountPaise: 200000,
          deductionDay: 5,
          frequency: 'monthly',
          status: 'active',
          createdAt: DateTime.utc(2025, 1, 1),
          updatedAt: DateTime.utc(2025, 1, 1),
        ),
      ];

      final swpPeriods = [
        SwpSchedulePeriod(
          id: 1,
          swpPlanId: 1,
          effectiveFrom: DateTime.utc(2025, 6, 1),
          withdrawalMode: 'amount',
          amountPaise: 50000,
          deductionDay: 1,
          frequency: 'monthly',
          status: 'active',
          createdAt: DateTime.utc(2025, 6, 1),
          updatedAt: DateTime.utc(2025, 6, 1),
        ),
      ];

      final events = InvestmentLifecycleSummary.generateLifecycleEvents(
        holding: holding,
        sips: sips,
        schedulePeriods: periods,
        swpPeriods: swpPeriods,
        transactions: [],
      );

      expect(events.length, 4);
      expect(events[0], contains('Start on 01 Jan 2024 · ₹1,000'));
      expect(events[1], contains('Previous SIP period closed on 31 Dec 2024'));
      expect(events[2], contains('Period revised on 01 Jan 2025 · ₹2,000'));
      expect(events[3], contains('SWP started on 01 Jun 2025 · ₹500'));
    });
  });
}
