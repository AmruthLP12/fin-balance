import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:finbalance/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Profile Management Workflow & Validation', () {
    test('creates multiple profiles without artificial limit', () async {
      final initialCount = await db.profilesDao.countActiveProfiles();
      expect(initialCount, 1); // 1 seeded default profile ("My Profile")

      final p1 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Father'),
          relationship: Value('father'),
          colorHex: Value('#3B82F6'),
          description: Value('Retirement savings & pension'),
        ),
      );

      final p2 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Priya'),
          relationship: Value('spouse'),
          colorHex: Value('#EC4899'),
          description: Value('Joint investments'),
        ),
      );

      final p3 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Aarav'),
          relationship: Value('child'),
          colorHex: Value('#F59E0B'),
          description: Value('Higher education fund'),
        ),
      );

      expect(p1, greaterThan(1));
      expect(p2, greaterThan(p1));
      expect(p3, greaterThan(p2));

      final activeProfiles = await db.profilesDao.getAllProfiles();
      expect(activeProfiles.length, 4);
    });

    test('edits an existing profile and updates metadata', () async {
      final profileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Mother'),
          relationship: Value('mother'),
          colorHex: Value('#10B981'),
        ),
      );

      final existing = await db.profilesDao.getProfileById(profileId);
      expect(existing, isNotNull);
      expect(existing!.name, 'Mother');

      final updated = await db.profilesDao.updateProfile(
        FinancialProfilesCompanion(
          id: Value(profileId),
          name: const Value('Maa (Retirement)'),
          relationship: const Value('mother'),
          colorHex: const Value('#8B5CF6'),
          description: const Value('Updated pension details'),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );

      expect(updated, isTrue);

      final refreshed = await db.profilesDao.getProfileById(profileId);
      expect(refreshed!.name, 'Maa (Retirement)');
      expect(refreshed.colorHex, '#8B5CF6');
      expect(refreshed.description, 'Updated pension details');
    });

    test('designates default profile cleanly and clears other defaults',
        () async {
      final p1 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
          isDefault: Value(false),
        ),
      );

      await db.profilesDao.setDefaultProfile(p1);

      final def = await db.profilesDao.getDefaultProfile();
      expect(def, isNotNull);
      expect(def!.id, p1);
      expect(def.name, 'Spouse');

      // The initial default profile should no longer be default
      final initial = await db.profilesDao.getProfileById(1);
      expect(initial!.isDefault, isFalse);
    });

    test('archives and unarchives profiles while preserving data', () async {
      final p1 = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Child Fund'),
          relationship: Value('child'),
        ),
      );

      expect(await db.profilesDao.countActiveProfiles(), 2);

      // Archive profile
      await db.profilesDao.archiveProfile(p1);
      expect(await db.profilesDao.countActiveProfiles(), 1);

      // Active query excludes archived
      final activeList =
          await db.profilesDao.getAllProfiles(includeArchived: false);
      expect(activeList.any((p) => p.id == p1), isFalse);

      // Including archived returns all
      final allList =
          await db.profilesDao.getAllProfiles(includeArchived: true);
      expect(allList.any((p) => p.id == p1), isTrue);

      // Unarchive
      await db.profilesDao.unarchiveProfile(p1);
      expect(await db.profilesDao.countActiveProfiles(), 2);
    });

    test(
        'hasFinancialHistory accurately identifies profiles with recorded data',
        () async {
      final emptyProfileId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Empty Profile'),
          relationship: Value('other'),
        ),
      );

      // Fresh profile has no financial history
      expect(await db.profilesDao.hasFinancialHistory(emptyProfileId), isFalse);

      // Add a financial item (holding)
      final cat = await db.categoriesDao.getCategoriesByClassification('asset');
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(emptyProfileId),
          name: const Value('SBI Small Cap Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(cat.first.id),
          initialValuePaise: const Value(500000), // ₹5,000.00
          currentValuationPaise: const Value(540000),
        ),
      );

      // Profile now HAS financial history and should be protected from deletion
      expect(await db.profilesDao.hasFinancialHistory(emptyProfileId), isTrue);
    });

    test('strictly isolates assets and liabilities across multiple profiles',
        () async {
      final fatherId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Father'),
          relationship: Value('father'),
        ),
      );

      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
        ),
      );

      final assetCats =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final liabilityCats =
          await db.categoriesDao.getCategoriesByClassification('liability');
      final assetCat = assetCats.first;
      final liabilityCat = liabilityCats.first;

      // Add asset to Father
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(fatherId),
          name: const Value('Father Fixed Deposit'),
          itemType: const Value('asset'),
          subType: const Value('fixed_deposit'),
          categoryId: Value(assetCat.id),
          initialValuePaise: const Value(10000000), // ₹1,00,000
          currentValuationPaise: const Value(10000000),
        ),
      );

      // Add asset and liability to Spouse
      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(spouseId),
          name: const Value('Spouse PPF Account'),
          itemType: const Value('asset'),
          subType: const Value('ppf'),
          categoryId: Value(assetCat.id),
          initialValuePaise: const Value(15000000), // ₹1,50,000
          currentValuationPaise: const Value(15000000),
        ),
      );

      await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(spouseId),
          name: const Value('Spouse Education Loan'),
          itemType: const Value('liability'),
          subType: const Value('education_loan'),
          categoryId: Value(liabilityCat.id),
          initialValuePaise: const Value(20000000), // ₹2,00,000
          currentValuationPaise: const Value(18000000),
        ),
      );

      // Query Father's assets
      final fatherAssets = await db.financialItemsDao
          .getItemsByProfile(fatherId, itemType: 'asset');
      expect(fatherAssets.length, 1);
      expect(fatherAssets.first.name, 'Father Fixed Deposit');

      // Father has NO liabilities
      final fatherLiabilities = await db.financialItemsDao
          .getItemsByProfile(fatherId, itemType: 'liability');
      expect(fatherLiabilities, isEmpty);

      // Query Spouse's assets
      final spouseAssets = await db.financialItemsDao
          .getItemsByProfile(spouseId, itemType: 'asset');
      expect(spouseAssets.length, 1);
      expect(spouseAssets.first.name, 'Spouse PPF Account');

      // Query Spouse's liabilities
      final spouseLiabilities = await db.financialItemsDao
          .getItemsByProfile(spouseId, itemType: 'liability');
      expect(spouseLiabilities.length, 1);
      expect(spouseLiabilities.first.name, 'Spouse Education Loan');

      // Verify Default profile (id: 1) has 0 assets and 0 liabilities
      final defaultAssets =
          await db.financialItemsDao.getItemsByProfile(1, itemType: 'asset');
      expect(defaultAssets, isEmpty);
    });
  });
}
