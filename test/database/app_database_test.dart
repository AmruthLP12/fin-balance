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

  group('Multi-Profile Management & Initialization', () {
    test(
        'seeds default profile and active_profile_id on fresh database creation',
        () async {
      final defaultProfile = await db.profilesDao.getDefaultProfile();
      expect(defaultProfile, isNotNull);
      expect(defaultProfile!.name, equals('My Profile'));
      expect(defaultProfile.relationship, equals('self'));
      expect(defaultProfile.isDefault, isTrue);
      expect(defaultProfile.isArchived, isFalse);

      final activeProfileSetting =
          await db.appSettingsDao.getSetting('active_profile_id');
      expect(activeProfileSetting, equals(defaultProfile.id.toString()));

      // Seeded default categories should be global (profileId is null)
      final categories = await db.categoriesDao.watchAllCategories().first;
      expect(categories, isNotEmpty);
      expect(categories.every((c) => c.profileId == null), isTrue);
    });

    test('creates multiple profiles without artificial limits', () async {
      final fatherId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Father'),
          relationship: Value('father'),
          colorHex: Value('#3B82F6'),
        ),
      );

      final motherId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Mother'),
          relationship: Value('mother'),
          colorHex: Value('#EC4899'),
        ),
      );

      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
          colorHex: Value('#8B5CF6'),
        ),
      );

      expect(fatherId, isPositive);
      expect(motherId, isPositive);
      expect(spouseId, isPositive);

      final allActive = await db.profilesDao.getAllProfiles();
      // Default profile + 3 new profiles = 4 profiles
      expect(allActive.length, equals(4));
      expect(allActive.any((p) => p.name == 'Father'), isTrue);
      expect(allActive.any((p) => p.name == 'Mother'), isTrue);
      expect(allActive.any((p) => p.name == 'Spouse'), isTrue);
    });

    test('switches active profile and updates default profile', () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;

      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
        ),
      );

      // Set spouse as new default profile
      await db.profilesDao.setDefaultProfile(spouseId);

      final newDefault = await db.profilesDao.getDefaultProfile();
      expect(newDefault, isNotNull);
      expect(newDefault!.id, equals(spouseId));
      expect(newDefault.name, equals('Spouse'));

      // Check that former default profile is no longer default
      final oldDefault = await db.profilesDao.getProfileById(defaultProfile.id);
      expect(oldDefault!.isDefault, isFalse);

      // Persist active profile in settings
      await db.appSettingsDao
          .setSetting('active_profile_id', spouseId.toString());
      expect(await db.appSettingsDao.getSetting('active_profile_id'),
          equals(spouseId.toString()));
    });

    test('archives profile without deleting financial history', () async {
      final brotherId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Brother'),
          relationship: Value('other'),
        ),
      );

      await db.profilesDao.archiveProfile(brotherId);

      // Not in active profiles
      final activeProfiles = await db.profilesDao.getAllProfiles();
      expect(activeProfiles.any((p) => p.id == brotherId), isFalse);

      // Present when querying with includeArchived: true
      final allProfiles =
          await db.profilesDao.getAllProfiles(includeArchived: true);
      expect(allProfiles.any((p) => p.id == brotherId), isTrue);

      // Unarchive
      await db.profilesDao.unarchiveProfile(brotherId);
      final unarchivedList = await db.profilesDao.getAllProfiles();
      expect(unarchivedList.any((p) => p.id == brotherId), isTrue);
    });
  });

  group('Financial Accounts & Profile Scoping', () {
    test(
        'strictly isolates accounts by profile and calculates liquidity correctly',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;

      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
        ),
      );

      // Account for Profile 1 (Self)
      final selfAccountId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Self HDFC Bank'),
          accountType: const Value('bank'),
          openingBalancePaise:
              Value(FinancialPrecision.rupeesToPaise(50000.0)), // ₹50,000
          currentBalancePaise: Value(FinancialPrecision.rupeesToPaise(50000.0)),
        ),
      );

      // Account for Profile 2 (Spouse)
      final spouseAccountId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: Value(spouseId),
          name: const Value('Spouse ICICI Bank'),
          accountType: const Value('bank'),
          openingBalancePaise:
              Value(FinancialPrecision.rupeesToPaise(30000.0)), // ₹30,000
          currentBalancePaise: Value(FinancialPrecision.rupeesToPaise(30000.0)),
        ),
      );

      expect(selfAccountId, isPositive);
      expect(spouseAccountId, isPositive);

      // Query Profile 1 accounts
      final selfAccounts =
          await db.accountsDao.getAccountsByProfile(defaultProfile.id);
      expect(selfAccounts.length, equals(1));
      expect(selfAccounts.first.name, equals('Self HDFC Bank'));
      expect(selfAccounts.any((a) => a.id == spouseAccountId), isFalse);

      // Query Profile 2 accounts
      final spouseAccounts =
          await db.accountsDao.getAccountsByProfile(spouseId);
      expect(spouseAccounts.length, equals(1));
      expect(spouseAccounts.first.name, equals('Spouse ICICI Bank'));
      expect(spouseAccounts.any((a) => a.id == selfAccountId), isFalse);

      // Liquidity calculations
      final selfLiquidity = await db.accountsDao
          .calculateTotalLiquidityForProfile(defaultProfile.id);
      final spouseLiquidity =
          await db.accountsDao.calculateTotalLiquidityForProfile(spouseId);

      expect(selfLiquidity, equals(5000000)); // ₹50,000 in paise
      expect(spouseLiquidity, equals(3000000)); // ₹30,000 in paise
    });
  });

  group('Financial Items (Assets vs Liabilities) & Data Separation', () {
    test(
        'strictly separates assets and liabilities by profile and calculates net worth',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;

      final fatherId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Father'),
          relationship: Value('father'),
        ),
      );

      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final liabilityCategories =
          await db.categoriesDao.getCategoriesByClassification('liability');

      // 1. Insert an Asset for Self (Mutual Fund, ₹100,000)
      final selfAssetId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Parag Parikh Flexi Cap'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
          currentValuationPaise:
              Value(FinancialPrecision.rupeesToPaise(100000.0)),
        ),
      );

      // 2. Insert a Liability for Self (Personal Loan, ₹20,000)
      final selfLiabilityId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Personal Loan'),
          itemType: const Value('liability'),
          subType: const Value('personal_loan'),
          categoryId: Value(liabilityCategories.first.id),
          currentValuationPaise:
              Value(FinancialPrecision.rupeesToPaise(20000.0)),
        ),
      );

      // 3. Insert an Asset for Father (Senior Citizen FD, ₹500,000)
      final fatherAssetId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(fatherId),
          name: const Value('SBI Senior Citizen FD'),
          itemType: const Value('asset'),
          subType: const Value('fixed_deposit'),
          categoryId: Value(assetCategories.first.id),
          currentValuationPaise:
              Value(FinancialPrecision.rupeesToPaise(500000.0)),
        ),
      );

      expect(selfAssetId, isPositive);
      expect(selfLiabilityId, isPositive);
      expect(fatherAssetId, isPositive);

      // Verify Self profile items
      final selfAssets = await db.financialItemsDao
          .getItemsByProfile(defaultProfile.id, itemType: 'asset');
      final selfLiabilities = await db.financialItemsDao
          .getItemsByProfile(defaultProfile.id, itemType: 'liability');

      expect(selfAssets.length, equals(1));
      expect(selfAssets.first.name, equals('Parag Parikh Flexi Cap'));
      expect(selfLiabilities.length, equals(1));
      expect(selfLiabilities.first.name, equals('Personal Loan'));

      // Ensure Father's FD does not leak into Self's assets
      expect(selfAssets.any((a) => a.id == fatherAssetId), isFalse);

      // Verify Father's profile items
      final fatherAssets = await db.financialItemsDao
          .getItemsByProfile(fatherId, itemType: 'asset');
      final fatherLiabilities = await db.financialItemsDao
          .getItemsByProfile(fatherId, itemType: 'liability');

      expect(fatherAssets.length, equals(1));
      expect(fatherAssets.first.name, equals('SBI Senior Citizen FD'));
      expect(fatherLiabilities, isEmpty);

      // Net Worth calculations:
      // Self Net Worth = ₹100,000 - ₹20,000 = ₹80,000 (8,000,000 paise)
      final selfNetWorth = await db.financialItemsDao
          .calculateNetWorthForProfile(defaultProfile.id);
      expect(selfNetWorth, equals(8000000));

      // Father Net Worth = ₹500,000 - ₹0 = ₹500,000 (50,000,000 paise)
      final fatherNetWorth =
          await db.financialItemsDao.calculateNetWorthForProfile(fatherId);
      expect(fatherNetWorth, equals(50000000));

      // Combined Household Net Worth = ₹80,000 + ₹500,000 = ₹580,000 (58,000,000 paise)
      final householdNetWorth =
          await db.financialItemsDao.calculateHouseholdNetWorth();
      expect(householdNetWorth, equals(58000000));
    });
  });

  group('Cross-Profile Integrity & Transactions', () {
    test(
        'prevents cross-profile relationships between transaction, items, and accounts',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;

      final spouseId = await db.profilesDao.createProfile(
        const FinancialProfilesCompanion(
          name: Value('Spouse'),
          relationship: Value('spouse'),
        ),
      );

      final categories =
          await db.categoriesDao.getCategoriesByClassification('expense');

      // Account belonging to Self
      final selfAccountId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Self Bank'),
          accountType: const Value('bank'),
        ),
      );

      // Asset belonging to Spouse
      final spouseItemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(spouseId),
          name: const Value('Spouse Gold'),
          itemType: const Value('asset'),
          subType: const Value('gold'),
          categoryId: Value(categories.first.id),
        ),
      );

      // Attempting to record a transaction for Self that references Spouse's asset should fail integrity check
      expect(
        () async => await db.transactionsDao.insertTransaction(
          TransactionsCompanion(
            profileId: Value(defaultProfile.id), // Profile 1
            transactionType: const Value('investment_purchase'),
            categoryId: Value(categories.first.id),
            financialItemId: Value(spouseItemId), // Profile 2!
            fromAccountId: Value(selfAccountId),
            transactionDate: Value(DateTime.utc(2026, 1, 1)),
            amountPaise: const Value(500000),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      // Attempting to record a transaction for Spouse referencing Self's account should also fail
      expect(
        () async => await db.transactionsDao.insertTransaction(
          TransactionsCompanion(
            profileId: Value(spouseId), // Profile 2
            transactionType: const Value('investment_purchase'),
            categoryId: Value(categories.first.id),
            financialItemId: Value(spouseItemId),
            fromAccountId: Value(selfAccountId), // Profile 1!
            transactionDate: Value(DateTime.utc(2026, 1, 1)),
            amountPaise: const Value(500000),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('records valid profile-scoped transactions and queries correctly',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;
      final categories =
          await db.categoriesDao.getCategoriesByClassification('expense');

      final accountId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Primary Checking'),
          accountType: const Value('bank'),
        ),
      );

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('HDFC Top 100'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(categories.first.id),
        ),
      );

      final txId = await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: Value(defaultProfile.id),
          transactionType: const Value('investment_purchase'),
          categoryId: Value(categories.first.id),
          financialItemId: Value(itemId),
          fromAccountId: Value(accountId),
          transactionDate: Value(DateTime.utc(2026, 1, 15)),
          amountPaise: Value(FinancialPrecision.rupeesToPaise(5000.0)),
          source: const Value('simulated_sip'),
        ),
      );

      expect(txId, isPositive);

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx, isNotNull);
      expect(tx!.profileId, equals(defaultProfile.id));
      expect(tx.amountPaise, equals(500000));

      final profileTxs = await db.transactionsDao
          .watchRecentTransactionsForProfile(defaultProfile.id)
          .first;
      expect(profileTxs.length, equals(1));
      expect(profileTxs.first.id, equals(txId));
    });
  });

  group('Valuation History & Uniqueness', () {
    test(
        'upserts historical valuations and enforces uniqueness on (financialItemId, valuationDate)',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Nifty 50 Index Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      final date1 = DateTime.utc(2026, 1, 10);
      final date2 = DateTime.utc(2026, 1, 11);

      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(date1),
          valuationPaise: Value(FinancialPrecision.rupeesToPaise(50000.0)),
          unitPriceMicroPaise: Value(FinancialPrecision.navToMicroPaise(250.0)),
          sourceProvider: const Value('mfapi'),
        ),
      );

      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(date2),
          valuationPaise: Value(FinancialPrecision.rupeesToPaise(51000.0)),
          unitPriceMicroPaise: Value(FinancialPrecision.navToMicroPaise(255.0)),
          sourceProvider: const Value('mfapi'),
        ),
      );

      final history = await db.valuationsDao.getValuationHistory(itemId);
      expect(history.length, equals(2));

      // Upsert on date2 with updated NAV replaces record without duplicate row
      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(date2),
          valuationPaise: Value(FinancialPrecision.rupeesToPaise(51500.0)),
          unitPriceMicroPaise: Value(FinancialPrecision.navToMicroPaise(257.5)),
          sourceProvider: const Value('mfapi'),
        ),
      );

      final updatedHistory = await db.valuationsDao.getValuationHistory(itemId);
      expect(updatedHistory.length, equals(2));

      final latestVal = await db.valuationsDao.getLatestValuation(itemId);
      expect(latestVal, isNotNull);
      expect(latestVal!.valuationPaise, equals(5150000));
    });

    test(
        'cascades delete on valuation history when parent financial item is deleted',
        () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Temporary Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(DateTime.utc(2026, 1, 1)),
          valuationPaise: const Value(100000),
        ),
      );

      await db.financialItemsDao.deleteItem(itemId);

      final history = await db.valuationsDao.getValuationHistory(itemId);
      expect(history, isEmpty);
    });
  });

  group('Recurring Transactions & AppSettings', () {
    test('manages profile-scoped scheduled SIP and loan EMI rules', () async {
      final defaultProfile = (await db.profilesDao.getDefaultProfile())!;
      final expenseCategories =
          await db.categoriesDao.getCategoriesByClassification('expense');
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('Parag Parikh Flexi Cap Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      final scheduleId = await db.recurringTransactionsDao.insertSchedule(
        RecurringTransactionsCompanion(
          profileId: Value(defaultProfile.id),
          name: const Value('PPFC Monthly SIP'),
          recurringType: const Value('sip_investment'),
          financialItemId: Value(itemId),
          categoryId: Value(expenseCategories.first.id),
          amountPaise: Value(FinancialPrecision.rupeesToPaise(5000.0)),
          frequency: const Value('monthly'),
          scheduledDay: const Value(5),
          startDate: Value(DateTime.utc(2026, 1, 5)),
        ),
      );

      expect(scheduleId, isPositive);

      final schedule =
          await db.recurringTransactionsDao.getScheduleById(scheduleId);
      expect(schedule, isNotNull);
      expect(schedule!.profileId, equals(defaultProfile.id));
      expect(schedule.recurringType, equals('sip_investment'));

      final activeSchedules = await db.recurringTransactionsDao
          .getActiveSchedulesByProfile(defaultProfile.id);
      expect(activeSchedules.length, equals(1));
    });

    test('sets, gets, updates, and deletes settings', () async {
      await db.appSettingsDao.setSetting('currency', 'INR');
      await db.appSettingsDao.setSetting('theme', 'dark');

      expect(await db.appSettingsDao.getSetting('currency'), equals('INR'));
      expect(await db.appSettingsDao.getSetting('theme'), equals('dark'));

      await db.appSettingsDao.setSetting('theme', 'light');
      expect(await db.appSettingsDao.getSetting('theme'), equals('light'));

      await db.appSettingsDao.deleteSetting('currency');
      expect(await db.appSettingsDao.getSetting('currency'), isNull);
    });
  });
}
