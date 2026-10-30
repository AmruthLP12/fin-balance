import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:finbalance/database/precision/financial_precision.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Mutual Fund Holdings & Cross-Profile Isolation', () {
    test('adds mutual fund holding to a profile and verifies ownership',
        () async {
      // 1. Setup profile
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Aarav'),
          relationship: Value('child'),
        ),
      );

      final categories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final mfCategory = categories.first;

      // 2. Add holding via FinancialItems
      const schemeCode = 125497;
      const navMicroPaise = 200184600; // ₹200.1846
      final unitsMicro = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 1000000, // ₹10,000
        navMicroPaise: navMicroPaise,
      );
      final valuationPaise = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: unitsMicro,
        navMicroPaise: navMicroPaise,
      );

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(profileId),
          name: const Value('SBI SMALL CAP FUND - Direct Plan - Growth'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(mfCategory.id),
          externalCode: Value(schemeCode.toString()),
          initialValuePaise: const Value(1000000),
          currentValuationPaise: Value(valuationPaise),
          unitCountMicroUnits: Value(unitsMicro),
        ),
      );

      // Record transaction
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: Value(profileId),
          transactionType: const Value('investment_purchase'),
          categoryId: Value(mfCategory.id),
          financialItemId: Value(itemId),
          transactionDate: Value(DateTime.now().toUtc()),
          amountPaise: const Value(1000000),
          unitsMicroUnits: Value(unitsMicro),
          unitPriceMicroPaise: const Value(navMicroPaise),
        ),
      );

      // 3. Verify Aarav holds this mutual fund
      final aaravAssets = await db.financialItemsDao
          .getItemsByProfile(profileId, itemType: 'asset');
      expect(aaravAssets.length, 1);
      expect(
          aaravAssets.first.name, 'SBI SMALL CAP FUND - Direct Plan - Growth');
      expect(aaravAssets.first.externalCode, '125497');
      expect(aaravAssets.first.initialValuePaise, 1000000);
      expect(aaravAssets.first.unitCountMicroUnits, unitsMicro);

      // 4. Verify default profile (id: 1) has 0 holdings
      final defaultAssets =
          await db.financialItemsDao.getItemsByProfile(1, itemType: 'asset');
      expect(defaultAssets, isEmpty);

      // 5. Verify transactions belong to Aarav
      final txs =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txs.length, 1);
      expect(txs.first.financialItemId, itemId);
      expect(txs.first.amountPaise, 1000000);

      // Default profile has 0 transactions
      final defaultTxs =
          await db.transactionsDao.getRecentTransactionsForProfile(1);
      expect(defaultTxs, isEmpty);
    });

    test(
        'aggregates multiple investments into the same mutual fund scheme for a profile',
        () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Priya'),
          relationship: Value('spouse'),
        ),
      );

      final categories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final mfCategory = categories.first;

      const schemeCode = '122639';
      const nav1MicroPaise = 75000000; // ₹75.00
      final units1 = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 500000, // ₹5,000
        navMicroPaise: nav1MicroPaise,
      );

      // First purchase
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(profileId),
          name: const Value('Parag Parikh Flexi Cap Fund - Direct Growth'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(mfCategory.id),
          externalCode: const Value(schemeCode),
          initialValuePaise: const Value(500000),
          currentValuationPaise: const Value(500000),
          unitCountMicroUnits: Value(units1),
        ),
      );

      // Second purchase in the same fund (SIP or top-up) at NAV ₹80.00
      const nav2MicroPaise = 80000000; // ₹80.00
      final units2 = FinancialPrecision.calculateUnitsPurchased(
        amountPaise: 500000, // ₹5,000
        navMicroPaise: nav2MicroPaise,
      );

      final existing = await db.financialItemsDao
          .getItemByExternalCode(profileId, schemeCode);
      expect(existing, isNotNull);

      final totalUnits = existing!.unitCountMicroUnits + units2;
      final totalInvested = existing.initialValuePaise + 500000;
      final currentValuation = FinancialPrecision.calculateValuationPaise(
        unitCountMicroUnits: totalUnits,
        navMicroPaise: nav2MicroPaise,
      );

      await db.financialItemsDao.updateItem(
        existing.copyWith(
          initialValuePaise: totalInvested,
          currentValuationPaise: currentValuation,
          unitCountMicroUnits: totalUnits,
          updatedAt: DateTime.now().toUtc(),
        ),
      );

      // Verify aggregated holding
      final updated = await db.financialItemsDao.getItemById(itemId);
      expect(updated, isNotNull);
      expect(updated!.initialValuePaise, 1000000); // ₹10,000
      expect(updated.unitCountMicroUnits, totalUnits);
      expect(updated.currentValuationPaise,
          greaterThan(1000000)); // Value increased due to NAV ₹80
    });
  });
}
