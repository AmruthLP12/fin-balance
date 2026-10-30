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

  group('Database Initialization & Categories', () {
    test('seeds default categories on fresh database creation', () async {
      final categories = await db.categoriesDao.watchAllCategories().first;
      expect(categories, isNotEmpty);
      expect(categories.any((c) => c.classification == 'asset'), isTrue);
      expect(categories.any((c) => c.classification == 'liability'), isTrue);
      expect(categories.any((c) => c.classification == 'income'), isTrue);
      expect(categories.any((c) => c.classification == 'expense'), isTrue);
    });

    test('creates custom categories and supports soft-archive', () async {
      final categoryId = await db.categoriesDao.insertCategory(
        const FinancialCategoriesCompanion(
          name: Value('Crypto & Web3'),
          classification: Value('asset'),
          isCustom: Value(true),
        ),
      );
      expect(categoryId, isPositive);

      final category = await db.categoriesDao.getCategoryById(categoryId);
      expect(category, isNotNull);
      expect(category!.name, equals('Crypto & Web3'));
      expect(category.isCustom, isTrue);
      expect(category.isArchived, isFalse);

      // Archive category
      await db.categoriesDao.archiveCategory(categoryId);
      final activeCategories =
          await db.categoriesDao.watchAllCategories().first;
      expect(activeCategories.any((c) => c.id == categoryId), isFalse);
    });
  });

  group('Financial Accounts', () {
    test(
        'creates accounts, manages opening balances, and updates cached balance in paise',
        () async {
      final accountId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          name: const Value('HDFC Salary Account'),
          accountType: const Value('bank'),
          institutionName: const Value('HDFC Bank'),
          openingBalancePaise:
              Value(FinancialPrecision.rupeesToPaise(25000.0)), // ₹25,000
          currentBalancePaise: Value(FinancialPrecision.rupeesToPaise(25000.0)),
        ),
      );
      expect(accountId, isPositive);

      final account = await db.accountsDao.getAccountById(accountId);
      expect(account, isNotNull);
      expect(account!.name, equals('HDFC Salary Account'));
      expect(account.openingBalancePaise, equals(2500000));
      expect(account.currentBalancePaise, equals(2500000));

      // Update cached balance to ₹30,000.50
      await db.accountsDao
          .updateBalance(accountId, FinancialPrecision.rupeesToPaise(30000.50));
      final updated = await db.accountsDao.getAccountById(accountId);
      expect(updated!.currentBalancePaise, equals(3000050));

      // Archive account
      await db.accountsDao.archiveAccount(accountId);
      final active = await db.accountsDao.getActiveAccounts();
      expect(active.any((a) => a.id == accountId), isFalse);
    });
  });

  group('Financial Items (Assets vs Liabilities)', () {
    test(
        'distinctly stores and filters Assets and Liabilities with precision values',
        () async {
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final liabilityCategories =
          await db.categoriesDao.getCategoriesByClassification('liability');

      // 1. Insert an Asset (Mutual Fund)
      final assetId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          name: const Value('SBI Small Cap Fund - Direct Growth'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
          externalCode: const Value('125497'),
          initialValuePaise:
              Value(FinancialPrecision.rupeesToPaise(10000.0)), // ₹10,000
          currentValuationPaise:
              Value(FinancialPrecision.rupeesToPaise(12500.0)), // ₹12,500
          unitCountMicroUnits:
              Value(FinancialPrecision.unitsToMicroUnits(62.456)),
        ),
      );

      // 2. Insert a Liability (Home Loan)
      final liabilityId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          name: const Value('SBI MaxGain Home Loan'),
          itemType: const Value('liability'),
          subType: const Value('home_loan'),
          categoryId: Value(liabilityCategories.first.id),
          externalCode: const Value('HL-987654321'),
          initialValuePaise:
              Value(FinancialPrecision.rupeesToPaise(4000000.0)), // ₹40 Lakhs
          currentValuationPaise:
              Value(FinancialPrecision.rupeesToPaise(3850000.0)), // ₹38.5 Lakhs
          interestRateBasisPoints: const Value(850), // 8.50%
        ),
      );

      expect(assetId, isPositive);
      expect(liabilityId, isPositive);

      // Verify separation by itemType
      final assets = await db.financialItemsDao.getItemsByType('asset');
      final liabilities =
          await db.financialItemsDao.getItemsByType('liability');

      expect(assets.any((a) => a.id == assetId), isTrue);
      expect(assets.any((a) => a.id == liabilityId), isFalse);

      expect(liabilities.any((l) => l.id == liabilityId), isTrue);
      expect(liabilities.any((l) => l.id == assetId), isFalse);

      // Lookup by external code (scheme code)
      final fund = await db.financialItemsDao.getItemByExternalCode('125497');
      expect(fund, isNotNull);
      expect(fund!.name, equals('SBI Small Cap Fund - Direct Growth'));
      expect(fund.unitCountMicroUnits, equals(62456000));
    });
  });

  group('Transactions Ledger', () {
    test('records financial cash flow and links to items and accounts',
        () async {
      final categories =
          await db.categoriesDao.getCategoriesByClassification('expense');
      final accountId = await db.accountsDao.insertAccount(
        const FinancialAccountsCompanion(
          name: Value('Primary Checking'),
          accountType: Value('bank'),
        ),
      );

      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          name: const Value('HDFC Top 100'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      // Record an SIP contribution transaction
      final txDate = DateTime.utc(2026, 1, 15);
      final txId = await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          transactionType: const Value('investment_purchase'),
          categoryId: Value(categories.first.id),
          financialItemId: Value(itemId),
          fromAccountId: Value(accountId),
          transactionDate: Value(txDate),
          amountPaise: Value(FinancialPrecision.rupeesToPaise(5000.0)),
          unitsMicroUnits: Value(FinancialPrecision.unitsToMicroUnits(15.250)),
          unitPriceMicroPaise:
              Value(FinancialPrecision.navToMicroPaise(327.8688)),
          source: const Value('simulated_sip'),
          notes: const Value('Monthly SIP installment #1'),
        ),
      );

      expect(txId, isPositive);

      final tx = await db.transactionsDao.getTransactionById(txId);
      expect(tx, isNotNull);
      expect(tx!.amountPaise, equals(500000));
      expect(tx.source, equals('simulated_sip'));
      expect(tx.unitsMicroUnits, equals(15250000));
      expect(tx.fromAccountId, equals(accountId));
      expect(tx.financialItemId, equals(itemId));

      // Query by item
      final itemTxs = await db.transactionsDao.getTransactionsByItem(itemId);
      expect(itemTxs.length, equals(1));
      expect(itemTxs.first.id, equals(txId));
    });
  });

  group('Valuation History & Uniqueness', () {
    test(
        'upserts historical valuations and enforces uniqueness on (financialItemId, valuationDate)',
        () async {
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          name: const Value('Nifty 50 Index Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      final date1 = DateTime.utc(2026, 1, 10);
      final date2 = DateTime.utc(2026, 1, 11);

      // Insert valuation for date1
      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(date1),
          valuationPaise: Value(FinancialPrecision.rupeesToPaise(50000.0)),
          unitPriceMicroPaise: Value(FinancialPrecision.navToMicroPaise(250.0)),
          sourceProvider: const Value('mfapi'),
        ),
      );

      // Insert valuation for date2
      await db.valuationsDao.upsertValuation(
        ValuationHistoryCompanion(
          financialItemId: Value(itemId),
          valuationDate: Value(date2),
          valuationPaise: Value(FinancialPrecision.rupeesToPaise(51000.0)),
          unitPriceMicroPaise: Value(FinancialPrecision.navToMicroPaise(255.0)),
          sourceProvider: const Value('mfapi'),
        ),
      );

      // Query valuations
      final history = await db.valuationsDao.getValuationHistory(itemId);
      expect(history.length, equals(2));

      // Upsert on date2 with updated NAV (should replace, not duplicate)
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
      expect(updatedHistory.length, equals(2)); // No duplicate row created

      final latestVal = await db.valuationsDao.getLatestValuation(itemId);
      expect(latestVal, isNotNull);
      expect(latestVal!.valuationPaise, equals(5150000));
    });

    test(
        'cascades delete on valuation history when parent financial item is deleted',
        () async {
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');
      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
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

      // Delete the parent item
      await db.financialItemsDao.deleteItem(itemId);

      // Verify valuations for deleted item are also deleted
      final history = await db.valuationsDao.getValuationHistory(itemId);
      expect(history, isEmpty);
    });
  });

  group('Recurring Transactions (SIPs & EMIs)', () {
    test('manages scheduled SIP and loan EMI rules', () async {
      final expenseCategories =
          await db.categoriesDao.getCategoriesByClassification('expense');
      final assetCategories =
          await db.categoriesDao.getCategoriesByClassification('asset');

      final itemId = await db.financialItemsDao.insertItem(
        FinancialItemsCompanion(
          name: const Value('Parag Parikh Flexi Cap Fund'),
          itemType: const Value('asset'),
          subType: const Value('mutual_fund'),
          categoryId: Value(assetCategories.first.id),
        ),
      );

      // Create a monthly SIP schedule
      final scheduleId = await db.recurringTransactionsDao.insertSchedule(
        RecurringTransactionsCompanion(
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
      expect(schedule!.recurringType, equals('sip_investment'));
      expect(schedule.amountPaise, equals(500000));
      expect(schedule.scheduledDay, equals(5));
      expect(schedule.status, equals('active'));

      // Pause the SIP schedule
      await db.recurringTransactionsDao.updateStatus(scheduleId, 'paused');
      final paused =
          await db.recurringTransactionsDao.getScheduleById(scheduleId);
      expect(paused!.status, equals('paused'));

      final activeSchedules = await db.recurringTransactionsDao
          .getActiveSchedulesByType('sip_investment');
      expect(activeSchedules.any((s) => s.id == scheduleId), isFalse);
    });
  });

  group('AppSettings Key-Value Store', () {
    test('sets, gets, updates, and deletes settings', () async {
      await db.appSettingsDao.setSetting('currency', 'INR');
      await db.appSettingsDao.setSetting('theme', 'dark');

      expect(await db.appSettingsDao.getSetting('currency'), equals('INR'));
      expect(await db.appSettingsDao.getSetting('theme'), equals('dark'));

      // Update on conflict
      await db.appSettingsDao.setSetting('theme', 'light');
      expect(await db.appSettingsDao.getSetting('theme'), equals('light'));

      final all = await db.appSettingsDao.getAllSettings();
      expect(all['currency'], equals('INR'));
      expect(all['theme'], equals('light'));

      // Delete setting
      await db.appSettingsDao.deleteSetting('currency');
      expect(await db.appSettingsDao.getSetting('currency'), isNull);
    });
  });
}
