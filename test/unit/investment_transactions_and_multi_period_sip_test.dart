import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/calculations/financial_calculator.dart';
import 'package:finbalance/core/calculations/investment_lifecycle_summary.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
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

    // 3. Seed mutual fund scheme
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
  });

  tearDown(() async {
    await db.close();
  });

  group('Multi-Type Investment Transactions & Charges Unit Tests', () {
    test(
        'One-time purchase increases units, updates cost basis including charges',
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
          initialValuePaise: const drift.Value(0),
          unitCountMicroUnits: const drift.Value(0),
          currentValuationPaise: const drift.Value(0),
        ),
      );

      // Record ₹10,000 purchase with ₹50 charges at ₹75 NAV (133.3333 units)
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 1000000, // ₹10,000
        navMicroPaise: 75000000, // ₹75.00
      );

      final txId = await db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: 'investment_purchase',
        transactionDate: DateTime.utc(2026, 1, 15),
        amountPaise: 1000000,
        chargesPaise: 5000, // ₹50 charges
        unitsMicroUnits: unitsMicro,
        unitPriceMicroPaise: 75000000,
        notes: 'Initial lump sum',
      );

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx, isNotNull);
      expect(tx!.amountPaise, 1000000);
      expect(tx.chargesPaise, 5000);
      expect(tx.netAmountPaise, 1005000); // Outflow = amount + charges

      // Verify holding was updated atomically
      final holding = await db.financialItemsDao.getItemById(holdingId);
      expect(
          holding!.initialValuePaise, 1005000); // Cost basis includes charges
      expect(holding.unitCountMicroUnits, unitsMicro);
      expect(holding.currentValuationPaise, inInclusiveRange(999998, 1000002));
    });

    test('IDCW Reinvestment increases units without external cash outflow',
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
          initialValuePaise: const drift.Value(1000000), // ₹10,000
          unitCountMicroUnits: const drift.Value(133333333), // 133.3333 units
          currentValuationPaise: const drift.Value(1000000),
        ),
      );

      // Reinvest ₹500 dividend into units at ₹75 NAV (6.6666 units)
      final reinvestUnits = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 50000,
        navMicroPaise: 75000000,
      );

      final txId = await db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: 'dividend_reinvestment',
        transactionDate: DateTime.utc(2026, 3, 1),
        amountPaise: 50000,
        chargesPaise: 0,
        unitsMicroUnits: reinvestUnits,
        unitPriceMicroPaise: 75000000,
        notes: 'IDCW Reinvestment',
      );

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx!.netAmountPaise, 0); // External cash flow is 0

      final holding = await db.financialItemsDao.getItemById(holdingId);
      expect(holding!.unitCountMicroUnits, 133333333 + reinvestUnits);
      expect(holding.initialValuePaise,
          1000000); // Invested capital from pocket unchanged!
    });

    test('IDCW Payout records cash income without altering units', () async {
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
          unitCountMicroUnits: const drift.Value(133333333),
          currentValuationPaise: const drift.Value(1000000),
        ),
      );

      final txId = await db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: 'dividend_payout',
        transactionDate: DateTime.utc(2026, 4, 1),
        amountPaise: 80000, // ₹800 dividend
        chargesPaise: 500, // ₹5 TDS
      );

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx!.netAmountPaise, 79500); // Inflow = amount - charges

      final holding = await db.financialItemsDao.getItemById(holdingId);
      expect(holding!.unitCountMicroUnits, 133333333); // Units unchanged!
    });

    test(
        'Redemption reduces units, deducts charges from proceeds, and blocks over-redemption',
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
          initialValuePaise: const drift.Value(1000000), // ₹10,000
          unitCountMicroUnits: const drift.Value(100000000), // 100.0000 units
          currentValuationPaise: const drift.Value(7500000), // ₹7,500
        ),
      );

      // Attempting to redeem 150 units must throw ArgumentError
      expect(
        () => db.transactionsDao.recordInvestmentTransaction(
          profileId: profileId,
          financialItemId: holdingId,
          categoryId: categoryId,
          transactionType: 'redemption',
          transactionDate: DateTime.utc(2026, 5, 1),
          amountPaise: 1125000,
          unitsMicroUnits: 150000000, // 150 units > 100 available
        ),
        throwsArgumentError,
      );

      // Valid redemption: redeem 40 units at ₹75 (₹3,000 proceeds with ₹20 exit load)
      final txId = await db.transactionsDao.recordInvestmentTransaction(
        profileId: profileId,
        financialItemId: holdingId,
        categoryId: categoryId,
        transactionType: 'redemption',
        transactionDate: DateTime.utc(2026, 5, 1),
        amountPaise: 300000,
        chargesPaise: 2000,
        unitsMicroUnits: 40000000,
        unitPriceMicroPaise: 75000000,
      );

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx!.netAmountPaise, 298000); // Inflow = amount - charges

      final updated = await db.financialItemsDao.getItemById(holdingId);
      expect(updated!.unitCountMicroUnits,
          60000000); // 100 - 40 = 60 units remaining
      expect(updated.currentValuationPaise,
          450000); // 60 * ₹75 = ₹4,500 = 450,000 paise
    });

    test('Switch Out and Switch In link two holdings atomically', () async {
      // Source Holding
      final sourceId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('PPFAS Liquid Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('100001'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(500000),
          unitCountMicroUnits: const drift.Value(50000000), // 50 units at ₹10
          currentValuationPaise: const drift.Value(500000),
        ),
      );

      // Destination Holding
      final destId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('122639'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(0),
          unitCountMicroUnits: const drift.Value(0),
          currentValuationPaise: const drift.Value(0),
        ),
      );

      // Switch ₹2,000 (20 units of source at ₹10) into dest at ₹50 (40 units)
      await db.transactionsDao.recordSwitchBetweenHoldings(
        profileId: profileId,
        sourceItemId: sourceId,
        destItemId: destId,
        categoryId: categoryId,
        transactionDate: DateTime.utc(2026, 6, 1),
        switchAmountPaise: 200000,
        chargesPaise: 1000, // ₹10 switch fee
        sourceUnitsMicroUnits: 20000000,
        sourceNavMicroPaise: 10000000,
        destUnitsMicroUnits: 39800000,
        destNavMicroPaise: 50000000,
        notes: 'Switch from Liquid to Flexi Cap',
      );

      final sourceTxs =
          await db.transactionsDao.getTransactionsByItem(profileId, sourceId);
      final destTxs =
          await db.transactionsDao.getTransactionsByItem(profileId, destId);

      expect(sourceTxs.length, 1);
      expect(destTxs.length, 1);
      expect(sourceTxs.first.transactionType, 'switch_out');
      expect(destTxs.first.transactionType, 'switch_in');
      expect(sourceTxs.first.linkedTransactionId, destTxs.first.id);
      expect(destTxs.first.linkedTransactionId, sourceTxs.first.id);

      final updatedSource = await db.financialItemsDao.getItemById(sourceId);
      final updatedDest = await db.financialItemsDao.getItemById(destId);
      expect(
          updatedSource!.unitCountMicroUnits, 30000000); // 50 - 20 = 30 units
      expect(updatedDest!.unitCountMicroUnits, 39800000);
    });
  });

  group('Multiple SIP Schedule Periods Unit Tests', () {
    test(
        'A holding supports multiple schedule periods with amount revisions and closed dates',
        () async {
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: drift.Value(100050),
          schemeName: drift.Value('HDFC Top 100 Fund Direct Growth'),
          fundHouse: drift.Value('HDFC Mutual Fund'),
        ),
      );

      final holdingId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('HDFC Top 100 Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: drift.Value(categoryId),
          externalCode: const drift.Value('100050'),
          status: const drift.Value('active'),
          initialValuePaise: const drift.Value(0),
          unitCountMicroUnits: const drift.Value(0),
          currentValuationPaise: const drift.Value(0),
        ),
      );

      // Period 1: ₹500 monthly from Jan 1, 2026
      final sipId = await db.sipsDao.createSipWithPeriod(
        profileId: profileId,
        schemeCode: 100050,
        name: 'HDFC Monthly SIP',
        startDate: DateTime.utc(2026, 1, 1),
        amountPaise: 50000,
        deductionDay: 1,
        frequency: 'monthly',
        financialItemId: holdingId,
      );

      final initialPeriods = await db.sipsDao.getSchedulePeriods(sipId);
      expect(initialPeriods.length, 1);
      expect(initialPeriods.first.amountPaise, 50000);
      expect(initialPeriods.first.status, 'active');

      // Add Period 2: revised to ₹1,000 monthly effective May 1, 2026
      final period2Id = await db.sipsDao.addSchedulePeriod(
        sipPlanId: sipId,
        effectiveFrom: DateTime.utc(2026, 5, 1),
        amountPaise: 100000,
        deductionDay: 1,
        frequency: 'monthly',
      );

      expect(period2Id, isNotNull);

      final updatedPeriods = await db.sipsDao.getSchedulePeriods(sipId);
      expect(updatedPeriods.length, 2);

      // Period 1 must be superseded/closed on April 30, 2026
      final p1 =
          updatedPeriods.firstWhere((p) => p.id == initialPeriods.first.id);
      expect(p1.status, 'superseded');
      expect(p1.effectiveTo!.year, 2026);
      expect(p1.effectiveTo!.month, 4);
      expect(p1.effectiveTo!.day, 30);

      // Period 2 must be active from May 1, 2026
      final p2 = updatedPeriods.firstWhere((p) => p.id == period2Id);
      expect(p2.status, 'active');
      expect(p2.effectiveFrom.year, 2026);
      expect(p2.effectiveFrom.month, 5);
      expect(p2.effectiveFrom.day, 1);
      expect(p2.amountPaise, 100000);
    });
  });

  group('Lifecycle Narrative & XIRR with Multi-Types Tests', () {
    test(
        'InvestmentLifecycleSummary correctly narrates multi-period SIP and transactions',
        () async {
      final holding = FinancialItem(
        id: 10,
        profileId: profileId,
        name: 'SBI Bluechip Fund',
        itemType: 'asset',
        subType: 'mutual_fund',
        categoryId: categoryId,
        status: 'active',
        initialValuePaise: 250000, // ₹2,500
        currentValuationPaise: 320000,
        unitCountMicroUnits: 30000000,
        startDate: DateTime.utc(2026, 1, 1),
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 11, 1),
      );

      final sips = [
        SipPlan(
          id: 5,
          profileId: profileId,
          schemeCode: 100020,
          name: 'SBI Bluechip Monthly SIP',
          startDate: DateTime.utc(2026, 1, 1),
          status: 'active',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 11, 1),
        ),
      ];

      final periods = [
        SipSchedulePeriod(
          id: 1,
          sipPlanId: 5,
          effectiveFrom: DateTime.utc(2026, 1, 1),
          effectiveTo: DateTime.utc(2026, 4, 30),
          amountPaise: 50000,
          deductionDay: 1,
          frequency: 'monthly',
          status: 'superseded',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 4, 30),
        ),
        SipSchedulePeriod(
          id: 2,
          sipPlanId: 5,
          effectiveFrom: DateTime.utc(2026, 5, 1),
          amountPaise: 100000,
          deductionDay: 1,
          frequency: 'monthly',
          status: 'active',
          createdAt: DateTime.utc(2026, 5, 1),
          updatedAt: DateTime.utc(2026, 5, 1),
        ),
      ];

      final transactions = [
        Transaction(
          id: 1,
          profileId: profileId,
          transactionType: 'sip_investment',
          categoryId: categoryId,
          transactionDate: DateTime.utc(2026, 1, 1),
          amountPaise: 50000,
          chargesPaise: 0,
          source: 'manual',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        ),
        Transaction(
          id: 2,
          profileId: profileId,
          transactionType: 'dividend_payout',
          categoryId: categoryId,
          transactionDate: DateTime.utc(2026, 3, 1),
          amountPaise: 15000,
          chargesPaise: 0,
          source: 'manual',
          createdAt: DateTime.utc(2026, 3, 1),
          updatedAt: DateTime.utc(2026, 3, 1),
        ),
      ];

      final narrative = InvestmentLifecycleSummary.generateSummary(
        holding: holding,
        sips: sips,
        schedulePeriods: periods,
        transactions: transactions,
      );

      expect(narrative, contains('Start on 01 Jan 2026 · ₹500.00'));
      expect(narrative, contains('Period revised on 01 May 2026 · ₹1,000.00'));
      expect(narrative, contains('Dividend payout on 01 Mar 2026 · ₹150.00'));
    });

    test(
        'FinancialCalculator XIRR correctly factors in charges and cash distributions',
        () {
      final txs = [
        Transaction(
          id: 1,
          profileId: 1,
          transactionType: 'investment_purchase',
          categoryId: 1,
          transactionDate: DateTime(2025, 1, 1),
          amountPaise: 1000000, // ₹10,000
          chargesPaise: 5000, // ₹50 charges -> Outflow is ₹10,050
          source: 'manual',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
        Transaction(
          id: 2,
          profileId: 1,
          transactionType: 'dividend_payout',
          categoryId: 1,
          transactionDate: DateTime(2025, 7, 1),
          amountPaise: 100000, // ₹1,000 dividend payout inflow
          chargesPaise: 0,
          source: 'manual',
          createdAt: DateTime(2025, 7, 1),
          updatedAt: DateTime(2025, 7, 1),
        ),
      ];

      // Terminal valuation at ₹12,000 on Jan 1, 2026
      final xirr = FinancialCalculator.calculateHoldingXirr(
        transactions: txs,
        currentValuationPaise: 1200000,
        valuationDate: DateTime(2026, 1, 1),
      );

      expect(xirr, isNotNull);
      // Growth from ~₹10,050 to ₹1,000 dividend + ₹12,000 terminal in 1 year is approx ~29-30%
      expect(xirr!, greaterThan(25.0));
      expect(xirr, lessThan(35.0));
    });
  });
}
