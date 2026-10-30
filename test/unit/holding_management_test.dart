import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  group('Mutual Fund Holding & Transaction Management', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());

      // Create a second profile (Primary profile 1 already created on boot)
      await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: drift.Value('Spouse Portfolio'),
          relationship: drift.Value('Spouse'),
        ),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Add holding with purchase NAV, units, and date', () async {
      final purchaseDate = DateTime.utc(2026, 10, 15);
      const amountRupees = 15000.0;
      const purchaseNav = 150.0; // 15,000 / 150 = 100 units

      final amountPaise = FinancialPrecision.rupeesToPaise(amountRupees);
      final navMicro = FinancialPrecision.navToMicroPaise(purchaseNav);
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: amountPaise,
        navMicroPaise: navMicro,
      );

      // Insert holding
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: const drift.Value(1),
          name: const drift.Value('Parag Parikh Flexi Cap Fund'),
          itemType: const drift.Value('asset'),
          subType: const drift.Value('mutual_fund'),
          categoryId: const drift.Value(1),
          externalCode: const drift.Value('122639'),
          initialValuePaise: drift.Value(amountPaise),
          currentValuationPaise: drift.Value(amountPaise),
          unitCountMicroUnits: drift.Value(unitsMicro),
          startDate: drift.Value(purchaseDate),
          notes: const drift.Value('Initial SIP lumpsum'),
        ),
      );

      // Record transaction
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: const drift.Value(1),
          transactionType: const drift.Value('investment_purchase'),
          categoryId: const drift.Value(1),
          financialItemId: drift.Value(itemId),
          transactionDate: drift.Value(purchaseDate),
          amountPaise: drift.Value(amountPaise),
          unitsMicroUnits: drift.Value(unitsMicro),
          unitPriceMicroPaise: drift.Value(navMicro),
          notes: const drift.Value('Initial purchase'),
        ),
      );

      // Verify holding
      final holding = await db.financialItemsDao.getItemById(itemId);
      expect(holding, isNotNull);
      expect(holding!.initialValuePaise, equals(1500000));
      expect(holding.unitCountMicroUnits, equals(100000000)); // 100.0 units
      expect(holding.startDate!.isAtSameMomentAs(purchaseDate), isTrue);

      // Verify transaction linked
      final txs = await db.transactionsDao.getTransactionsByItem(1, itemId);
      expect(txs.length, equals(1));
      expect(txs.first.amountPaise, equals(1500000));
      expect(txs.first.unitPriceMicroPaise, equals(150000000)); // Purchase NAV
    });

    test('Edit holding updates existing record without creating duplicates',
        () async {
      // 1. Create initial holding
      final itemId = await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          id: drift.Value(10),
          profileId: drift.Value(1),
          name: drift.Value('HDFC Top 100'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('100122'),
          initialValuePaise: drift.Value(1000000), // ₹10,000
          currentValuationPaise: drift.Value(1000000),
          unitCountMicroUnits: drift.Value(50000000), // 50 units
        ),
      );

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          id: const drift.Value(100),
          profileId: const drift.Value(1),
          transactionType: const drift.Value('investment_purchase'),
          categoryId: const drift.Value(1),
          financialItemId: const drift.Value(10),
          transactionDate: drift.Value(DateTime.utc(2026, 8, 1)),
          amountPaise: const drift.Value(1000000),
          unitsMicroUnits: const drift.Value(50000000),
          unitPriceMicroPaise: const drift.Value(200000000), // ₹200.00
        ),
      );

      // 2. Perform Edit: User corrects units to 60.0 and amount to ₹12,000
      final item = await db.financialItemsDao.getItemById(itemId);
      expect(item, isNotNull);

      const updatedAmountPaise = 1200000;
      const updatedUnitsMicro = 60000000;
      final updatedDate = DateTime.utc(2026, 9, 1);

      await db.financialItemsDao.updateItem(
        item!.copyWith(
          initialValuePaise: updatedAmountPaise,
          unitCountMicroUnits: updatedUnitsMicro,
          startDate: drift.Value(updatedDate),
          notes: const drift.Value('Corrected statement figures'),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      final primaryTx =
          await db.transactionsDao.getPrimaryTransactionForItem(1, itemId);
      expect(primaryTx, isNotNull);

      await db.transactionsDao.updateTransaction(
        primaryTx!.copyWith(
          amountPaise: updatedAmountPaise,
          unitsMicroUnits: const drift.Value(updatedUnitsMicro),
          transactionDate: updatedDate,
          notes: const drift.Value('Corrected statement figures'),
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      // 3. Verify exactly 1 holding and 1 transaction exists (no duplicates)
      final allHoldings = await db.financialItemsDao.getItemsByProfile(1);
      expect(allHoldings.length, equals(1));
      expect(allHoldings.first.id, equals(10));
      expect(allHoldings.first.initialValuePaise, equals(1200000));
      expect(allHoldings.first.unitCountMicroUnits, equals(60000000));

      final allTxs = await db.transactionsDao.getTransactionsByItem(1, itemId);
      expect(allTxs.length, equals(1));
      expect(allTxs.first.id, equals(100));
      expect(allTxs.first.amountPaise, equals(1200000));
      expect(allTxs.first.unitsMicroUnits, equals(60000000));
    });

    test('Two-way calculation: Amount to Units and Units to Amount', () {
      const navRupees = 250.0;
      final navMicro = FinancialPrecision.navToMicroPaise(navRupees);

      // Amount = ₹50,000 -> Units = 200.0
      final amountPaise = FinancialPrecision.rupeesToPaise(50000.0);
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: amountPaise,
        navMicroPaise: navMicro,
      );
      final calculatedUnits = FinancialPrecision.microUnitsToUnits(unitsMicro);
      expect(calculatedUnits, equals(200.0));

      // Units = 150.5 -> Amount = 150.5 * 250 = ₹37,625
      const manualUnits = 150.5;
      const calculatedAmount = manualUnits * navRupees;
      expect(calculatedAmount, equals(37625.0));
    });

    test(
        'Multiple purchases of same scheme aggregate units while logging distinct transactions',
        () async {
      // First purchase: ₹10,000 for 100 units at ₹100
      final itemId = await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          profileId: drift.Value(1),
          name: drift.Value('Nippon India Small Cap'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('118778'),
          initialValuePaise: drift.Value(1000000), // ₹10,000
          currentValuationPaise: drift.Value(1000000),
          unitCountMicroUnits: drift.Value(100000000), // 100 units
        ),
      );

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: const drift.Value(1),
          transactionType: const drift.Value('investment_purchase'),
          categoryId: const drift.Value(1),
          financialItemId: drift.Value(itemId),
          transactionDate: drift.Value(DateTime.utc(2026, 8, 1)),
          amountPaise: const drift.Value(1000000),
          unitsMicroUnits: const drift.Value(100000000),
          unitPriceMicroPaise: const drift.Value(100000000),
        ),
      );

      // Second purchase: ₹20,000 for 160 units at ₹125
      final existing = await db.financialItemsDao.getItemById(itemId);
      await db.financialItemsDao.updateItem(
        existing!.copyWith(
          initialValuePaise: existing.initialValuePaise + 2000000,
          unitCountMicroUnits: existing.unitCountMicroUnits + 160000000,
          currentValuationPaise: existing.currentValuationPaise + 2000000,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: const drift.Value(1),
          transactionType: const drift.Value('investment_purchase'),
          categoryId: const drift.Value(1),
          financialItemId: drift.Value(itemId),
          transactionDate: drift.Value(DateTime.utc(2026, 9, 1)),
          amountPaise: const drift.Value(2000000),
          unitsMicroUnits: const drift.Value(160000000),
          unitPriceMicroPaise: const drift.Value(125000000),
        ),
      );

      // Verify aggregate holding
      final updatedHolding = await db.financialItemsDao.getItemById(itemId);
      expect(updatedHolding!.initialValuePaise, equals(3000000)); // ₹30,000
      expect(
          updatedHolding.unitCountMicroUnits, equals(260000000)); // 260 units

      // Verify 2 distinct transaction records preserved
      final txs = await db.transactionsDao.getTransactionsByItem(1, itemId);
      expect(txs.length, equals(2));
      expect(txs[0].unitPriceMicroPaise, equals(100000000)); // Purchase 1 NAV
      expect(txs[1].unitPriceMicroPaise, equals(125000000)); // Purchase 2 NAV
    });

    test(
        'Multiple profiles own the same scheme independently without data leakage',
        () async {
      // Profile 1 buys 100 units
      await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          profileId: drift.Value(1),
          name: drift.Value('SBI Bluechip Fund'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('119598'),
          initialValuePaise: drift.Value(1000000),
          unitCountMicroUnits: drift.Value(100000000), // 100 units
        ),
      );

      // Profile 2 (Spouse) buys 250 units
      await db.financialItemsDao.insertItem(
        const FinancialItemsCompanion(
          profileId: drift.Value(2),
          name: drift.Value('SBI Bluechip Fund'),
          itemType: drift.Value('asset'),
          subType: drift.Value('mutual_fund'),
          categoryId: drift.Value(1),
          externalCode: drift.Value('119598'),
          initialValuePaise: drift.Value(2500000),
          unitCountMicroUnits: drift.Value(250000000), // 250 units
        ),
      );

      final p1Items = await db.financialItemsDao.getItemsByProfile(1);
      final p2Items = await db.financialItemsDao.getItemsByProfile(2);

      expect(p1Items.length, equals(1));
      expect(p1Items.first.unitCountMicroUnits, equals(100000000));

      expect(p2Items.length, equals(1));
      expect(p2Items.first.unitCountMicroUnits, equals(250000000));
    });
  });
}
