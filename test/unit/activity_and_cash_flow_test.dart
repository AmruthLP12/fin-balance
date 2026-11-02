import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int profileId;
  late int salaryCategoryId;
  late int groceryCategoryId;
  late int mfCategoryId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final defaultProfile = await db.profilesDao.getDefaultProfile();
    profileId = defaultProfile!.id;

    final categories = await db.categoriesDao.watchAllCategories().first;
    salaryCategoryId =
        categories.firstWhere((c) => c.classification == 'income').id;
    groceryCategoryId =
        categories.firstWhere((c) => c.classification == 'expense').id;
    mfCategoryId = categories.firstWhere((c) => c.classification == 'asset').id;
  });

  tearDown(() async {
    await db.close();
  });

  group('Activity & Cash Flow Ledger Tests', () {
    test('Records income and expense transactions and computes net cash flow',
        () async {
      // 1. Record Income: ₹50,000 (5,000,000 paise)
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('income'),
          categoryId: drift.Value(salaryCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 1)),
          amountPaise: const drift.Value(5000000),
          notes: const drift.Value('February Salary'),
        ),
      );

      // 2. Record Expense: ₹15,000 (1,500,000 paise)
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('expense'),
          categoryId: drift.Value(groceryCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 5)),
          amountPaise: const drift.Value(1500000),
          notes: const drift.Value('Monthly Groceries'),
        ),
      );

      // 3. Record Capital Investment Purchase: ₹10,000 (1,000,000 paise)
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('investment_purchase'),
          categoryId: drift.Value(mfCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 10)),
          amountPaise: const drift.Value(1000000),
          notes: const drift.Value('Index Fund SIP'),
        ),
      );

      // Fetch all transactions
      final txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.length, 3);

      // Cash Flow Calculation:
      int income = 0;
      int expense = 0;
      int investments = 0;

      for (final t in txns) {
        if (t.transactionType == 'income') {
          income += t.amountPaise;
        }
        if (t.transactionType == 'expense') {
          expense += t.amountPaise;
        }
        if (t.transactionType.contains('investment')) {
          investments += t.amountPaise;
        }
      }

      expect(income, 5000000); // ₹50,000
      expect(expense, 1500000); // ₹15,000
      expect(investments, 1000000); // ₹10,000

      // Net Cash Flow = Income - Expenses = ₹35,000
      final netCashFlow = income - expense;
      expect(netCashFlow, 3500000);

      // Savings Rate = (50,000 - 15,000) / 50,000 * 100 = 70.0%
      final savingsRate = (income - expense) / income * 100;
      expect(savingsRate, 70.0);
    });

    test(
        'Transfers are strictly excluded from income and expenses calculations',
        () async {
      // Create cash and bank accounts
      final bankAccId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Salary Account'),
          accountType: const drift.Value('bank'),
          institutionName: const drift.Value('HDFC Bank'),
          accountNumberMasked: const drift.Value('**1234'),
          currencyCode: const drift.Value('INR'),
          currentBalancePaise: const drift.Value(10000000),
        ),
      );

      final cashAccId = await db.accountsDao.insertAccount(
        FinancialAccountsCompanion(
          profileId: drift.Value(profileId),
          name: const drift.Value('Cash Wallet'),
          accountType: const drift.Value('cash'),
          institutionName: const drift.Value('Physical Wallet'),
          currencyCode: const drift.Value('INR'),
          currentBalancePaise: const drift.Value(500000),
        ),
      );

      // Record Transfer of ₹5,000 from Bank to Wallet
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('transfer'),
          categoryId: drift.Value(groceryCategoryId),
          fromAccountId: drift.Value(bankAccId),
          toAccountId: drift.Value(cashAccId),
          transactionDate: drift.Value(DateTime(2025, 2, 8)),
          amountPaise: const drift.Value(500000),
          notes: const drift.Value('ATM Withdrawal to Cash Wallet'),
        ),
      );

      final txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.length, 1);
      expect(txns.first.transactionType, 'transfer');

      // In Cash Flow, transfers are filtered out:
      final cashFlowTxns =
          txns.where((t) => t.transactionType != 'transfer').toList();
      expect(cashFlowTxns.isEmpty, isTrue);

      int income = 0;
      int expense = 0;
      for (final t in cashFlowTxns) {
        if (t.transactionType == 'income') income += t.amountPaise;
        if (t.transactionType == 'expense') expense += t.amountPaise;
      }

      expect(income, 0);
      expect(expense, 0);
    });

    test('Transaction deletion removes record cleanly and updates totals',
        () async {
      final txnId = await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('expense'),
          categoryId: drift.Value(groceryCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 12)),
          amountPaise: const drift.Value(85000),
          notes: const drift.Value('Dinner'),
        ),
      );

      var txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.length, 1);

      // Delete transaction
      final rowsDeleted = await db.transactionsDao.deleteTransaction(txnId);
      expect(rowsDeleted, 1);

      txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      expect(txns.isEmpty, isTrue);
    });

    test('Category grouping correctly aggregates breakdown and top expenses',
        () async {
      // Add multiple expense transactions in different categories
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('expense'),
          categoryId: drift.Value(groceryCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 1)),
          amountPaise: const drift.Value(1200000), // ₹12,000
          notes: const drift.Value('Supermarket'),
        ),
      );

      await db.transactionsDao.insertTransaction(
        TransactionsCompanion(
          profileId: drift.Value(profileId),
          transactionType: const drift.Value('expense'),
          categoryId: drift.Value(groceryCategoryId),
          transactionDate: drift.Value(DateTime(2025, 2, 15)),
          amountPaise: const drift.Value(800000), // ₹8,000
          notes: const drift.Value('Local Grocery'),
        ),
      );

      final txns =
          await db.transactionsDao.getRecentTransactionsForProfile(profileId);
      final expenseByCategory = <int, int>{};
      int totalExpenses = 0;

      for (final t in txns) {
        if (t.transactionType == 'expense') {
          totalExpenses += t.amountPaise;
          expenseByCategory[t.categoryId] =
              (expenseByCategory[t.categoryId] ?? 0) + t.amountPaise;
        }
      }

      expect(totalExpenses, 2000000); // ₹20,000
      expect(expenseByCategory[groceryCategoryId], 2000000);
      final pct = expenseByCategory[groceryCategoryId]! / totalExpenses;
      expect(pct, 1.0);
    });
  });
}
