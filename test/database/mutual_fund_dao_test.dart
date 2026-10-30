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

  group('MutualFundDao Scheme Caching & Search', () {
    test('upserts scheme master records and searches locally by code and name',
        () async {
      await db.mutualFundDao.upsertSchemes([
        const MutualFundSchemesCompanion(
          schemeCode: Value(125497),
          schemeName: Value('SBI SMALL CAP FUND - Direct Plan - Growth'),
          fundHouse: Value('SBI Mutual Fund'),
          planType: Value('Direct'),
          optionType: Value('Growth'),
          latestNavMicroPaise: Value(200184600), // ₹200.1846
        ),
        const MutualFundSchemesCompanion(
          schemeCode: Value(122639),
          schemeName: Value('Parag Parikh Flexi Cap Fund - Direct Growth'),
          fundHouse: Value('PPFAS Mutual Fund'),
          planType: Value('Direct'),
          optionType: Value('Growth'),
          latestNavMicroPaise: Value(75450000), // ₹75.45
        ),
      ]);

      // Search by text
      final searchParag =
          await db.mutualFundDao.searchLocalSchemes('Parag Parikh');
      expect(searchParag.length, equals(1));
      expect(searchParag.first.schemeCode, equals(122639));

      // Search by scheme code
      final searchCode = await db.mutualFundDao.searchLocalSchemes('125497');
      expect(searchCode.length, equals(1));
      expect(searchCode.first.fundHouse, equals('SBI Mutual Fund'));
    });

    test('toggles and watches favorite schemes', () async {
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: Value(100121),
          schemeName: Value('HDFC Balanced Advantage Fund'),
          isFavorite: Value(false),
        ),
      );

      // Bookmark
      await db.mutualFundDao.setFavorite(100121, true);

      final favorites = await db.mutualFundDao.watchFavoriteSchemes().first;
      expect(favorites.length, equals(1));
      expect(favorites.first.schemeCode, equals(100121));

      // Unbookmark
      await db.mutualFundDao.setFavorite(100121, false);
      final unbookmarked = await db.mutualFundDao.watchFavoriteSchemes().first;
      expect(unbookmarked, isEmpty);
    });
  });

  group('NavHistory Caching & Holdings Valuation Sync', () {
    test(
        'upserts historical NAV datapoints enforcing uniqueness on (schemeCode, navDate)',
        () async {
      await db.mutualFundDao.upsertScheme(
        const MutualFundSchemesCompanion(
          schemeCode: Value(125497),
          schemeName: Value('SBI Small Cap Fund'),
        ),
      );

      final date1 = DateTime.utc(2026, 10, 28);
      final date2 = DateTime.utc(2026, 10, 29);

      await db.mutualFundDao.upsertNavRecords(125497, [
        NavHistoryCompanion(
          schemeCode: const Value(125497),
          navDate: Value(date1),
          navMicroPaise: const Value(199500000), // ₹199.50
        ),
        NavHistoryCompanion(
          schemeCode: const Value(125497),
          navDate: Value(date2),
          navMicroPaise: const Value(200184600), // ₹200.1846
        ),
      ]);

      final history = await db.mutualFundDao.getNavHistory(125497);
      expect(history.length, equals(2));

      // Re-upsert on date2 with corrected NAV (should update, not duplicate)
      await db.mutualFundDao.upsertNavRecords(125497, [
        NavHistoryCompanion(
          schemeCode: const Value(125497),
          navDate: Value(date2),
          navMicroPaise: const Value(200250000), // updated ₹200.25
        ),
      ]);

      final updatedHistory = await db.mutualFundDao.getNavHistory(125497);
      expect(updatedHistory.length, equals(2));
      expect(updatedHistory.first.navMicroPaise, equals(200250000));
    });

    test(
        'syncHoldingsValuation updates portfolio valuations across multiple profiles',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;
      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
        ),
      );

      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');

      // 1. Profile 1 holds 50 units of scheme 125497
      final selfItemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('SBI Small Cap (Self)'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
          externalCode: const Value('125497'),
          unitCountMicroUnits:
              Value(FinancialPrecision.unitsToMicroUnits(50.0)), // 50 units
          currentValuationPaise: const Value(0),
        ),
      );

      // 2. Profile 2 (Spouse) holds 20 units of scheme 125497
      final spouseItemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(spouseId),
          name: const Value('SBI Small Cap (Spouse)'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
          externalCode: const Value('125497'),
          unitCountMicroUnits:
              Value(FinancialPrecision.unitsToMicroUnits(20.0)), // 20 units
          currentValuationPaise: const Value(0),
        ),
      );

      // 3. New NAV arrives: ₹200.00 = 200,000,000 micro-paise
      // Expected valuation Self (50 units * ₹200) = ₹10,000 = 1,000,000 paise
      // Expected valuation Spouse (20 units * ₹200) = ₹4,000 = 400,000 paise
      final syncDate = DateTime.utc(2026, 10, 30);
      final updatedCount = await db.mutualFundDao.syncHoldingsValuation(
        schemeCode: 125497,
        latestNavMicroPaise: FinancialPrecision.navToMicroPaise(200.0),
        navDate: syncDate,
      );

      expect(updatedCount, equals(2));

      // Verify Self item
      final selfItem = await db.financialItemsDao.getItemById(selfItemId);
      expect(selfItem!.currentValuationPaise, equals(1000000)); // ₹10,000

      // Verify Spouse item
      final spouseItem = await db.financialItemsDao.getItemById(spouseItemId);
      expect(spouseItem!.currentValuationPaise, equals(400000)); // ₹4,000

      // Verify ValuationHistory entries created for both
      final selfVal = await db.valuationsDao.getLatestValuation(selfItemId);
      final spouseVal = await db.valuationsDao.getLatestValuation(spouseItemId);

      expect(selfVal, isNotNull);
      expect(selfVal!.valuationPaise, equals(1000000));
      expect(spouseVal, isNotNull);
      expect(spouseVal!.valuationPaise, equals(400000));
    });
  });
}

