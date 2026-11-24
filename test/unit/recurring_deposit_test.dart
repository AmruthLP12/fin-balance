import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:finbalance/core/cash_flow.dart';
import 'package:finbalance/data/assets/recurring_deposit_service.dart';
import 'package:finbalance/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RD auto-posts each due installment once, clamping month-end dates',
      () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final itemId = await db.financialItemsDao.insertItem(
      const FinancialItemsCompanion(
        profileId: drift.Value(1),
        name: drift.Value('Test RD'),
        itemType: drift.Value('asset'),
        subType: drift.Value('recurring_deposit'),
        categoryId: drift.Value(1),
      ),
    );
    final start = DateTime(2026, 1, 31);
    final maturity = DateTime(2026, 4, 30);
    final scheduleId = await db.recurringTransactionsDao.insertSchedule(
      RecurringTransactionsCompanion(
        profileId: const drift.Value(1),
        name: const drift.Value('Test RD'),
        recurringType: const drift.Value(recurringDepositType),
        financialItemId: drift.Value(itemId),
        categoryId: const drift.Value(1),
        amountPaise: const drift.Value(250000),
        frequency: const drift.Value('monthly'),
        scheduledDay: const drift.Value(31),
        startDate: drift.Value(start),
        endDate: drift.Value(maturity),
        nextDueDate: drift.Value(start),
      ),
    );

    expect(
        await applyDueDepositTransactions(db, today: DateTime(2026, 3, 31)), 3);
    expect(
        await applyDueDepositTransactions(db, today: DateTime(2026, 3, 31)), 0);

    final item = (await db.financialItemsDao.getItemById(itemId))!;
    expect(item.initialValuePaise, 750000);
    expect(item.currentValuationPaise, 750000);
    final transactions =
        await db.transactionsDao.getTransactionsByItem(1, itemId);
    expect(transactions.map((t) => t.transactionDate), [
      DateTime(2026, 1, 31),
      DateTime(2026, 2, 28),
      DateTime(2026, 3, 31),
    ]);
    expect(
        transactions.every((t) => t.source == recurringDepositAutoPostSource),
        isTrue);
    expect(flowOf(transactions.first.transactionType), MoneyFlow.investment);

    final schedule =
        (await db.recurringTransactionsDao.getScheduleById(scheduleId))!;
    expect(schedule.status, 'completed');
    expect(schedule.nextDueDate, isNull);
  });

  test('non-cumulative FD interest posts as income at payout date', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final category =
        (await db.categoriesDao.getCategoriesByClassification('asset'))
            .firstWhere((c) => c.name == 'Fixed & Recurring Deposits');
    final start = DateTime(2026, 1, 31);
    final maturity = DateTime(2026, 4, 30);
    final itemId = await db.financialItemsDao.insertItem(
      FinancialItemsCompanion(
        profileId: const drift.Value(1),
        name: const drift.Value('Test FD'),
        itemType: const drift.Value('asset'),
        subType: const drift.Value('fixed_deposit'),
        categoryId: drift.Value(category.id),
        initialValuePaise: const drift.Value(1000000),
        currentValuationPaise: const drift.Value(1000000),
        interestRateBasisPoints: const drift.Value(1200),
        depositCompoundingMonths: const drift.Value(3),
        depositCumulative: const drift.Value(false),
      ),
    );
    await db.recurringTransactionsDao.insertSchedule(
      RecurringTransactionsCompanion(
        profileId: const drift.Value(1),
        name: const drift.Value('Test FD'),
        recurringType: const drift.Value(fixedDepositInterestType),
        financialItemId: drift.Value(itemId),
        categoryId: drift.Value(category.id),
        amountPaise: const drift.Value(0),
        frequency: const drift.Value('quarterly'),
        scheduledDay: const drift.Value(31),
        startDate: drift.Value(start),
        endDate: drift.Value(maturity),
        nextDueDate: drift.Value(maturity),
      ),
    );

    expect(await applyDueDepositTransactions(db, today: maturity), 1);
    final transaction =
        (await db.transactionsDao.getTransactionsByItem(1, itemId)).single;
    expect(transaction.transactionType, 'interest_received');
    expect(transaction.source, fixedDepositInterestAutoPostSource);
    expect(transaction.amountPaise, 30000);
    expect(flowOf(transaction.transactionType), MoneyFlow.income);
  });
}
